import bcrypt from 'bcryptjs';
const SALT_ROUNDS = 12;
export const hashPassword = async (plainText) => bcrypt.hash(plainText, SALT_ROUNDS);
export const verifyPassword = async (plainText, hash) => bcrypt.compare(plainText, hash);
//# sourceMappingURL=password.js.map