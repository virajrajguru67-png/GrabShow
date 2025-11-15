import { Router } from 'express';
import { prisma } from '../services/prisma.js';
export const router = Router();
router.get('/', async (_req, res) => {
    try {
        await prisma.$queryRaw `SELECT 1`;
        res.json({ status: 'healthy' });
    }
    catch (error) {
        res.status(503).json({ status: 'degraded', error: error.message });
    }
});
//# sourceMappingURL=health.js.map