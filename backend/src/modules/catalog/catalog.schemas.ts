import { z } from 'zod';

export const movieListQuerySchema = z.object({
  filter: z.enum(['trending', 'top-picks', 'upcoming', 'now-showing']).optional(),
  q: z.string().min(1).optional(),
  genre: z.string().min(1).optional(),
  language: z.string().min(1).optional(),
  limit: z.coerce.number().int().positive().max(50).optional(),
});

export const movieIdentifierSchema = z.object({
  identifier: z.string().min(1),
});

export const showtimeParamSchema = z.object({
  id: z.string().uuid(),
});

export const bookingSeatSchema = z.object({
  seatId: z.string().min(1),
  seatLabel: z.string().min(1),
  seatType: z.string().min(1).optional(),
});

export const createBookingSchema = z.object({
  showtimeId: z.string().uuid(),
  purchaser: z.object({
    email: z.string().email(),
    name: z.string().min(1),
  }),
  seats: z.array(bookingSeatSchema).min(1),
});

export const bookingReferenceSchema = z.object({
  reference: z.string().min(1),
});
