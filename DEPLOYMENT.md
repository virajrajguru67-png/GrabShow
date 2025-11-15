# Vercel Deployment Guide

This guide explains how to deploy your Flutter web app and Node.js backend to Vercel.

## Prerequisites

1. **Vercel CLI installed**: `npm install -g vercel`
2. **Flutter SDK** installed locally (for building the web app)
3. **Node.js** installed (for backend)
4. **Git repository** (Vercel works best with Git integration)

## Quick Start

### Option 1: Deploy Everything to Vercel (Recommended for Testing)

#### Step 1: Build Flutter Web App Locally

```bash
cd flutter_demo
flutter build web --release --dart-define=API_BASE_URL=/api
```

**Note**: We use `/api` as a relative path since both frontend and backend will be on the same domain.

#### Step 2: Build Backend

```bash
cd backend
npm install
npm run build
npm run prisma:generate
```

#### Step 3: Install API Dependencies

```bash
cd api
npm install
```

#### Step 4: Set Environment Variables in Vercel

Go to Vercel Dashboard → Your Project → Settings → Environment Variables, and add:

```env
DATABASE_URL=your_database_url
JWT_SECRET=your-secret-key-min-16-chars
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_TTL_DAYS=30
FRONTEND_URL=https://your-app.vercel.app
NODE_ENV=production
```

#### Step 5: Deploy

```bash
# From root directory
vercel

# For production
vercel --prod
```

### Option 2: Separate Deployments (Recommended for Production)

Deploy Flutter web to Vercel, and backend to a dedicated service like Railway or Render.

## Project Structure

```
.
├── api/
│   └── index.js          # Vercel serverless function wrapper
├── backend/              # Node.js/Express backend
│   ├── src/
│   └── dist/            # Built backend (generated)
├── flutter_demo/
│   ├── build/
│   │   └── web/         # Built Flutter web app (generated)
│   └── lib/
├── vercel.json          # Vercel configuration
└── .vercelignore        # Files to ignore in deployment
```

## Important Notes

1. **Database**: You'll need a cloud database. Options:
   - [PlanetScale](https://planetscale.com) (MySQL)
   - [Supabase](https://supabase.com) (PostgreSQL)
   - [Railway](https://railway.app) (MySQL/PostgreSQL)

2. **Prisma Migrations**: Run migrations before deployment:
   ```bash
   cd backend
   npx prisma migrate deploy
   ```

3. **Build Order**: Always build Flutter web app locally before deploying, as Vercel doesn't have Flutter SDK.

4. **API Routes**: All backend routes are accessible at `/api/*` (e.g., `/api/auth/login`)

## Troubleshooting

### Flutter build not found
- Make sure you've built the Flutter web app: `flutter build web --release`
- Check that `flutter_demo/build/web` directory exists

### Backend not working
- Ensure backend is built: `cd backend && npm run build`
- Check environment variables are set in Vercel dashboard
- Verify database connection string is correct

### CORS errors
- Backend CORS is configured to allow all origins in development
- For production, update CORS settings in `backend/src/app.ts`

## Alternative: Separate Deployments

If you prefer, you can:
1. Deploy Flutter web to Vercel (static hosting)
2. Deploy backend separately to:
   - [Railway](https://railway.app)
   - [Render](https://render.com)
   - [Fly.io](https://fly.io)
   - Or keep on Vercel as serverless functions

Then update `API_BASE_URL` in Flutter to point to your backend URL.

