import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { adminRouter } from './routes/admin.js';
import { authRouter } from './routes/auth.js';
import { catalogRouter } from './routes/catalog.js';
import { router as healthRouter } from './routes/health.js';
import { paymentsRouter } from './routes/payments.js';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';

export const createApp = () => {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use((req, _res, next) => {
    const override = req.get('x-http-method-override');
    if (override) {
      req.method = override.toUpperCase();
    }
    next();
  });
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan('dev'));

  app.get('/', (_req, res) => {
    res.json({ name: 'StreamFlix API', version: '0.1.0', status: 'ok' });
  });

  app.use('/healthz', healthRouter);
  app.use('/auth', authRouter);
  app.use('/admin', adminRouter);
  app.use('/catalog', catalogRouter);
  app.use('/payments', paymentsRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
