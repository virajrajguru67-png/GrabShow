import { Router } from 'express';
import { authenticate, requireAdmin } from '../middleware/authenticate.js';
import { buildAuthPayload, createSession } from '../modules/auth/token.service.js';
import { loginSchema } from '../modules/auth/auth.schema.js';
import { authenticateUser, ensureActiveAdmin, normalizeUserResponse } from '../modules/auth/auth.service.js';
import { asyncHandler } from '../utils/async-handler.js';
import { moviesRouter } from './admin/movies.js';
import { operationsRouter } from './admin/operations.js';
export const adminRouter = Router();
adminRouter.post('/login', asyncHandler(async (req, res) => {
    const body = loginSchema.parse(req.body);
    const user = await authenticateUser(body.email, body.password);
    const adminUser = ensureActiveAdmin(user);
    const session = await createSession(adminUser.id, {
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
    });
    const payload = buildAuthPayload(adminUser, session.refreshToken, session.expiresAt);
    const roles = adminUser.adminProfile?.roles?.map((role) => role.role.toLowerCase()) ?? [];
    res.json({
        ...payload,
        user: normalizeUserResponse(adminUser),
        admin: {
            status: adminUser.adminProfile?.statusLabel ?? 'active',
            roles,
        },
        isAdmin: true,
    });
}));
adminRouter.use(authenticate);
adminRouter.use(requireAdmin);
adminRouter.use('/movies', moviesRouter);
adminRouter.use('/operations', operationsRouter);
//# sourceMappingURL=admin.js.map