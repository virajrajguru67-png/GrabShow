import type {
  Movie,
  MovieGenre,
  MovieLanguage,
  Prisma,
  Showtime,
  ShowtimePricingTier,
  ShowtimeStatus,
} from '@prisma/client';

import type { SeatDefinition, SeatLayoutPayload, SeatRow } from '../admin/admin.types.js';

const decimalToNumber = (value: Prisma.Decimal | number | null | undefined) => {
  if (value == null) return null;
  if (typeof value === 'number') return value;
  return value.toNumber();
};

const toLower = (value: string) => value.toLowerCase();

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

type MovieSummaryShowtime = {
  id: string;
  startsAt: Date;
};

type MovieSummaryRecord = Movie & {
  genres: MovieGenre[];
  languages: MovieLanguage[];
  showtimes: MovieSummaryShowtime[];
};

type ShowtimeWithContext = Showtime & {
  auditorium: Prisma.AuditoriumGetPayload<{ select: { id: true; cinemaId: true; cinemaName: true; name: true } }>;
  pricingTiers: ShowtimePricingTier[];
};

type MovieDetailRecord = Movie & {
  genres: MovieGenre[];
  languages: MovieLanguage[];
  showtimes: ShowtimeWithContext[];
};

interface MovieMetadata {
  cast?: string[];
  ticketPrices?: Record<string, number>;
  [key: string]: unknown;
}

const parseMetadata = (metadata: unknown): MovieMetadata => {
  if (!metadata || typeof metadata !== 'object') return {};
  return metadata as MovieMetadata;
};

const unique = <T>(values: T[]) => Array.from(new Set(values));

export const toMovieSummary = (movie: MovieSummaryRecord) => {
  const upcomingShowtimes = movie.showtimes
    .filter((showtime) => showtime.startsAt > new Date())
    .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());

  return {
    id: movie.id,
    title: movie.title,
    slug: movie.slug,
    tagline: movie.tagline,
    synopsis: movie.synopsis,
    posterUrl: movie.posterUrl,
    backdropUrl: movie.backdropUrl,
    releaseYear: movie.releaseYear,
    rating: decimalToNumber(movie.rating),
    durationMinutes: movie.durationMinutes,
    genres: movie.genres.map((item) => item.name),
    languages: movie.languages.map((item) => item.name),
    status: movie.status.toLowerCase(),
    isTrending: movie.isTrending,
    isTopPick: movie.isTopPick,
    isUpcoming: movie.isUpcoming,
    nextShowtime: upcomingShowtimes[0]?.startsAt.toISOString() ?? null,
  };
};

const mapPricingTier = (tier: ShowtimePricingTier) => ({
  id: tier.id,
  label: tier.label,
  price: decimalToNumber(tier.price),
  seatTypes: Array.isArray(tier.seatTypes) ? (tier.seatTypes as string[]) : [],
});

const mapShowtimeInfo = (showtime: ShowtimeWithContext) => ({
  id: showtime.id,
  movieId: showtime.movieId,
  auditoriumId: showtime.auditoriumId,
  auditoriumName: showtime.auditorium.name,
  cinemaId: showtime.auditorium.cinemaId,
  cinemaName: showtime.auditorium.cinemaName,
  startsAt: showtime.startsAt.toISOString(),
  endsAt: showtime.endsAt.toISOString(),
  basePrice: decimalToNumber(showtime.basePrice),
  status: showtimeStatusToClient(showtime.status),
  seatLayoutVersion: showtime.seatLayoutVersion,
  pricingTiers: showtime.pricingTiers.map(mapPricingTier),
});

export const toMovieDetail = (movie: MovieDetailRecord) => {
  const metadata = parseMetadata(movie.metadata);
  const cast = Array.isArray(metadata.cast) ? unique(metadata.cast as string[]) : [];

  const showtimes = movie.showtimes
    .slice()
    .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());

  const seatTypePrices = new Map<string, number>();
  const earliestOnSale = showtimes.find((showtime) => showtime.status === 'ON_SALE' || showtime.status === 'SCHEDULED');
  if (earliestOnSale) {
    const basePrice = decimalToNumber(earliestOnSale.basePrice) ?? 0;
    earliestOnSale.pricingTiers.forEach((tier) => {
      const price = decimalToNumber(tier.price) ?? basePrice;
      const types = Array.isArray(tier.seatTypes) ? (tier.seatTypes as string[]) : [];
      types.forEach((type) => {
        const key = toLower(type);
        if (!seatTypePrices.has(key)) {
          seatTypePrices.set(key, price);
        }
      });
    });
    if (!seatTypePrices.size) {
      seatTypePrices.set('standard', basePrice);
    }
  }

  const metadataTicketPricesRaw = metadata.ticketPrices;
  const metadataTicketPrices =
    metadataTicketPricesRaw && typeof metadataTicketPricesRaw === 'object'
      ? (metadataTicketPricesRaw as Record<string, number>)
      : {};

  const ticketPrices = Object.fromEntries(
    unique([
      ...Object.keys(metadataTicketPrices),
      ...Array.from(seatTypePrices.keys()),
    ]).map((key) => [key, metadataTicketPrices[key] ?? seatTypePrices.get(key) ?? 0]),
  );

  return {
    id: movie.id,
    title: movie.title,
    slug: movie.slug,
    synopsis: movie.synopsis,
    tagline: movie.tagline,
    posterUrl: movie.posterUrl,
    backdropUrl: movie.backdropUrl,
    releaseYear: movie.releaseYear,
    rating: decimalToNumber(movie.rating),
    durationMinutes: movie.durationMinutes,
    genres: movie.genres.map((item) => item.name),
    languages: movie.languages.map((item) => item.name),
    status: movie.status.toLowerCase(),
    isTrending: movie.isTrending,
    isTopPick: movie.isTopPick,
    isUpcoming: movie.isUpcoming,
    cast,
    showtimes: showtimes.map(mapShowtimeInfo),
    ticketPrices,
    metadata,
  };
};

export const buildSeatTypeMap = (layout: SeatLayoutPayload) => {
  const map = new Map<string, string>();
  for (const row of layout.rows ?? []) {
    for (const seat of row.seats ?? []) {
      map.set(seat.seatId, seat.type);
    }
  }
  return map;
};

export const buildSeatMapWithAvailability = (layout: SeatLayoutPayload, reservedSeatIds: Set<string>) => ({
  version: layout.version,
  rows: (layout.rows ?? []).map((row: SeatRow) => ({
    rowLabel: row.rowLabel,
    seats: (row.seats ?? []).map((seat: SeatDefinition) => ({
      seatId: seat.seatId,
      label: seat.label,
      type: seat.type,
      isAisle: Boolean(seat.isAisle),
      isAvailable: !reservedSeatIds.has(seat.seatId) && !seat.blocked,
    })),
  })),
});
