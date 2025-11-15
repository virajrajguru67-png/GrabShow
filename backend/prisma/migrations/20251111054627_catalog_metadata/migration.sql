-- AlterTable
ALTER TABLE `movie` ADD COLUMN `isTopPick` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `isTrending` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `isUpcoming` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `metadata` JSON NULL,
    ADD COLUMN `rating` DECIMAL(4, 2) NULL,
    ADD COLUMN `releaseYear` INTEGER NULL;
