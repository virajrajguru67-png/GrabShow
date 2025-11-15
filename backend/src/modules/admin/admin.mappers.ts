import type {
  AdminStatus,
  AdminUser,
  AdminUserRole,
  Booking,
  BookingAudit,
  BookingStatus,
  BookingTicket,
  Movie,
  MovieGenre,
  MovieLanguage,
  NotificationCampaign,
  NotificationSegment,
  PaymentAudit,
  PlatformSettings,
  Prisma,
  SettlementStatus,
  SettlementTransaction,
  Showtime,
  ShowtimePricingTier,
  ShowtimeStatus,
  User,
  MovieStatus,
} from '@prisma/client';

import type { SeatDefinition, SeatLayoutPayload, SeatRow } from './admin.types.js';

const toNumber = (value: Prisma.Decimal | number) =>
  typeof value === 'number' ? value : value.toNumber();

const movieStatusToClient = (status: MovieStatus) => status.toLowerCase();
const movieStatusFromClient = (status: string) => status.toUpperCase() as MovieStatus;

const showtimeStatusToClient = (status: ShowtimeStatus) => {
  switch (status) {
    case 'ON_SALE':
      return 'on-sale';
    case 'COMPLETED':
      return 'completed';
    case 'CANCELLED':
      return 'cancelled';
    default:
      return 'scheduled';
  }
};

export const showtimeStatusFromClient = (status: string) => {
  switch (status) {
    case 'on-sale':
      return 'ON_SALE';
    case 'completed':
      return 'COMPLETED';
    case 'cancelled':
      return 'CANCELLED';
    default:
      return 'SCHEDULED';
  }
};

const bookingStatusToClient = (status: BookingStatus) => status.toLowerCase();

const settlementStatusToClient = (status: SettlementStatus) => status.toLowerCase();

const adminStatusToClient = (status: AdminStatus) => status.toLowerCase();

export type MovieWithRelations = Movie & {
  genres: MovieGenre[];
  languages: MovieLanguage[];
};

export const mapMovie = (movie: MovieWithRelations) => ({
  id: movie.id,
  title: movie.title,
  slug: movie.slug,
  status: movieStatusToClient(movie.status),
  durationMinutes: movie.durationMinutes,
  synopsis: movie.synopsis,
  tagline: movie.tagline,
  posterUrl: movie.posterUrl,
  backdropUrl: movie.backdropUrl,
  releaseYear: movie.releaseYear,
  rating: movie.rating ? toNumber(movie.rating) : null,
  genres: movie.genres.map((item) => item.name),
  languages: movie.languages.map((item) => item.name),
  isTrending: movie.isTrending,
  isTopPick: movie.isTopPick,
  isUpcoming: movie.isUpcoming,
  metadata: movie.metadata ?? null,
});

export type ShowtimeWithRelations = Showtime & {
  movie: Movie;
  auditorium: Prisma.AuditoriumGetPayload<{ select: { id: true; cinemaId: true; cinemaName: true; name: true; layoutVersion: true } }>;
  pricingTiers: ShowtimePricingTier[];
};

export const mapShowtime = (showtime: ShowtimeWithRelations) => ({
  id: showtime.id,
  movieId: showtime.movieId,
  movieTitle: showtime.movie.title,
  cinemaId: showtime.auditorium.cinemaId,
  cinemaName: showtime.auditorium.cinemaName,
  auditoriumId: showtime.auditoriumId,
  auditoriumName: showtime.auditorium.name,
  startsAt: showtime.startsAt.toISOString(),
  endsAt: showtime.endsAt.toISOString(),
  basePrice: toNumber(showtime.basePrice),
  pricingTiers: showtime.pricingTiers.map((tier) => ({
    id: tier.id,
    label: tier.label,
    price: toNumber(tier.price),
    seatTypes: Array.isArray(tier.seatTypes) ? (tier.seatTypes as string[]) : [],
  })),
  status: showtimeStatusToClient(showtime.status),
  seatLayoutVersion: showtime.seatLayoutVersion,
});

export type AuditoriumWithLayout = Prisma.AuditoriumGetPayload<{
  select: {
    id: true;
    cinemaId: true;
    cinemaName: true;
    name: true;
    capacity: true;
    layoutVersion: true;
    layoutUpdatedAt: true;
    layoutJson: true;
  };
}>;

export const mapAuditorium = (auditorium: AuditoriumWithLayout) => {
  const layout = ((auditorium.layoutJson ?? {}) as unknown) as SeatLayoutPayload;
  const metrics = calculateSeatMetrics(layout);
  return {
    id: auditorium.id,
    cinemaId: auditorium.cinemaId,
    cinemaName: auditorium.cinemaName,
    name: auditorium.name,
    capacity: auditorium.capacity,
    layout: {
      version: auditorium.layoutVersion,
      updatedAt: auditorium.layoutUpdatedAt.toISOString(),
      rows: layout.rows ?? [],
    },
    stats: {
      totalSeats: metrics.totalSeats,
      availableSeats: metrics.activeSeats,
      blockedSeats: metrics.blockedSeats,
    },
  };
};

export type BookingWithRelations = Booking & {
  tickets: BookingTicket[];
  auditLog: BookingAudit[];
};

