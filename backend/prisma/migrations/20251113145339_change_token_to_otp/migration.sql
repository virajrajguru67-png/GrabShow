-- Delete existing password reset tokens
DELETE FROM PasswordResetToken;

-- AlterTable
ALTER TABLE `PasswordResetToken` DROP COLUMN `token`,
ADD COLUMN `otp` VARCHAR(6) NOT NULL;
