/// <reference types="node" />
import { Prisma, PrismaClient } from '@prisma/client';
import type { $Enums } from '@prisma/client';

import { hashPassword } from '../src/utils/password.js';

const prisma = new PrismaClient();
const ADMIN_STATUS_ACTIVE = 'ACTIVE' satisfies $Enums.AdminStatus;
const ADMIN_ROLES = ['OWNER', 'OPERATIONS'] as const satisfies ReadonlyArray<$Enums.AdminRole>;

const ADMIN_EMAIL = 'admin@developer.com';
const ADMIN_PASSWORD = process.env.ADMIN_SEED_PASSWORD ?? 'Admin@123';
const ADMIN_DISPLAY_NAME = 'StreamFlix Admin';

async function main() {
  const existing = await prisma.user.findUnique({
    where: { email: ADMIN_EMAIL },
    include: { adminProfile: { include: { roles: true } } },
  });

  if (existing) {
    if (!existing.isAdmin) {
      await prisma.user.update({
        where: { id: existing.id },
        data: { isAdmin: true },
      });
    }

    if (!existing.adminProfile) {
      await prisma.adminUser.create({
        data: {
          userId: existing.id,
          status: ADMIN_STATUS_ACTIVE,
          roles: {
            create: ADMIN_ROLES.map((role) => ({ role })),
          },
        },
      });
    }

    console.info('Admin user already exists:', ADMIN_EMAIL);
  } else {
    const passwordHash = await hashPassword(ADMIN_PASSWORD);
    const user = await prisma.user.create({
      data: {
        email: ADMIN_EMAIL,
        passwordHash,
        displayName: ADMIN_DISPLAY_NAME,
        isAdmin: true,
        adminProfile: {
          create: {
            status: ADMIN_STATUS_ACTIVE,
            roles: {
              create: ADMIN_ROLES.map((role) => ({ role })),
            },
          },
        },
      },
    });

    console.info('Seeded admin account:', { email: user.email, password: ADMIN_PASSWORD });
  }

  await seedCatalog();
  await seedPlatformSettings();
  await seedNotifications();
}

const seatLayout = {
  version: 1,
  rows: [
    {
      rowLabel: 'A',
      seats: [
        { seatId: 'A1', label: 'A1', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'A2', label: 'A2', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'A3', label: 'A3', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'A4', label: 'A4', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'A5', label: 'A5', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'A6', label: 'A6', type: 'standard', isAisle: false, blocked: false },
      ],
    },
    {
      rowLabel: 'B',
      seats: [
        { seatId: 'B1', label: 'B1', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'B2', label: 'B2', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'B3', label: 'B3', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'B4', label: 'B4', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'B5', label: 'B5', type: 'standard', isAisle: false, blocked: false },
        { seatId: 'B6', label: 'B6', type: 'standard', isAisle: false, blocked: false },
      ],
    },
    {
      rowLabel: 'C',
      seats: [
        { seatId: 'C1', label: 'C1', type: 'premium', isAisle: false, blocked: false },
        { seatId: 'C2', label: 'C2', type: 'premium', isAisle: false, blocked: false },
        { seatId: 'C3', label: 'C3', type: 'premium', isAisle: false, blocked: false },
        { seatId: 'C4', label: 'C4', type: 'premium', isAisle: false, blocked: false },
        { seatId: 'C5', label: 'C5', type: 'premium', isAisle: false, blocked: true },
        { seatId: 'C6', label: 'C6', type: 'premium', isAisle: false, blocked: true },
      ],
    },
    {
      rowLabel: 'D',
      seats: [
        { seatId: 'D1', label: 'D1', type: 'couple', isAisle: false, blocked: false },
        { seatId: 'D2', label: 'D2', type: 'couple', isAisle: false, blocked: false },
        { seatId: 'D3', label: 'D3', type: 'couple', isAisle: false, blocked: false },
        { seatId: 'D4', label: 'D4', type: 'couple', isAisle: false, blocked: false },
      ],
    },
  ],
};