export const mapBooking = (booking: BookingWithRelations) => ({
  id: booking.id,
  reference: booking.reference,
  movieTitle: booking.movieTitle,
  showtimeId: booking.showtimeId,
  purchaserEmail: booking.purchaserEmail,
  purchaserName: booking.purchaserName,
  status: bookingStatusToClient(booking.status),
  totalAmount: toNumber(booking.totalAmount),
  currency: booking.currency,
  purchasedAt: booking.purchasedAt.toISOString(),
  tickets: booking.tickets.map((ticket) => ({
    seatId: ticket.seatId,
    seatLabel: ticket.seatLabel,
    price: toNumber(ticket.price),
    tierId: ticket.tierId,
  })),
  auditLog: booking.auditLog.map((entry) => ({
    id: entry.id,
    type: entry.type,
    message: entry.message,
    createdAt: entry.createdAt.toISOString(),
    actor: entry.actor,
  })),
});

export const mapSettlement = (settlement: SettlementTransaction) => ({
  id: settlement.id,
  gateway: settlement.gateway,
  transactionId: settlement.transactionId,
  amount: toNumber(settlement.amount),
  currency: settlement.currency,
  status: settlementStatusToClient(settlement.status),
  fees: toNumber(settlement.fees),
  netPayout: toNumber(settlement.netPayout),
  settledAt: settlement.settledAt ? settlement.settledAt.toISOString() : null,
  bookingReference: settlement.bookingId ?? null,
});

export type AdminUserWithRelations = AdminUser & {
  user: User;
  roles: AdminUserRole[];
};

export const mapAdminUser = (record: AdminUserWithRelations) => ({
  id: record.id,
  email: record.user.email,
  name: record.user.displayName,
  roles: record.roles.map((role) => role.role.toLowerCase()),
  lastActiveAt: record.lastActiveAt?.toISOString() ?? record.user.updatedAt.toISOString(),
  status: adminStatusToClient(record.status),
});

export const mapNotificationSegment = (segment: NotificationSegment) => ({
  id: segment.id,
  name: segment.name,
  description: segment.description ?? '',
  createdAt: segment.createdAt.toISOString(),
});

export const mapNotificationCampaign = (
  campaign: NotificationCampaign & { segment: NotificationSegment },
) => ({
  id: campaign.id,
  name: campaign.name,
  subject: campaign.subject,
  channels: Array.isArray(campaign.channels) ? (campaign.channels as string[]) : [],
  status: (() => {
    switch (campaign.status) {
      case 'IN_FLIGHT':
        return 'in-flight';
      case 'SCHEDULED':
        return 'scheduled';
      case 'COMPLETED':
        return 'completed';
      default:
        return 'draft';
    }
  })(),
  scheduledAt: campaign.scheduledAt ? campaign.scheduledAt.toISOString() : null,
  createdAt: campaign.createdAt.toISOString(),
  segmentId: campaign.segmentId,
  stats: {
    sent: campaign.statsSent,
    opened: campaign.statsOpened,
    clicked: campaign.statsClicked,
  },
  segment: {
    id: campaign.segment.id,
    name: campaign.segment.name,
  },
});

export const buildSeatLayoutPayload = (layout: SeatLayoutPayload) => ({
  version: layout.version,
  rows: layout.rows ?? [],
  updatedAt: layout.updatedAt ?? new Date().toISOString(),
});

export const mapPaymentAudit = (audit: PaymentAudit) => ({
  id: audit.id,
  transactionId: audit.transactionId,
  status: audit.status,
  method: audit.method,
  amount: toNumber(audit.amount),
  movieTitle: audit.movieTitle,
  showtime: audit.showtime,
  seats: audit.seats ?? [],
  createdAt: audit.createdAt.toISOString(),
});

export const mapSeatLayoutJson = (layout: SeatLayoutPayload) => ({
  version: layout.version,
  rows: layout.rows.map((row: SeatRow) => ({
    rowLabel: row.rowLabel,
    seats: row.seats.map((seat: SeatDefinition) => ({
      seatId: seat.seatId,
      label: seat.label,
      type: seat.type,
      isAisle: Boolean(seat.isAisle),
      blocked: Boolean(seat.blocked),
    })),
  })),
});

export const calculateSeatMetrics = (layout: SeatLayoutPayload) => {
  const rows = layout.rows ?? [];
  let totalSeats = 0;
  let blockedSeats = 0;

  rows.forEach((row) => {
    row.seats.forEach((seat) => {
      totalSeats += 1;
      if (seat.blocked) {
        blockedSeats += 1;
      }
    });
  });

  const activeSeats = totalSeats - blockedSeats;

  return { totalSeats, blockedSeats, activeSeats };
};

export const mapPlatformSettings = (settings: PlatformSettings) => ({
  payment: {
    razorpayKey: settings.razorpayKey,
    stripeKey: settings.stripeKey,
    settlementDays: settings.settlementDays,
  },
  taxes: {
    cgst: toNumber(settings.cgst),
    sgst: toNumber(settings.sgst),
    convenienceFee: toNumber(settings.convenienceFee),
  },
  theatre: {
    name: settings.theatreName,
    supportEmail: settings.supportEmail,
    contactNumber: settings.contactNumber,
    address: settings.address,
  },
  policies: {
    termsUrl: settings.termsUrl,
    privacyUrl: settings.privacyUrl,
    refundWindowHours: settings.refundWindowHours,
  },
  updatedAt: settings.updatedAt.toISOString(),
});

export const statusMapper = {
  movieStatusFromClient,
};
