import 'dotenv/config';
import { z } from 'zod';
const envSchema = z.object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().int().positive().max(65535).default(5000),
    DATABASE_URL: z
        .string({ required_error: 'DATABASE_URL is required' })
        .url({ message: 'DATABASE_URL must be a valid connection string' }),
    JWT_SECRET: z.string({ required_error: 'JWT_SECRET is required' }).min(16),
    JWT_EXPIRES_IN: z.string().default('1h'),
    REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
    // SMTP Configuration (optional - for password reset emails)
    SMTP_HOST: z.string().optional(),
    SMTP_PORT: z.coerce.number().int().positive().default(587),
    SMTP_SECURE: z.coerce.boolean().default(false),
    SMTP_USER: z.string().optional(),
    SMTP_PASS: z.string().optional(),
    SMTP_FROM_EMAIL: z.string().email().optional(),
    SMTP_FROM_NAME: z.string().default('StreamFlix Tickets'),
    // Frontend URL for password reset links
    FRONTEND_URL: z.string().url().default('http://localhost:3000'),
});
export const env = envSchema.parse({
    NODE_ENV: process.env.NODE_ENV ?? 'development',
    PORT: process.env.PORT ?? 5000,
    DATABASE_URL: process.env.DATABASE_URL,
    JWT_SECRET: process.env.JWT_SECRET,
    JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN ?? '1h',
    REFRESH_TOKEN_TTL_DAYS: process.env.REFRESH_TOKEN_TTL_DAYS ?? 30,
    SMTP_HOST: process.env.SMTP_HOST,
    SMTP_PORT: process.env.SMTP_PORT ?? 587,
    SMTP_SECURE: process.env.SMTP_SECURE === 'true',
    SMTP_USER: process.env.SMTP_USER,
    SMTP_PASS: process.env.SMTP_PASS,
    SMTP_FROM_EMAIL: process.env.SMTP_FROM_EMAIL,
    SMTP_FROM_NAME: process.env.SMTP_FROM_NAME ?? 'StreamFlix Tickets',
    FRONTEND_URL: process.env.FRONTEND_URL ?? 'http://localhost:3000',
});
//# sourceMappingURL=env.js.map