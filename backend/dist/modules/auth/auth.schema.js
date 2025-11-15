import { z } from 'zod';
export const registerSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
    displayName: z.string().min(2),
});
export const loginSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
});
export const refreshSchema = z.object({
    refreshToken: z.string().min(10),
});
export const updateProfileSchema = z.object({
    displayName: z.string().min(2).optional(),
    phoneNumber: z.string().optional().nullable(),
    avatarUrl: z.union([z.string().url(), z.literal(''), z.null()]).optional(),
});
export const forgotPasswordSchema = z.object({
    email: z.string().email(),
});
export const verifyOtpSchema = z.object({
    email: z.string().email(),
    otp: z.string().length(6, 'OTP must be 6 digits').regex(/^\d+$/, 'OTP must contain only digits'),
});
export const resetPasswordSchema = z.object({
    email: z.string().email(),
    otp: z.string().length(6, 'OTP must be 6 digits').regex(/^\d+$/, 'OTP must contain only digits'),
    newPassword: z.string().min(6),
});
//# sourceMappingURL=auth.schema.js.map