import { Router } from 'express';
import { Prisma } from '@prisma/client';

import { asyncHandler } from '../utils/async-handler.js';
import { prisma } from '../services/prisma.js';
import {
  bookingReferenceSchema,
  createBookingSchema,
  movieIdentifierSchema,
  movieListQuerySchema,
  showtimeParamSchema,
} from '../modules/catalog/catalog.schemas.js';
import {
  buildSeatMapWithAvailability,
  buildSeatTypeMap,
  toMovieDetail,
  toMovieSummary,
} from '../modules/catalog/catalog.mappers.js';
import type { SeatLayoutPayload } from '../modules/admin/admin.types.js';
import { mapBooking } from '../modules/admin/admin.mappers.js';
import { badRequest, notFound } from '../errors/app-error.js';
import type { RequestWithAuth } from '../middleware/authenticate.js';

export const catalogRouter = Router();

const DEFAULT_LIMIT = 20;

const resolveMovieIdentifier = async (identifier: string) => {
  return prisma.movie.findFirst({
    where: {
      OR: [{ id: identifier }, { slug: identifier }],
    },
    include: {
      genres: true,
      languages: true,
      showtimes: {
        include: {
          auditorium: {
            select: { id: true, cinemaId: true, cinemaName: true, name: true },
          },
          pricingTiers: true,
        },
        orderBy: { startsAt: 'asc' },
      },
    },
  });
};

catalogRouter.get(
  '/movies',
  asyncHandler(async (req, res) => {
    const query = movieListQuerySchema.parse(req.query);
    const limit = query.limit ?? DEFAULT_LIMIT;

    const where: Prisma.MovieWhereInput = { status: 'PUBLISHED' };
    const andConditions: Prisma.MovieWhereInput[] = [];

    if (query.filter === 'trending') {
      andConditions.push({ isTrending: true });
    } else if (query.filter === 'top-picks') {
      andConditions.push({ isTopPick: true });
    } else if (query.filter === 'upcoming') {
      andConditions.push({ isUpcoming: true });
    } else if (query.filter === 'now-showing') {
      andConditions.push({ showtimes: { some: { startsAt: { gte: new Date() } } } });
    }

    if (query.q) {
      const term = query.q.trim();
      andConditions.push({
        OR: [
          { title: { contains: term } },
          { synopsis: { contains: term } },
          { tagline: { contains: term } },
        ],
      });
    }

    if (query.genre) {
      andConditions.push({
        genres: {
          some: {
            name: { contains: query.genre },
          },
        },
      });
    }

    if (query.language) {
      andConditions.push({
        languages: {
          some: {
            name: { contains: query.language },
          },
        },
      });
    }

    if (andConditions.length) {
      where.AND = andConditions;
    }

    const movies = await prisma.movie.findMany({
      where,
      include: {
        genres: true,
        languages: true,
        showtimes: {
          where: {
            startsAt: { gte: new Date(Date.now() - 2 * 60 * 60 * 1000) },
          },
          select: {
            id: true,
            startsAt: true,
          },
          orderBy: { startsAt: 'asc' },
        },
      },
      orderBy: query.filter === 'upcoming' ? { createdAt: 'desc' } : { title: 'asc' },
      take: limit,
    });

    res.json({ data: movies.map(toMovieSummary) });
  }),
);

catalogRouter.get(
  '/movies/:identifier',
  asyncHandler(async (req, res) => {
    const { identifier } = movieIdentifierSchema.parse(req.params);
    const movie = await resolveMovieIdentifier(identifier);
    if (!movie) {
      throw notFound('Movie not found');
    }

    res.json({ data: toMovieDetail(movie) });
  }),
);

catalogRouter.get(
  '/showtimes/:id/seats',
  asyncHandler(async (req, res) => {
    const { id } = showtimeParamSchema.parse(req.params);
    const showtime = await prisma.showtime.findUnique({
      where: { id },
      include: {
        movie: true,
        auditorium: true,
        pricingTiers: true,
        bookings: {
          where: {
            status: { in: ['CONFIRMED', 'RESERVED'] },
          },
          select: {
            tickets: true,
          },
        },
      },
    });

    if (!showtime) {
      throw notFound('Showtime not found');
    }

    const reservedSeats = new Set<string>();
    for (const booking of showtime.bookings) {
      for (const ticket of booking.tickets) {
        reservedSeats.add(ticket.seatId);
      }
    }

    const layout = (showtime.auditorium.layoutJson ?? { rows: [] }) as unknown as SeatLayoutPayload;
    const seatMap = buildSeatMapWithAvailability(layout, reservedSeats);

    res.json({
      data: {
        showtime: {
          id: showtime.id,
          movieId: showtime.movieId,
          auditoriumId: showtime.auditoriumId,
          auditoriumName: showtime.auditorium.name,
          cinemaId: showtime.auditorium.cinemaId,
          cinemaName: showtime.auditorium.cinemaName,
          startsAt: showtime.startsAt.toISOString(),
          endsAt: showtime.endsAt.toISOString(),
          seatLayoutVersion: showtime.seatLayoutVersion,
        },
        seatMap,
        pricingTiers: showtime.pricingTiers.map((tier) => ({
          id: tier.id,
          label: tier.label,
          price: tier.price.toNumber(),
          seatTypes: Array.isArray(tier.seatTypes) ? (tier.seatTypes as string[]) : [],
        })),
      },
    });
  }),
);

