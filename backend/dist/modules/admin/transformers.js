import { Prisma, } from '@prisma/client';
const movieStatusMap = {
    DRAFT: 'draft',
    PUBLISHED: 'published',
};
const showtimeStatusToJson = {
    SCHEDULED: 'scheduled',
    ON_SALE: 'on-sale',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled',
};
const showtimeStatusFromJson = {
    scheduled: 'SCHEDULED',
    'on-sale': 'ON_SALE',
    completed: 'COMPLETED',
    cancelled: 'CANCELLED',
};
const bookingStatusMap = {
    RESERVED: 'reserved',
    CONFIRMED: 'confirmed',
    CANCELLED: 'cancelled',
    REFUNDED: 'refunded',
};
const settlementStatusMap = {
    PENDING: 'pending',
    PROCESSING: 'processing',
    COMPLETED: 'completed',
};
const adminStatusMap = {
    INVITED: 'invited',
    ACTIVE: 'active',
    DISABLED: 'disabled',
};
const adminRoleMap = {
    OWNER: 'owner',
    FINANCE: 'finance',
    CONTENT: 'content',
    OPERATIONS: 'operations',
    SUPPORT: 'support',
    MARKETING: 'marketing',
};
const campaignStatusMap = {
    DRAFT: 'draft',
    SCHEDULED: 'scheduled',
    IN_FLIGHT: 'in-flight',
    COMPLETED: 'completed',
};
const campaignChannelMap = {
    EMAIL: 'email',
    SMS: 'sms',
    PUSH: 'push',
};
const adminRoleSet = new Set(Object.keys(adminRoleMap));
const campaignStatusSet = new Set(Object.keys(campaignStatusMap));
const campaignChannelSet = new Set(Object.keys(campaignChannelMap));
export const parseMovieStatus = (status) => {
    if (!status)
        return undefined;
    const value = status.toUpperCase();
    if (value === 'PUBLISHED' || value === 'DRAFT') {
        return value;
    }
    return undefined;
};
export const parseShowtimeStatus = (status) => {
    if (!status)
        return undefined;
    const normalized = status.toLowerCase();
    return showtimeStatusFromJson[normalized] ?? undefined;
};
export const parseAdminStatus = (status) => {
    if (!status)
        return undefined;
    const value = status.toUpperCase();
    if (value === 'INVITED' || value === 'ACTIVE' || value === 'DISABLED') {
        return value;
    }
    return undefined;
};
export const parseAdminRoles = (roles) => roles
    .map((role) => role.toUpperCase())
    .filter((role) => adminRoleSet.has(role));
export const parseCampaignStatus = (status) => {
    if (!status)
        return undefined;
    const value = status.toUpperCase().replace('-', '_');
    if (campaignStatusSet.has(value)) {
        return value;
    }
    return undefined;
};
export const parseCampaignChannels = (channels) => channels
    .map((channel) => channel.toUpperCase())
    .filter((channel) => campaignChannelSet.has(channel));
