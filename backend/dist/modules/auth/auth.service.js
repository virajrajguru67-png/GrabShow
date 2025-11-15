import { badRequest, conflict, unauthorized } from '../../errors/app-error.js';
import { prisma } from '../../services/prisma.js';
import { hashPassword, verifyPassword } from '../../utils/password.js';
const NORMALIZED_STATUS = {
    INVITED: 'invited',
    ACTIVE: 'active',
    DISABLED: 'disabled',
};
export const findUserByEmail = (email) => prisma.user.findUnique({
    where: { email: email.toLowerCase() },
    include: {
        adminProfile: {
            include: {
                roles: true,
            },
        },
    },
});
export const registerUser = async (payload) => {
    const existing = await findUserByEmail(payload.email);
    if (existing) {
        throw conflict('Email already registered');
    }
    const displayName = payload.displayName.trim();
    if (!displayName) {
        throw badRequest('Display name is required');
    }
    const passwordHash = await hashPassword(payload.password);
    const user = await prisma.user.create({
        data: {
            email: payload.email.toLowerCase(),
            passwordHash,
            displayName,
        },
        include: {
            adminProfile: {
                include: { roles: true },
            },
        },
    });
    return user;
};
export const authenticateUser = async (email, password) => {
    const user = await findUserByEmail(email);
    if (!user) {
        throw unauthorized('Invalid email or password');
    }
    const isValid = await verifyPassword(password, user.passwordHash);
    if (!isValid) {
        throw unauthorized('Invalid email or password');
    }
    return user;
};
export const ensureActiveAdmin = (user) => {
    if (!user.isAdmin || !user.adminProfile) {
        throw unauthorized('Admin access required');
    }
    if (user.adminProfile.status === 'DISABLED') {
        throw unauthorized('Admin account disabled');
    }
    return {
        ...user,
        adminProfile: {
            ...user.adminProfile,
            statusLabel: NORMALIZED_STATUS[user.adminProfile.status],
        },
    };
};
export const updateUserProfile = async (userId, payload) => {
    const updateData = {};
    if (payload.displayName !== undefined) {
        const displayName = payload.displayName.trim();
        if (!displayName) {
            throw badRequest('Display name cannot be empty');
        }
        updateData.displayName = displayName;
    }
    if (payload.phoneNumber !== undefined) {
        updateData.phoneNumber = payload.phoneNumber?.trim() || null;
    }
    if (payload.avatarUrl !== undefined) {
        updateData.avatarUrl = payload.avatarUrl && payload.avatarUrl.trim() !== '' ? payload.avatarUrl.trim() : null;
    }
    const user = await prisma.user.update({
        where: { id: userId },
        data: updateData,
        include: {
            adminProfile: {
                include: { roles: true },
            },
        },
    });
    return user;
};
export const normalizeUserResponse = (user) => ({
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    phoneNumber: user.phoneNumber,
    isAdmin: user.isAdmin,
    adminStatus: user.adminProfile ? NORMALIZED_STATUS[user.adminProfile.status] : null,
});
//# sourceMappingURL=auth.service.js.map