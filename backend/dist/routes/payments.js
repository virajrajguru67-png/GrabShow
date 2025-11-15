import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { paymentAuditSchema } from '../modules/payments/payment.schema.js';
import { asyncHandler } from '../utils/async-handler.js';
import { prisma } from '../services/prisma.js';
import { mapPaymentAudit } from '../modules/admin/admin.mappers.js';
export const paymentsRouter = Router();
paymentsRouter.post('/audit', asyncHandler(async (req, res) => {
    const payload = paymentAuditSchema.parse(req.body);
    const record = await prisma.paymentAudit.upsert({
        where: { transactionId: payload.transactionId },
        create: {
            transactionId: payload.transactionId,
            status: payload.status,
            method: payload.method,
            amount: new Prisma.Decimal(payload.amount),
            movieTitle: payload.movieTitle,
            showtime: payload.showtime,
            seats: payload.seats ?? [],
        },
        update: {
            status: payload.status,
            method: payload.method,
            amount: new Prisma.Decimal(payload.amount),
            movieTitle: payload.movieTitle,
            showtime: payload.showtime,
            seats: payload.seats ?? [],
        },
    });
    res.status(201).json({ data: mapPaymentAudit(record) });
}));
//# sourceMappingURL=payments.js.map