async function seedCatalog() {
  console.info('Seeding catalog data...');

  await prisma.bookingAudit.deleteMany();
  await prisma.bookingTicket.deleteMany();
  await prisma.settlementTransaction.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.showtimePricingTier.deleteMany();
  await prisma.showtime.deleteMany();
  await prisma.auditorium.deleteMany();
  await prisma.movieGenre.deleteMany();
  await prisma.movieLanguage.deleteMany();
  await prisma.movie.deleteMany();

  const movie = await prisma.movie.create({
    data: {
      title: 'Shadow Reckoning',
      slug: 'shadow-reckoning',
      status: 'PUBLISHED',
      durationMinutes: 129,
      synopsis:
        'A retired detective returns to the underworld when a copycat killer starts recreating the city’s most infamous crimes.',
      tagline: 'Justice lives in the dark.',
      posterUrl: 'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4',
      backdropUrl: 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d',
      releaseYear: 2025,
      rating: new Prisma.Decimal(8.7),
      isTrending: true,
      isTopPick: true,
      metadata: {
        cast: ['Idris Vaughn', 'Ana Rivera', 'Miles Chen'],
        ticketPrices: {
          standard: 200,
          premium: 320,
          couple: 500,
        },
      },
      genres: {
        create: ['Action', 'Thriller'].map((name) => ({ name })),
      },
      languages: {
        create: ['English', 'Hindi'].map((name) => ({ name })),
      },
    },
  });

  const auditorium = await prisma.auditorium.create({
    data: {
      id: 'auditorium-main',
      cinemaId: 'cinema-001',
      cinemaName: 'StreamFlix Downtown',
      name: 'Prime Screen',
      capacity: 120,
      layoutVersion: 1,
      layoutJson: seatLayout,
    },
  });

  const now = new Date();
  const startsAt = new Date(now.getTime() + 4 * 60 * 60 * 1000);
  const endsAt = new Date(now.getTime() + 6 * 60 * 60 * 1000);

  const showtime = await prisma.showtime.create({
    data: {
      movieId: movie.id,
      auditoriumId: auditorium.id,
      startsAt,
      endsAt,
      basePrice: new Prisma.Decimal(200),
      status: 'ON_SALE',
      seatLayoutVersion: 1,
      pricingTiers: {
        create: [
          { label: 'STANDARD', price: new Prisma.Decimal(200), seatTypes: ['standard'] },
          { label: 'PREMIUM', price: new Prisma.Decimal(320), seatTypes: ['premium'] },
          { label: 'COUPLE', price: new Prisma.Decimal(500), seatTypes: ['couple'] },
        ],
      },
    },
  });

  await prisma.booking.create({
    data: {
      reference: 'SFBK-DEMO',
      showtimeId: showtime.id,
      purchaserEmail: 'demo@streamflix.com',
      purchaserName: 'Demo Customer',
      status: 'CONFIRMED',
      totalAmount: new Prisma.Decimal(540),
      currency: 'INR',
      movieTitle: movie.title,
      tickets: {
        create: [
          { seatId: 'A1', seatLabel: 'A1', price: new Prisma.Decimal(200), tierLabel: 'STANDARD' },
          { seatId: 'A2', seatLabel: 'A2', price: new Prisma.Decimal(200), tierLabel: 'STANDARD' },
          { seatId: 'B1', seatLabel: 'B1', price: new Prisma.Decimal(140), tierLabel: 'STANDARD' },
        ],
      },
      auditLog: {
        create: {
          type: 'booking-created',
          message: 'Booking confirmed via seed',
          actor: 'system',
        },
      },
      settlements: {
        create: {
          gateway: 'upi',
          transactionId: 'TXN-DEMO-001',
          amount: new Prisma.Decimal(540),
          fees: new Prisma.Decimal(27),
          netPayout: new Prisma.Decimal(513),
          status: 'PENDING',
        },
      },
    },
  });
}

async function seedPlatformSettings() {
  await prisma.platformSettings.upsert({
    where: { id: 1 },
    update: {
      razorpayKey: 'rzp_test_demo',
      stripeKey: 'pk_test_demo',
      settlementDays: 2,
      cgst: new Prisma.Decimal(9),
      sgst: new Prisma.Decimal(9),
      convenienceFee: new Prisma.Decimal(5),
      theatreName: 'StreamFlix Cinemas',
      supportEmail: 'support@streamflix.com',
      contactNumber: '+91-90000-00000',
      address: '221B Baker Street, London',
      termsUrl: 'https://streamflix.example.com/terms',
      privacyUrl: 'https://streamflix.example.com/privacy',
      refundWindowHours: 24,
    },
    create: {
      razorpayKey: 'rzp_test_demo',
      stripeKey: 'pk_test_demo',
      settlementDays: 2,
      cgst: new Prisma.Decimal(9),
      sgst: new Prisma.Decimal(9),
      convenienceFee: new Prisma.Decimal(5),
      theatreName: 'StreamFlix Cinemas',
      supportEmail: 'support@streamflix.com',
      contactNumber: '+91-90000-00000',
      address: '221B Baker Street, London',
      termsUrl: 'https://streamflix.example.com/terms',
      privacyUrl: 'https://streamflix.example.com/privacy',
      refundWindowHours: 24,
    },
  });
}

async function seedNotifications() {
  await prisma.notificationCampaign.deleteMany();
  await prisma.notificationSegment.deleteMany();

  const segment = await prisma.notificationSegment.create({
    data: {
      name: 'Active watchers',
      description: 'Users who booked in the last 30 days',
    },
  });

  await prisma.notificationCampaign.create({
    data: {
      name: 'Weekend Offers',
      subject: 'Grab 2-for-1 tickets this weekend!',
      status: 'SCHEDULED',
      scheduledAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      segmentId: segment.id,
      channels: ['email', 'push'],
      statsSent: 1200,
      statsOpened: 530,
      statsClicked: 210,
    },
  });
}

main()
  .catch((error) => {
    console.error('Failed to seed database', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
