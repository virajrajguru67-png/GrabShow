import crypto from 'crypto';

import jwt, { type SignOptions } from 'jsonwebtoken';
import ms, { type StringValue as MsStringValue } from 'ms';

import { env } from '../../config/index.js';
import { AppError, internal } from '../../errors/app-error.js';
import { prisma } from '../../services/prisma.js';

const REFRESH_TOKEN_BYTES = 48;
const ACCESS_TOKEN_EXPIRES_IN_SECONDS = (() => {
  const value = ms(env.JWT_EXPIRES_IN as MsStringValue);
  if (typeof value !== 'number' || Number.isNaN(value) || value <= 0) {
    throw internal('Invalid JWT_EXPIRES_IN value');
  }
  return Math.floor(value / 1000);
})();

const refreshTokenExpiryMs = env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000;

const generateRefreshToken = () => crypto.randomBytes(REFRESH_TOKEN_BYTES).toString('base64url');

export const signAccessToken = (payload: { userId: string; email: string; displayName: string; isAdmin: boolean }) => {
  const options: SignOptions = {
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn'],
    subject: payload.userId,
  };

  return jwt.sign(
    {
      email: payload.email,
      displayName: payload.displayName,
      isAdmin: payload.isAdmin,
    },
    env.JWT_SECRET,
    options,
  );
};

export const createSession = async (
  userId: string,
  metadata?: { ipAddress?: string | null; userAgent?: string | null },
) => {
  const refreshToken = generateRefreshToken();
  const expiresAt = new Date(Date.now() + refreshTokenExpiryMs);

  await prisma.session.create({
    data: {
      userId,
      refreshToken,
      expiresAt,
      ipAddress: metadata?.ipAddress ?? null,
      userAgent: metadata?.userAgent ?? null,
    },
  });

  return { refreshToken, expiresAt };
};

export const rotateSession = async (
  currentRefreshToken: string,
  metadata?: { ipAddress?: string | null; userAgent?: string | null },
) => {
  const session = await prisma.session.findUnique({ where: { refreshToken: currentRefreshToken } });
  if (!session || session.revokedAt || session.expiresAt <= new Date()) {
    throw new AppError('Invalid or expired refresh token', 401);
  }

  const newToken = generateRefreshToken();
  const expiresAt = new Date(Date.now() + refreshTokenExpiryMs);

  await prisma.session.update({
    where: { id: session.id },
    data: {
      refreshToken: newToken,
      expiresAt,
      ipAddress: metadata?.ipAddress ?? session.ipAddress,
      userAgent: metadata?.userAgent ?? session.userAgent,
      revokedAt: null,
    },
  });

  return { userId: session.userId, refreshToken: newToken, expiresAt };
};

export const revokeSession = async (refreshToken: string) => {
  await prisma.session.updateMany({
    where: { refreshToken },
    data: { revokedAt: new Date() },
  });
};

export const buildAuthPayload = (
  user: { id: string; email: string; displayName: string; isAdmin: boolean; avatarUrl?: string | null },
  refreshToken: string,
  refreshExpiresAt: Date,
) => {
  const accessToken = signAccessToken({
    userId: user.id,
    email: user.email,
    displayName: user.displayName,
    isAdmin: user.isAdmin,
  });

  return {
    user: {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl ?? null,
    },
    accessToken,
    refreshToken,
    expiresIn: ACCESS_TOKEN_EXPIRES_IN_SECONDS,
    isAdmin: user.isAdmin,
    refreshExpiresAt,
  } as const;
};
