import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import type { JwtPayload } from 'jsonwebtoken';

import { env } from '../config/index.js';
import { unauthorized } from '../errors/app-error.js';
import { prisma } from '../services/prisma.js';
import type { UserWithAdmin } from '../modules/auth/auth.service.js';
import { asyncHandler } from '../utils/async-handler.js';

const { TokenExpiredError, JsonWebTokenError } = jwt;

export interface AuthContext {
  user: UserWithAdmin;
  token: string;
}

export type RequestWithAuth = Request & { auth?: AuthContext };

const parseToken = (header?: string | string[]) => {
  if (!header) return null;
  const value = Array.isArray(header) ? header[0] : header;
  if (!value?.startsWith('Bearer ')) return null;
  return value.slice(7).trim();
};

export const authenticate = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const token = parseToken(req.headers.authorization);
  if (!token) {
    throw unauthorized('Authentication required');
  }

  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as JwtPayload;

    if (!payload.sub) {
      throw unauthorized('Invalid token');
    }

    const user = (await prisma.user.findUnique({
      where: { id: payload.sub },
      include: {
        adminProfile: { include: { roles: true } },
      },
    })) as UserWithAdmin | null;

    if (!user) {
      throw unauthorized('User no longer exists');
    }

    (req as RequestWithAuth).auth = { user, token };
    next();
  } catch (error) {
    if (error instanceof TokenExpiredError) {
      throw unauthorized('Session expired');
    }
    if (error instanceof JsonWebTokenError) {
      throw unauthorized('Invalid token');
    }
    throw error;
  }
});

export const requireAuth = (req: Request, _res: Response, next: NextFunction) => {
  const context = (req as RequestWithAuth).auth;
  if (!context) {
    throw unauthorized('Authentication required');
  }
  next();
};

export const requireAdmin = (req: Request, _res: Response, next: NextFunction) => {
  const context = (req as RequestWithAuth).auth;
  if (!context) {
    throw unauthorized('Authentication required');
  }

  if (!context.user.isAdmin || !context.user.adminProfile) {
    throw unauthorized('Admin privileges required');
  }

  next();
};
