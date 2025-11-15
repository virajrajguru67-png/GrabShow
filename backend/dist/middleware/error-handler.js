import { ZodError } from 'zod';
import { AppError } from '../errors/app-error.js';
export const notFoundHandler = (_req, res) => {
    res.status(404).json({ message: 'Not Found' });
};
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const errorHandler = (error, _req, res, _next) => {
    if (error instanceof ZodError) {
        res.status(400).json({
            message: 'Validation failed',
            errors: error.flatten(),
        });
        return;
    }
    if (error instanceof AppError) {
        const payload = { message: error.message };
        if (error.details)
            payload.details = error.details;
        res.status(error.statusCode).json(payload);
        return;
    }
    console.error('Unhandled error', error);
    res.status(500).json({ message: 'Internal Server Error' });
};
//# sourceMappingURL=error-handler.js.map