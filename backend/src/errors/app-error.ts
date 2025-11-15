export class AppError extends Error {
  public readonly statusCode: number;
  public readonly expose: boolean;
  public readonly details?: Record<string, unknown>;

  constructor(message: string, statusCode = 500, options?: { expose?: boolean; details?: Record<string, unknown> }) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.expose = options?.expose ?? statusCode < 500;
    this.details = options?.details;
  }
}

export const createError = (statusCode: number, message: string, details?: Record<string, unknown>) =>
  new AppError(message, statusCode, { expose: true, details });

export const badRequest = (message: string, details?: Record<string, unknown>) =>
  createError(400, message, details);

export const unauthorized = (message: string) => createError(401, message);

export const conflict = (message: string) => createError(409, message);

export const internal = (message: string, details?: Record<string, unknown>) =>
  new AppError(message, 500, { expose: false, details });

export const notFound = (message: string) => createError(404, message);