const toStringArray = (value) => Array.isArray(value) ? value.map((item) => String(item)) : [];
export const movieToDto = (movie) => ({
    id: movie.id,
    title: movie.title,
    slug: movie.slug,
    status: movieStatusMap[movie.status],
    durationMinutes: movie.durationMinutes,
    synopsis: movie.synopsis,
    tagline: movie.tagline,
    posterUrl: movie.posterUrl,
    backdropUrl: movie.backdropUrl,
    genres: movie.genres.map((genre) => genre.name),
    languages: movie.languages.map((language) => language.name),
    metadata: movie.metadata ?? {},
});
export const auditoriumToDto = (auditorium) => {
    const layout = (auditorium.layoutJson ?? {});
    const rows = Array.isArray(layout.rows)
        ? layout.rows
        : [];
    return {
        id: auditorium.id,
        cinemaId: auditorium.cinemaId,
        cinemaName: auditorium.cinemaName,
        name: auditorium.name,
        capacity: auditorium.capacity,
        layout: {
            version: auditorium.layoutVersion,
            updatedAt: auditorium.layoutUpdatedAt.toISOString(),
            rows,
        },
    };
};
export const pricingTierToDto = (tier) => ({
    id: tier.id,
    label: tier.label,
    price: new Prisma.Decimal(tier.price).toNumber(),
    seatTypes: toStringArray(tier.seatTypes),
});
export const showtimeToDto = (showtime) => ({
    id: showtime.id,
    movieId: showtime.movieId,
    movieTitle: showtime.movie.title,
    cinemaId: showtime.auditorium.cinemaId,
    cinemaName: showtime.auditorium.cinemaName,
    auditoriumId: showtime.auditoriumId,
    auditoriumName: showtime.auditorium.name,
    startsAt: showtime.startsAt.toISOString(),
    endsAt: showtime.endsAt.toISOString(),
    basePrice: new Prisma.Decimal(showtime.basePrice).toNumber(),
    pricingTiers: showtime.pricingTiers.map(pricingTierToDto),
    status: showtimeStatusToJson[showtime.status],
    seatLayoutVersion: showtime.seatLayoutVersion,
});
const mapTicket = (ticket) => ({
    seatId: ticket.seatId,
    seatLabel: ticket.seatLabel,
    price: new Prisma.Decimal(ticket.price).toNumber(),
    tierId: ticket.tierId ?? undefined,
});
const mapAudit = (audit) => ({
    id: audit.id,
    type: audit.type,
    message: audit.message,
    actor: audit.actor,
    createdAt: audit.createdAt.toISOString(),
});
export const bookingToDto = (booking) => ({
    id: booking.id,
    reference: booking.reference,
    movieTitle: booking.movieTitle,
    showtimeId: booking.showtimeId,
    purchaserEmail: booking.purchaserEmail,
    purchaserName: booking.purchaserName,
    status: bookingStatusMap[booking.status],
    totalAmount: new Prisma.Decimal(booking.totalAmount).toNumber(),
    currency: booking.currency,
    purchasedAt: booking.purchasedAt.toISOString(),
    tickets: booking.tickets.map(mapTicket),
    auditLog: booking.auditLog
        .slice()
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
        .map(mapAudit),
});
export const settlementToDto = (settlement) => ({
    id: settlement.id,
    gateway: settlement.gateway,
    transactionId: settlement.transactionId,
    amount: new Prisma.Decimal(settlement.amount).toNumber(),
    fees: new Prisma.Decimal(settlement.fees).toNumber(),
    netPayout: new Prisma.Decimal(settlement.netPayout).toNumber(),
    currency: settlement.currency,
    status: settlementStatusMap[settlement.status],
    bookingReference: settlement.bookingId ?? '',
    settledAt: settlement.settledAt?.toISOString() ?? null,
    createdAt: settlement.createdAt.toISOString(),
});
export const adminUserToDto = (adminUser) => ({
    id: adminUser.id,
    email: adminUser.user.email,
    name: adminUser.name ?? adminUser.user.displayName,
    roles: adminUser.roles.map((role) => adminRoleMap[role.role]),
    lastActiveAt: adminUser.lastActiveAt?.toISOString() ?? null,
    status: adminStatusMap[adminUser.status],
});
export const segmentToDto = (segment) => ({
    id: segment.id,
    name: segment.name,
    description: segment.description ?? '',
});
export const campaignToDto = (campaign) => ({
    id: campaign.id,
    name: campaign.name,
    subject: campaign.subject,
    channels: campaign.channels.map((entry) => campaignChannelMap[entry.channel]),
    status: campaignStatusMap[campaign.status],
    scheduledAt: campaign.scheduledAt?.toISOString() ?? null,
    createdAt: campaign.createdAt.toISOString(),
    segmentId: campaign.segmentId,
    stats: {
        sent: campaign.sent,
        opened: campaign.opened,
        clicked: campaign.clicked,
    },
});
export const normalizeUserResponse = (user) => ({
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    isAdmin: user.isAdmin,
});
//# sourceMappingURL=transformers.js.map