-- CreateTable
CREATE TABLE `Movie` (
    `id` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `status` ENUM('DRAFT', 'PUBLISHED') NOT NULL DEFAULT 'DRAFT',
    `durationMinutes` INTEGER NULL,
    `synopsis` TEXT NULL,
    `tagline` VARCHAR(191) NULL,
    `posterUrl` VARCHAR(191) NULL,
    `backdropUrl` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `Movie_slug_key`(`slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MovieGenre` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `movieId` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,

    INDEX `MovieGenre_movieId_idx`(`movieId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MovieLanguage` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `movieId` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,

    INDEX `MovieLanguage_movieId_idx`(`movieId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Auditorium` (
    `id` VARCHAR(191) NOT NULL,
    `cinemaId` VARCHAR(191) NOT NULL,
    `cinemaName` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `capacity` INTEGER NOT NULL,
    `layoutVersion` INTEGER NOT NULL DEFAULT 1,
    `layoutJson` JSON NOT NULL,
    `layoutUpdatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Showtime` (
    `id` VARCHAR(191) NOT NULL,
    `movieId` VARCHAR(191) NOT NULL,
    `auditoriumId` VARCHAR(191) NOT NULL,
    `startsAt` DATETIME(3) NOT NULL,
    `endsAt` DATETIME(3) NOT NULL,
    `basePrice` DECIMAL(10, 2) NOT NULL,
    `status` ENUM('SCHEDULED', 'ON_SALE', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'SCHEDULED',
    `seatLayoutVersion` INTEGER NOT NULL DEFAULT 1,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Showtime_movieId_idx`(`movieId`),
    INDEX `Showtime_auditoriumId_idx`(`auditoriumId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ShowtimePricingTier` (
    `id` VARCHAR(191) NOT NULL,
    `showtimeId` VARCHAR(191) NOT NULL,
    `label` VARCHAR(191) NOT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    `seatTypes` JSON NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `ShowtimePricingTier_showtimeId_idx`(`showtimeId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Booking` (
    `id` VARCHAR(191) NOT NULL,
    `reference` VARCHAR(191) NOT NULL,
    `showtimeId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NULL,
    `purchaserEmail` VARCHAR(191) NOT NULL,
    `purchaserName` VARCHAR(191) NOT NULL,
    `status` ENUM('RESERVED', 'CONFIRMED', 'CANCELLED', 'REFUNDED') NOT NULL DEFAULT 'CONFIRMED',
    `totalAmount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(191) NOT NULL DEFAULT 'INR',
    `purchasedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `movieTitle` VARCHAR(191) NOT NULL,

    UNIQUE INDEX `Booking_reference_key`(`reference`),
    INDEX `Booking_showtimeId_idx`(`showtimeId`),
    INDEX `Booking_userId_idx`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `BookingTicket` (
    `id` VARCHAR(191) NOT NULL,
    `bookingId` VARCHAR(191) NOT NULL,
    `seatId` VARCHAR(191) NOT NULL,
    `seatLabel` VARCHAR(191) NOT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    `tierLabel` VARCHAR(191) NULL,
    `tierId` VARCHAR(191) NULL,

    INDEX `BookingTicket_bookingId_idx`(`bookingId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `BookingAudit` (
    `id` VARCHAR(191) NOT NULL,
    `bookingId` VARCHAR(191) NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `message` VARCHAR(191) NOT NULL,
    `actor` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `BookingAudit_bookingId_idx`(`bookingId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SettlementTransaction` (
    `id` VARCHAR(191) NOT NULL,
    `gateway` VARCHAR(191) NOT NULL,
    `transactionId` VARCHAR(191) NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(191) NOT NULL DEFAULT 'INR',
    `status` ENUM('PENDING', 'PROCESSING', 'COMPLETED') NOT NULL DEFAULT 'PENDING',
    `fees` DECIMAL(10, 2) NOT NULL,
    `netPayout` DECIMAL(10, 2) NOT NULL,
    `settledAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `bookingId` VARCHAR(191) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `NotificationSegment` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `NotificationCampaign` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `subject` VARCHAR(191) NOT NULL,
    `channels` JSON NOT NULL,
    `status` ENUM('DRAFT', 'SCHEDULED', 'IN_FLIGHT', 'COMPLETED') NOT NULL DEFAULT 'DRAFT',
    `scheduledAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `segmentId` VARCHAR(191) NOT NULL,
    `statsSent` INTEGER NOT NULL DEFAULT 0,
    `statsOpened` INTEGER NOT NULL DEFAULT 0,
    `statsClicked` INTEGER NOT NULL DEFAULT 0,

    INDEX `NotificationCampaign_segmentId_idx`(`segmentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PlatformSettings` (
    `id` INTEGER NOT NULL DEFAULT 1,
    `razorpayKey` VARCHAR(191) NOT NULL DEFAULT '',
    `stripeKey` VARCHAR(191) NOT NULL DEFAULT '',
    `settlementDays` INTEGER NOT NULL DEFAULT 2,
    `cgst` DECIMAL(5, 2) NOT NULL DEFAULT 0,
    `sgst` DECIMAL(5, 2) NOT NULL DEFAULT 0,
    `convenienceFee` DECIMAL(5, 2) NOT NULL DEFAULT 0,
    `theatreName` VARCHAR(191) NOT NULL DEFAULT '',
    `supportEmail` VARCHAR(191) NOT NULL DEFAULT '',
    `contactNumber` VARCHAR(191) NOT NULL DEFAULT '',
    `address` TEXT NOT NULL DEFAULT '',
    `termsUrl` VARCHAR(191) NOT NULL DEFAULT '',
    `privacyUrl` VARCHAR(191) NOT NULL DEFAULT '',
    `refundWindowHours` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PaymentAudit` (
    `id` VARCHAR(191) NOT NULL,
    `transactionId` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `method` VARCHAR(191) NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `movieTitle` VARCHAR(191) NOT NULL,
    `showtime` VARCHAR(191) NULL,
    `seats` JSON NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PaymentAudit_transactionId_key`(`transactionId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `MovieGenre` ADD CONSTRAINT `MovieGenre_movieId_fkey` FOREIGN KEY (`movieId`) REFERENCES `Movie`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MovieLanguage` ADD CONSTRAINT `MovieLanguage_movieId_fkey` FOREIGN KEY (`movieId`) REFERENCES `Movie`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Showtime` ADD CONSTRAINT `Showtime_movieId_fkey` FOREIGN KEY (`movieId`) REFERENCES `Movie`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Showtime` ADD CONSTRAINT `Showtime_auditoriumId_fkey` FOREIGN KEY (`auditoriumId`) REFERENCES `Auditorium`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ShowtimePricingTier` ADD CONSTRAINT `ShowtimePricingTier_showtimeId_fkey` FOREIGN KEY (`showtimeId`) REFERENCES `Showtime`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Booking` ADD CONSTRAINT `Booking_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Booking` ADD CONSTRAINT `Booking_showtimeId_fkey` FOREIGN KEY (`showtimeId`) REFERENCES `Showtime`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BookingTicket` ADD CONSTRAINT `BookingTicket_bookingId_fkey` FOREIGN KEY (`bookingId`) REFERENCES `Booking`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BookingAudit` ADD CONSTRAINT `BookingAudit_bookingId_fkey` FOREIGN KEY (`bookingId`) REFERENCES `Booking`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SettlementTransaction` ADD CONSTRAINT `SettlementTransaction_bookingId_fkey` FOREIGN KEY (`bookingId`) REFERENCES `Booking`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `NotificationCampaign` ADD CONSTRAINT `NotificationCampaign_segmentId_fkey` FOREIGN KEY (`segmentId`) REFERENCES `NotificationSegment`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
