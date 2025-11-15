// Vercel serverless function wrapper for Express backend
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApp } from '../backend/dist/app.js';

// Create Express app once (cached for subsequent invocations)
let app: any = null;

function getApp() {
  if (!app) {
    app = createApp();
  }
  return app;
}

// Export as Vercel serverless function
export default async function handler(req: VercelRequest, res: VercelResponse) {
  const expressApp = getApp();
  
  // Convert Vercel request/response to Express format
  return new Promise<void>((resolve, reject) => {
    // Create Express-compatible request/response objects
    const expressReq = req as any;
    const expressRes = res as any;
    
    // Handle the request
    expressApp(expressReq, expressRes, (err?: any) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    });
  });
}
