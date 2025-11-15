import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import ms from 'ms';
import { env } from '../../config/index.js';
import { AppError, internal } from '../../errors/app-error.js';
import { prisma } from '../../services/prisma.js';
const REFRESH_TOKEN_BYTES = 48;
const ACCESS_TOKEN_EXPIRES_IN_SECONDS = (() => {
    const value = ms(env.JWT_EXPIRES_IN);
    if (typeof value !== 'number' || Number.isNaN(value) || value <= 0) {
        throw internal('Invalid JWT_EXPIRES_IN value');
    }
    return Math.floor(value / 1000);
})();
const refreshTokenExpiryMs = env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000;
const generateRefreshToken = () => crypto.randomBytes(REFRESH_TOKEN_BYTES).toString('base64url');
export const signAccessToken = (payload) => {
    const options = {
        expiresIn: env.JWT_EXPIRES_IN,
        subject: payload.userId,
    };
    return jwt.sign({
        email: payload.email,
        displayName: payload.displayName,
        isAdmin: payload.isAdmin,
    }, env.JWT_SECRET, options);
};
export const createSession = async (userId, metadata) => {
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
export const rotateSession = async (currentRefreshToken, metadata) => {
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
export const revokeSession = async (refreshToken) => {
    await prisma.session.updateMany({
        where: { refreshToken },
        data: { revokedAt: new Date() },
    });
};
export const buildAuthPayload = (user, refreshToken, refreshExpiresAt) => {
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
    };
};
//# sourceMappingURL=token.service.js.map