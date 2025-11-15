import { z } from 'zod';

export const statusString = z.enum(['draft', 'published']);

export const movieCreateSchema = z.object({
  title: z.string().min(1),
  slug: z.string().min(1),
  synopsis: z.string().optional(),
  tagline: z.string().optional(),
  posterUrl: z.string().url().optional(),
  backdropUrl: z.string().url().optional(),
  durationMinutes: z.number().int().positive().optional(),
  releaseYear: z.number().int().min(1900).max(2100).optional(),
  rating: z.number().min(0).max(10).optional(),
  genres: z.array(z.string().min(1)).optional(),
  languages: z.array(z.string().min(1)).optional(),
  status: statusString.optional(),
  isTrending: z.boolean().optional(),
  isTopPick: z.boolean().optional(),
  isUpcoming: z.boolean().optional(),
  metadata: z.record(z.any()).optional(),
});

export const movieUpdateSchema = movieCreateSchema.partial().extend({
  slug: z.string().min(1).optional(),
});

export const seatDefinitionSchema = z.object({
  seatId: z.string().min(1),
  label: z.string().min(1),
  type: z.string().min(1),
  isAisle: z.boolean().optional().default(false),
  blocked: z.boolean().optional().default(false),
});

export const seatRowSchema = z.object({
  rowLabel: z.string().min(1),
  seats: z.array(seatDefinitionSchema),
});

export const seatLayoutSchema = z.object({
  version: z.number().int().positive(),
  rows: z.array(seatRowSchema),
});

export const auditoriumCreateSchema = z.object({
  cinemaId: z.string().min(1),
  cinemaName: z.string().min(1),
  name: z.string().min(1),
  capacity: z.number().int().positive(),
  layout: seatLayoutSchema.optional(),
});

export const auditoriumUpdateSchema = z.object({
  cinemaId: z.string().min(1).optional(),
  cinemaName: z.string().min(1).optional(),
  name: z.string().min(1).optional(),
  capacity: z.number().int().positive().optional(),
});

export const pricingTierSchema = z.object({
  id: z.string().optional(),
  label: z.string().min(1),
  price: z.number().positive(),
  seatTypes: z.array(z.string().min(1)).min(1),
});

export const showtimeStatusSchema = z.enum(['scheduled', 'on-sale', 'completed', 'cancelled']);

export const showtimePayloadSchema = z.object({
  movieId: z.string().uuid(),
  auditoriumId: z.string().uuid(),
  startsAt: z.string().refine((value) => !Number.isNaN(Date.parse(value)), {
    message: 'startsAt must be an ISO date string',
  }),
  endsAt: z.string().refine((value) => !Number.isNaN(Date.parse(value)), {
    message: 'endsAt must be an ISO date string',
  }),
  basePrice: z.number().positive(),
  status: showtimeStatusSchema.default('scheduled'),
  seatLayoutVersion: z.number().int().positive().optional(),
  pricingTiers: z.array(pricingTierSchema).default([]),
});

export const showtimeUpdateSchema = showtimePayloadSchema.partial({
  movieId: true,
  auditoriumId: true,
  seatLayoutVersion: true,
});

export const auditoriumLayoutUpdateSchema = seatLayoutSchema.extend({
  updatedAt: z.string().optional(),
});

export const adminRoleSchema = z.enum(['owner', 'finance', 'content', 'operations', 'support', 'marketing']);

export const inviteAdminSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  roles: z.array(adminRoleSchema).min(1),
});

export const updateAdminSchema = z.object({
  name: z.string().min(1).optional(),
  status: z.enum(['invited', 'active', 'disabled']).optional(),
  roles: z.array(adminRoleSchema).min(1).optional(),
});

export const campaignStatusSchema = z.enum(['draft', 'scheduled', 'in-flight', 'completed']);

export const campaignPayloadSchema = z.object({
  name: z.string().min(1),
  subject: z.string().min(1),
  channel: z.array(z.enum(['email', 'sms', 'push'])).min(1),
  segmentId: z.string().uuid(),
  scheduledAt: z
    .string()
    .refine((value) => !Number.isNaN(Date.parse(value)), {
      message: 'scheduledAt must be an ISO date string',
    })
    .optional(),
});

export const platformSettingsPayloadSchema = z.object({
  payment: z
    .object({
      razorpayKey: z.string().optional(),
      stripeKey: z.string().optional(),
      settlementDays: z.number().int().nonnegative().optional(),
    })
    .default({}),
  taxes: z
    .object({
      cgst: z.number().nonnegative().optional(),
      sgst: z.number().nonnegative().optional(),
      convenienceFee: z.number().nonnegative().optional(),
    })
    .default({}),
  theatre: z
    .object({
      name: z.string().optional(),
      supportEmail: z.string().optional(),
      contactNumber: z.string().optional(),
      address: z.string().optional(),
    })
    .default({}),
  policies: z
    .object({
      termsUrl: z.string().optional(),
      privacyUrl: z.string().optional(),
      refundWindowHours: z.number().int().nonnegative().optional(),
    })
    .default({}),
});