const generateBookingReference = async (tx: Prisma.TransactionClient) => {
  let reference: string;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    reference = `SF${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
    const existing = await tx.booking.findUnique({ where: { reference } });
    if (!existing) break;
  }
  return reference;
};

catalogRouter.post(
  '/bookings',
  asyncHandler(async (req, res) => {
    const payload = createBookingSchema.parse(req.body);
    const seatIds = payload.seats.map((seat) => seat.seatId);

    const booking = await prisma.$transaction(async (tx) => {
      const showtime = await tx.showtime.findUnique({
        where: { id: payload.showtimeId },
        include: {
          movie: true,
          auditorium: true,
          pricingTiers: true,
        },
      });

      if (!showtime) {
        throw notFound('Showtime not found');
      }

      const conflicts = await tx.bookingTicket.findMany({
        where: {
          seatId: { in: seatIds },
          booking: {
            showtimeId: payload.showtimeId,
            status: { in: ['CONFIRMED', 'RESERVED'] },
          },
        },
        select: { seatId: true },
      });

      if (conflicts.length) {
        throw badRequest('Selected seats are no longer available', {
          seats: conflicts.map((item) => item.seatId),
        });
      }

      const layout = (showtime.auditorium.layoutJson ?? { rows: [] }) as unknown as SeatLayoutPayload;
      const seatTypeMap = buildSeatTypeMap(layout);
      const pricingByType = new Map<string, { label: string; price: number; id: string }>();
      const basePrice = showtime.basePrice.toNumber();

      for (const tier of showtime.pricingTiers) {
        const price = tier.price.toNumber();
        const seatTypes = Array.isArray(tier.seatTypes) ? (tier.seatTypes as string[]) : [];
        seatTypes.forEach((seatType) => {
          const key = seatType.toLowerCase();
          if (!pricingByType.has(key)) {
            pricingByType.set(key, {
              label: tier.label,
              price,
              id: tier.id,
            });
          }
        });
      }

      let total = 0;
      const ticketPayload = payload.seats.map((seat) => {
        const seatType = (seat.seatType ?? seatTypeMap.get(seat.seatId) ?? '').toLowerCase();
        if (!seatType) {
          throw badRequest('Seat type could not be determined for seat', { seatId: seat.seatId });
        }

        const pricing = pricingByType.get(seatType);
        const price = pricing?.price ?? basePrice;
        total += price;

        return {
          seatId: seat.seatId,
          seatLabel: seat.seatLabel,
          price: new Prisma.Decimal(price),
          tierLabel: pricing?.label,
          tierId: pricing?.id,
        };
      });

      const authContext = (req as RequestWithAuth).auth;
      const booking = await tx.booking.create({
        data: {
          reference: await generateBookingReference(tx),
          showtimeId: payload.showtimeId,
          userId: authContext?.user.id,
          purchaserEmail: payload.purchaser.email.toLowerCase(),
          purchaserName: payload.purchaser.name,
          status: 'CONFIRMED',
          totalAmount: new Prisma.Decimal(total),
          currency: 'INR',
          movieTitle: showtime.movie.title,
          tickets: {
            create: ticketPayload,
          },
          auditLog: {
            create: {
              type: 'booking-created',
              message: 'Booking confirmed',
              actor: authContext ? authContext.user.displayName : payload.purchaser.name,
            },
          },
        },
        include: {
          tickets: true,
          auditLog: { orderBy: { createdAt: 'desc' } },
        },
      });

      return booking;
    });

    res.status(201).json({ data: mapBooking(booking) });
  }),
);

catalogRouter.get(
  '/bookings/:reference',
  asyncHandler(async (req, res) => {
    const { reference } = bookingReferenceSchema.parse(req.params);
    const booking = await prisma.booking.findUnique({
      where: { reference },
      include: {
        tickets: true,
        auditLog: { orderBy: { createdAt: 'desc' } },
      },
    });

    if (!booking) {
      throw notFound('Booking not found');
    }

    res.json({ data: mapBooking(booking) });
  }),
);
