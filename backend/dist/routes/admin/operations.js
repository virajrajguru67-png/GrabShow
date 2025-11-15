import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { asyncHandler } from '../../utils/async-handler.js';
import { auditoriumCreateSchema, auditoriumLayoutUpdateSchema, auditoriumUpdateSchema, campaignPayloadSchema, inviteAdminSchema, platformSettingsPayloadSchema, seatLayoutSchema, showtimePayloadSchema, showtimeUpdateSchema, updateAdminSchema, } from '../../modules/admin/admin.schemas.js';
import { mapAdminUser, mapAuditorium, mapBooking, mapNotificationCampaign, mapNotificationSegment, mapPlatformSettings, mapSettlement, mapShowtime, showtimeStatusFromClient, mapSeatLayoutJson, calculateSeatMetrics, } from '../../modules/admin/admin.mappers.js';
import { prisma } from '../../services/prisma.js';
import { notFound } from '../../errors/app-error.js';
import { hashPassword } from '../../utils/password.js';
export const operationsRouter = Router();
const decimal = (value) => typeof value === 'number' ? new Prisma.Decimal(value) : new Prisma.Decimal(value.toNumber());
/** Auditoriums */
operationsRouter.get('/auditoriums', asyncHandler(async (_req, res) => {
    const auditoriums = await prisma.auditorium.findMany({
        select: {
            id: true,
            cinemaId: true,
            cinemaName: true,
            name: true,
            capacity: true,
            layoutVersion: true,
            layoutUpdatedAt: true,
            layoutJson: true,
        },
        orderBy: [
            { cinemaName: 'asc' },
            { name: 'asc' },
        ],
    });
    res.json({ data: auditoriums.map(mapAuditorium) });
}));
operationsRouter.post('/auditoriums', asyncHandler(async (req, res) => {
    const payload = auditoriumCreateSchema.parse(req.body);
    const rawLayout = payload.layout ?? { version: 1, rows: [] };
    const layout = seatLayoutSchema.parse(rawLayout);
    const metrics = calculateSeatMetrics(layout);
    const computedCapacity = metrics.totalSeats > 0 ? metrics.totalSeats : payload.capacity;
    const created = await prisma.auditorium.create({
        data: {
            cinemaId: payload.cinemaId,
            cinemaName: payload.cinemaName,
            name: payload.name,
            capacity: computedCapacity,
            layoutVersion: layout.version,
            layoutUpdatedAt: new Date(),
            layoutJson: mapSeatLayoutJson(layout),
        },
        select: {
            id: true,
            cinemaId: true,
            cinemaName: true,
            name: true,
            capacity: true,
            layoutVersion: true,
            layoutUpdatedAt: true,
            layoutJson: true,
        },
    });
    res.status(201).json({ data: mapAuditorium(created) });
}));
operationsRouter.put('/auditoriums/:id', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const payload = auditoriumUpdateSchema.parse(req.body);
    const auditorium = await prisma.auditorium.findUnique({ where: { id } });
    if (!auditorium) {
        throw notFound('Auditorium not found');
    }
    const updated = await prisma.auditorium.update({
        where: { id },
        data: {
            cinemaId: payload.cinemaId ?? auditorium.cinemaId,
            cinemaName: payload.cinemaName ?? auditorium.cinemaName,
            name: payload.name ?? auditorium.name,
            capacity: payload.capacity ?? auditorium.capacity,
        },
        select: {
            id: true,
            cinemaId: true,
            cinemaName: true,
            name: true,
            capacity: true,
            layoutVersion: true,
            layoutUpdatedAt: true,
            layoutJson: true,
        },
    });
    res.json({ data: mapAuditorium(updated) });
}));
operationsRouter.put('/auditoriums/:id/layout', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const payload = auditoriumLayoutUpdateSchema.parse(req.body);
    const auditorium = await prisma.auditorium.findUnique({ where: { id } });
    if (!auditorium) {
        throw notFound('Auditorium not found');
    }
    const layout = seatLayoutSchema.parse({
        version: payload.version,
        rows: payload.rows,
    });
    const metrics = calculateSeatMetrics(layout);
    const updated = await prisma.auditorium.update({
        where: { id },
        data: {
            layoutVersion: layout.version,
            layoutUpdatedAt: new Date(),
            layoutJson: mapSeatLayoutJson(layout),
            capacity: metrics.totalSeats > 0 ? metrics.totalSeats : auditorium.capacity,
        },
        select: {
            id: true,
            cinemaId: true,
            cinemaName: true,
            name: true,
            capacity: true,
            layoutVersion: true,
            layoutUpdatedAt: true,
            layoutJson: true,
        },
    });
    res.json({ data: mapAuditorium(updated) });
}));
/** Showtimes */
operationsRouter.get('/showtimes', asyncHandler(async (_req, res) => {
    const showtimes = await prisma.showtime.findMany({
        include: {
            movie: true,
            auditorium: {
                select: { id: true, cinemaId: true, cinemaName: true, name: true, layoutVersion: true },
            },
            pricingTiers: true,
        },
        orderBy: { startsAt: 'asc' },
    });
    res.json({ data: showtimes.map(mapShowtime) });
}));
operationsRouter.post('/showtimes', asyncHandler(async (req, res) => {
    const payload = showtimePayloadSchema.parse(req.body);
    const auditorium = await prisma.auditorium.findUnique({ where: { id: payload.auditoriumId } });
    if (!auditorium) {
        throw notFound('Auditorium not found');
    }
    const showtime = await prisma.showtime.create({
        data: {
            movieId: payload.movieId,
            auditoriumId: payload.auditoriumId,
            startsAt: new Date(payload.startsAt),
            endsAt: new Date(payload.endsAt),
            basePrice: decimal(payload.basePrice),
            status: showtimeStatusFromClient(payload.status),
            seatLayoutVersion: payload.seatLayoutVersion ?? auditorium.layoutVersion,
            pricingTiers: {
                create: payload.pricingTiers.map((tier) => ({
                    label: tier.label,
                    price: decimal(tier.price),
                    seatTypes: tier.seatTypes,
                })),
            },
        },
        include: {
            movie: true,
            auditorium: {
                select: { id: true, cinemaId: true, cinemaName: true, name: true, layoutVersion: true },
            },
            pricingTiers: true,
        },
    });
    res.status(201).json({ data: mapShowtime(showtime) });
}));
operationsRouter.put('/showtimes/:id', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const payload = showtimeUpdateSchema.parse(req.body);
    const showtime = await prisma.showtime.findUnique({ where: { id } });
    if (!showtime) {
        throw notFound('Showtime not found');
    }
    const updated = await prisma.showtime.update({
        where: { id },
        data: {
            movieId: payload.movieId ?? showtime.movieId,
            auditoriumId: payload.auditoriumId ?? showtime.auditoriumId,
            startsAt: payload.startsAt ? new Date(payload.startsAt) : showtime.startsAt,
            endsAt: payload.endsAt ? new Date(payload.endsAt) : showtime.endsAt,
            basePrice: payload.basePrice ? decimal(payload.basePrice) : showtime.basePrice,
            status: payload.status ? showtimeStatusFromClient(payload.status) : showtime.status,
            seatLayoutVersion: payload.seatLayoutVersion ?? showtime.seatLayoutVersion,
            pricingTiers: payload.pricingTiers
                ? {
                    deleteMany: {},
                    create: payload.pricingTiers.map((tier) => ({
                        label: tier.label,
                        price: decimal(tier.price),
                        seatTypes: tier.seatTypes,
                    })),
                }
                : undefined,
        },
        include: {
            movie: true,
            auditorium: {
                select: { id: true, cinemaId: true, cinemaName: true, name: true, layoutVersion: true },
            },
            pricingTiers: true,
        },
    });
    res.json({ data: mapShowtime(updated) });
}));
operationsRouter.delete('/showtimes/:id', asyncHandler(async (req, res) => {
    const { id } = req.params;
    await prisma.showtime.delete({ where: { id } });
    res.status(204).send();
}));
/** Bookings */
operationsRouter.get('/bookings', asyncHandler(async (_req, res) => {
    const bookings = await prisma.booking.findMany({
        include: {
            tickets: true,
            auditLog: { orderBy: { createdAt: 'desc' } },
        },
        orderBy: { purchasedAt: 'desc' },
    });
    res.json({ data: bookings.map(mapBooking) });
}));
const addBookingAudit = async (bookingId, type, message) => {
    await prisma.bookingAudit.create({
        data: {
            bookingId,
            type,
            message,
            actor: 'System',
        },
    });
};
operationsRouter.post('/bookings/:id/cancel', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const booking = await prisma.booking.update({
        where: { id },
        data: {
            status: 'CANCELLED',
        },
        include: {
            tickets: true,
            auditLog: { orderBy: { createdAt: 'desc' } },
        },
    });
    await addBookingAudit(id, 'cancelled', 'Booking cancelled by admin');
    res.json({ data: mapBooking(booking) });
}));
operationsRouter.post('/bookings/:id/refund', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const booking = await prisma.booking.update({
        where: { id },
        data: {
            status: 'REFUNDED',
        },
        include: {
            tickets: true,
            auditLog: { orderBy: { createdAt: 'desc' } },
        },
    });
    await addBookingAudit(id, 'refunded', 'Refund initiated by admin');
    res.json({ data: mapBooking(booking) });
}));
/** Settlements */
operationsRouter.get('/settlements/ledger', asyncHandler(async (_req, res) => {
    const settlements = await prisma.settlementTransaction.findMany({
        orderBy: { createdAt: 'desc' },
    });
    res.json({ data: settlements.map(mapSettlement) });
}));
/** Admin users */
operationsRouter.get('/users', asyncHandler(async (_req, res) => {
    const users = await prisma.adminUser.findMany({
        include: {
            user: true,
            roles: true,
        },
        orderBy: { createdAt: 'desc' },
    });
    res.json({ data: users.map(mapAdminUser) });
}));
operationsRouter.post('/users/invite', asyncHandler(async (req, res) => {
    const payload = inviteAdminSchema.parse(req.body);
    const roles = payload.roles.map((role) => role.toUpperCase());
    const existingUser = await prisma.user.findUnique({
        where: { email: payload.email.toLowerCase() },
        include: { adminProfile: { include: { roles: true } } },
    });
    let adminUser;
    if (existingUser) {
        adminUser = await prisma.adminUser.upsert({
            where: { userId: existingUser.id },
            update: {
                status: 'INVITED',
                roles: {
                    deleteMany: {},
                    create: roles.map((role) => ({ role: role })),
                },
            },
            create: {
                userId: existingUser.id,
                status: 'INVITED',
                roles: {
                    create: roles.map((role) => ({ role: role })),
                },
            },
            include: { user: true, roles: true },
        });
    }
    else {
        const password = await hashPassword(Math.random().toString(36).slice(2, 10));
        const user = await prisma.user.create({
            data: {
                email: payload.email.toLowerCase(),
                passwordHash: password,
                displayName: payload.name,
                isAdmin: true,
            },
        });
        adminUser = await prisma.adminUser.create({
            data: {
                userId: user.id,
                status: 'INVITED',
                roles: {
                    create: roles.map((role) => ({ role: role })),
                },
            },
            include: { user: true, roles: true },
        });
    }
    res.status(201).json({ data: mapAdminUser(adminUser) });
}));
operationsRouter.put('/users/:id', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const payload = updateAdminSchema.parse(req.body);
    const adminUser = await prisma.adminUser.findUnique({ where: { id } });
    if (!adminUser) {
        throw notFound('Admin user not found');
    }
    const updateData = {};
    if (payload.status) {
        updateData.status = payload.status.toUpperCase();
    }
    if (payload.name) {
        updateData.user = { update: { displayName: payload.name } };
    }
    if (payload.roles) {
        updateData.roles = {
            deleteMany: {},
            create: payload.roles.map((role) => ({ role: role.toUpperCase() })),
        };
    }
    const updated = await prisma.adminUser.update({
        where: { id },
        data: updateData,
        include: {
            user: true,
            roles: true,
        },
    });
    res.json({ data: mapAdminUser(updated) });
}));
/** Notifications */
operationsRouter.get('/notifications/segments', asyncHandler(async (_req, res) => {
    const segments = await prisma.notificationSegment.findMany({ orderBy: { name: 'asc' } });
    res.json({ data: segments.map(mapNotificationSegment) });
}));
operationsRouter.get('/notifications/campaigns', asyncHandler(async (_req, res) => {
    const campaigns = await prisma.notificationCampaign.findMany({
        include: { segment: true },
        orderBy: { createdAt: 'desc' },
    });
    res.json({ data: campaigns.map(mapNotificationCampaign) });
}));
operationsRouter.post('/notifications/campaigns', asyncHandler(async (req, res) => {
    const payload = campaignPayloadSchema.parse(req.body);
    const campaign = await prisma.notificationCampaign.create({
        data: {
            name: payload.name,
            subject: payload.subject,
            channels: payload.channel,
            status: payload.scheduledAt ? 'SCHEDULED' : 'DRAFT',
            scheduledAt: payload.scheduledAt ? new Date(payload.scheduledAt) : undefined,
            segmentId: payload.segmentId,
        },
        include: { segment: true },
    });
    res.status(201).json({ data: mapNotificationCampaign(campaign) });
}));
/** Platform settings */
operationsRouter.get('/settings', asyncHandler(async (_req, res) => {
    let settings = await prisma.platformSettings.findFirst();
    if (!settings) {
        settings = await prisma.platformSettings.create({
            data: {},
        });
    }
    res.json({ data: mapPlatformSettings(settings) });
}));
operationsRouter.put('/settings', asyncHandler(async (req, res) => {
    const payload = platformSettingsPayloadSchema.parse(req.body);
    let settings = await prisma.platformSettings.findFirst();
    if (!settings) {
        settings = await prisma.platformSettings.create({ data: {} });
    }
    const updated = await prisma.platformSettings.update({
        where: { id: settings.id },
        data: {
            razorpayKey: payload.payment.razorpayKey ?? settings.razorpayKey,
            stripeKey: payload.payment.stripeKey ?? settings.stripeKey,
            settlementDays: payload.payment.settlementDays ?? settings.settlementDays,
            cgst: decimal(payload.taxes.cgst ?? settings.cgst),
            sgst: decimal(payload.taxes.sgst ?? settings.sgst),
            convenienceFee: decimal(payload.taxes.convenienceFee ?? settings.convenienceFee),
            theatreName: payload.theatre.name ?? settings.theatreName,
            supportEmail: payload.theatre.supportEmail ?? settings.supportEmail,
            contactNumber: payload.theatre.contactNumber ?? settings.contactNumber,
            address: payload.theatre.address ?? settings.address,
            termsUrl: payload.policies.termsUrl ?? settings.termsUrl,
            privacyUrl: payload.policies.privacyUrl ?? settings.privacyUrl,
            refundWindowHours: payload.policies.refundWindowHours ?? settings.refundWindowHours,
        },
    });
    res.json({ data: mapPlatformSettings(updated) });
}));
//# sourceMappingURL=operations.js.map