export class AppError extends Error {
    constructor(message, statusCode = 500, options) {
        super(message);
        this.name = 'AppError';
        this.statusCode = statusCode;
        this.expose = options?.expose ?? statusCode < 500;
        this.details = options?.details;
    }
}
export const createError = (statusCode, message, details) => new AppError(message, statusCode, { expose: true, details });
export const badRequest = (message, details) => createError(400, message, details);
export const unauthorized = (message) => createError(401, message);
export const conflict = (message) => createError(409, message);
export const internal = (message, details) => new AppError(message, 500, { expose: false, details });
export const notFound = (message) => createError(404, message);
//# sourceMappingURL=app-error.js.map