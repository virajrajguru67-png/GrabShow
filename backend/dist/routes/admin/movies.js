import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { conflict, notFound } from '../../errors/app-error.js';
import { prisma } from '../../services/prisma.js';
import { asyncHandler } from '../../utils/async-handler.js';
import { mapMovie } from '../../modules/admin/admin.mappers.js';
import { movieCreateSchema, movieUpdateSchema } from '../../modules/admin/admin.schemas.js';
import { statusMapper } from '../../modules/admin/admin.mappers.js';
const movieInclude = {
    genres: true,
    languages: true,
};
export const moviesRouter = Router();
moviesRouter.get('/', asyncHandler(async (_req, res) => {
    const movies = await prisma.movie.findMany({
        include: movieInclude,
        orderBy: { title: 'asc' },
    });
    res.json({ data: movies.map(mapMovie) });
}));
moviesRouter.post('/', asyncHandler(async (req, res) => {
    const payload = movieCreateSchema.parse(req.body);
    const existing = await prisma.movie.findUnique({ where: { slug: payload.slug } });
    if (existing) {
        throw conflict('Slug already in use');
    }
    const movie = await prisma.movie.create({
        data: {
            title: payload.title,
            slug: payload.slug,
            synopsis: payload.synopsis,
            tagline: payload.tagline,
            posterUrl: payload.posterUrl,
            backdropUrl: payload.backdropUrl,
            durationMinutes: payload.durationMinutes,
            releaseYear: payload.releaseYear,
            rating: payload.rating != null ? new Prisma.Decimal(payload.rating) : undefined,
            status: statusMapper.movieStatusFromClient(payload.status ?? 'draft'),
            isTrending: payload.isTrending ?? false,
            isTopPick: payload.isTopPick ?? false,
            isUpcoming: payload.isUpcoming ?? false,
            metadata: payload.metadata,
            genres: {
                create: (payload.genres ?? []).map((name) => ({ name })),
            },
            languages: {
                create: (payload.languages ?? []).map((name) => ({ name })),
            },
        },
        include: movieInclude,
    });
    res.status(201).json({ data: mapMovie(movie) });
}));
moviesRouter.put('/:id', asyncHandler(async (req, res) => {
    const { id } = req.params;
    const payload = movieUpdateSchema.parse(req.body);
    const existing = await prisma.movie.findUnique({ where: { id } });
    if (!existing) {
        throw notFound('Movie not found');
    }
    if (payload.slug && payload.slug !== existing.slug) {
        const slugConflict = await prisma.movie.findUnique({ where: { slug: payload.slug } });
        if (slugConflict) {
            throw conflict('Slug already in use');
        }
    }
    const movie = await prisma.movie.update({
        where: { id },
        data: {
            title: payload.title ?? existing.title,
            slug: payload.slug ?? existing.slug,
            synopsis: payload.synopsis ?? existing.synopsis,
            tagline: payload.tagline ?? existing.tagline,
            posterUrl: payload.posterUrl ?? existing.posterUrl,
            backdropUrl: payload.backdropUrl ?? existing.backdropUrl,
            durationMinutes: payload.durationMinutes ?? existing.durationMinutes,
            releaseYear: payload.releaseYear ?? existing.releaseYear,
            rating: payload.rating != null
                ? new Prisma.Decimal(payload.rating)
                : existing.rating,
            status: payload.status
                ? statusMapper.movieStatusFromClient(payload.status)
                : existing.status,
            isTrending: payload.isTrending ?? existing.isTrending,
            isTopPick: payload.isTopPick ?? existing.isTopPick,
            isUpcoming: payload.isUpcoming ?? existing.isUpcoming,
            metadata: payload.metadata !== undefined ? payload.metadata : undefined,
            genres: payload.genres
                ? {
                    deleteMany: {},
                    create: payload.genres.map((name) => ({ name })),
                }
                : undefined,
            languages: payload.languages
                ? {
                    deleteMany: {},
                    create: payload.languages.map((name) => ({ name })),
                }
                : undefined,
        },
        include: movieInclude,
    });
    res.json({ data: mapMovie(movie) });
}));
moviesRouter.delete('/:id', asyncHandler(async (req, res) => {
    const { id } = req.params;
    await prisma.movie.delete({ where: { id } });
    res.status(204).send();
}));
//# sourceMappingURL=movies.js.map