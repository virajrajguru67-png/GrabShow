import { Router } from 'express';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';

import crypto from 'crypto';

import { buildAuthPayload, createSession, rotateSession } from '../modules/auth/token.service.js';
import { forgotPasswordSchema, loginSchema, refreshSchema, registerSchema, resetPasswordSchema, updateProfileSchema, verifyOtpSchema } from '../modules/auth/auth.schema.js';
import { authenticateUser, findUserByEmail, normalizeUserResponse, registerUser, updateUserProfile } from '../modules/auth/auth.service.js';
import { authenticate, type RequestWithAuth } from '../middleware/authenticate.js';
import { asyncHandler } from '../utils/async-handler.js';
import { env } from '../config/index.js';
import { prisma } from '../services/prisma.js';
import { sendPasswordResetOtp, isEmailConfigured } from '../services/email.service.js';
import { hashPassword } from '../utils/password.js';
import { badRequest, notFound } from '../errors/app-error.js';

export const authRouter = Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (_req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

authRouter.post(
  '/register',
  asyncHandler(async (req, res) => {
    const body = registerSchema.parse(req.body);
    const user = await registerUser(body);

    const session = await createSession(user.id, {
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });

    const payload = buildAuthPayload(user, session.refreshToken, session.expiresAt);
    res.status(201).json({ ...payload, user: normalizeUserResponse(user) });
  }),
);

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const body = loginSchema.parse(req.body);
    const user = await authenticateUser(body.email, body.password);

    const session = await createSession(user.id, {
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });

    const payload = buildAuthPayload(user, session.refreshToken, session.expiresAt);
    res.json({ ...payload, user: normalizeUserResponse(user) });
  }),
);

authRouter.post(
  '/refresh',
  asyncHandler(async (req, res) => {
    const body = refreshSchema.parse(req.body);

    const rotated = await rotateSession(body.refreshToken, {
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });

    const user = await prisma.user.findUnique({
      where: { id: rotated.userId },
      include: {
        adminProfile: { include: { roles: true } },
      },
    });
    if (!user) {
      res.status(401).json({ message: 'Invalid refresh token' });
      return;
    }

    const payload = buildAuthPayload(user, rotated.refreshToken, rotated.expiresAt);
    res.json({ ...payload, user: normalizeUserResponse(user) });
  }),
);

authRouter.put(
  '/profile',
  authenticate,
  asyncHandler(async (req, res) => {
    const body = updateProfileSchema.parse(req.body);
    const authReq = req as RequestWithAuth;
    const userId = authReq.auth!.user.id;

    const updatedUser = await updateUserProfile(userId, body);

    // Get current session to return updated tokens
    const session = await createSession(updatedUser.id, {
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });

    const payload = buildAuthPayload(updatedUser, session.refreshToken, session.expiresAt);
    res.json({ ...payload, user: normalizeUserResponse(updatedUser) });
  }),
);

authRouter.post(
  '/upload-avatar',
  authenticate,
  upload.single('avatar'),
  asyncHandler(async (req, res) => {
    const authReq = req as RequestWithAuth;
    const userId = authReq.auth!.user.id;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    // For now, we'll generate a URL and store it
    // In production, you'd upload to S3, Cloudinary, or similar service
    // For development, we'll create a data URL or use a placeholder
    const fileExtension = file.originalname.split('.').pop() || 'jpg';
    const fileName = `${userId}-${uuidv4()}.${fileExtension}`;
    
    // Convert buffer to base64 data URL for now
    // In production, upload to cloud storage and return the URL
    const base64Image = file.buffer.toString('base64');
    const dataUrl = `data:${file.mimetype};base64,${base64Image}`;
    
    // For now, we'll store the data URL directly
    // In production, you'd upload to cloud storage and store the public URL
    const avatarUrl = dataUrl;

    // Update user's avatar URL
    const updatedUser = await updateUserProfile(userId, { avatarUrl });

    res.json({
      avatarUrl: updatedUser.avatarUrl,
      message: 'Avatar uploaded successfully',
    });
  }),
);

authRouter.post(
  '/forgot-password',
  asyncHandler(async (req, res) => {
    const body = forgotPasswordSchema.parse(req.body);
    const user = await findUserByEmail(body.email);

    // For security, don't reveal if email exists or not
    // Always return success, but only send email if user exists
    if (!user) {
      // Return success even if user doesn't exist (security best practice)
      return res.json({ message: 'If the email exists, a password reset link has been sent' });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

    // Invalidate any existing reset OTPs for this user
    await prisma.passwordResetToken.updateMany({
      where: {
        userId: user.id,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      data: {
        usedAt: new Date(),
      },
    });

    // Create new reset OTP
    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        otp,
        expiresAt,
      },
    });

    // Send email with OTP if SMTP is configured, otherwise return OTP for development
    await sendPasswordResetOtp(user.email, otp);

    if (isEmailConfigured()) {
      res.json({ message: 'Password reset OTP sent to your email' });
    } else {
      // Development mode: return OTP
      res.json({
        message: 'Password reset OTP generated (SMTP not configured)',
        otp, // Only in development
      });
    }
  }),
);

authRouter.post(
  '/verify-otp',
  asyncHandler(async (req, res) => {
    const body = verifyOtpSchema.parse(req.body);
    const user = await findUserByEmail(body.email);

    if (!user) {
      throw notFound('User not found');
    }

    // Find valid OTP
    const otpRecord = await prisma.passwordResetToken.findFirst({
      where: {
        userId: user.id,
        otp: body.otp,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw badRequest('Invalid or expired OTP');
    }

    res.json({ message: 'OTP verified successfully', verified: true });
  }),
);

authRouter.post(
  '/reset-password',
  asyncHandler(async (req, res) => {
    const body = resetPasswordSchema.parse(req.body);
    const user = await findUserByEmail(body.email);

    if (!user) {
      throw notFound('User not found');
    }

    // Find valid OTP
    const otpRecord = await prisma.passwordResetToken.findFirst({
      where: {
        userId: user.id,
        otp: body.otp,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      include: { user: true },
    });

    if (!otpRecord) {
      throw badRequest('Invalid or expired OTP');
    }

    // Hash new password
    const passwordHash = await hashPassword(body.newPassword);

    // Update user password
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    // Mark OTP as used
    await prisma.passwordResetToken.update({
      where: { id: otpRecord.id },
      data: { usedAt: new Date() },
    });

    // Invalidate all user sessions (force re-login)
    await prisma.session.updateMany({
      where: { userId: user.id },
      data: { revokedAt: new Date() },
    });

    // Create new session and return auth tokens (auto-login)
    const session = await createSession(user.id, {
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });

    const payload = buildAuthPayload(user, session.refreshToken, session.expiresAt);
    res.json({ 
      message: 'Password reset successfully',
      ...payload,
      user: normalizeUserResponse(user),
    });
  }),
);
