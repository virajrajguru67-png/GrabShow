import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;

export const hashPassword = async (plainText: string) => bcrypt.hash(plainText, SALT_ROUNDS);

export const verifyPassword = async (plainText: string, hash: string) => bcrypt.compare(plainText, hash);
