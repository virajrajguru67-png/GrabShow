import { z } from 'zod';

export const paymentAuditSchema = z.object({
  transactionId: z.string().min(1),
  status: z.string().min(1),
  method: z.string().min(1),
  amount: z.number().nonnegative(),
  movieTitle: z.string().min(1),
  showtime: z.string().optional(),
  seats: z.array(z.string().min(1)).optional(),
});
