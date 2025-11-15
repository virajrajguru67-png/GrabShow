const decimalToNumber = (value) => {
    if (value == null)
        return null;
    if (typeof value === 'number')
        return value;
    return value.toNumber();
};
const toLower = (value) => value.toLowerCase();
const showtimeStatusToClient = (status) => {
    switch (status) {
        case 'ON_SALE':
            return 'on-sale';
        case 'COMPLETED':
            return 'completed';
        case 'CANCELLED':
            return 'cancelled';
        default:
            return 'scheduled';
    }
};
const parseMetadata = (metadata) => {
    if (!metadata || typeof metadata !== 'object')
        return {};
    return metadata;
};
const unique = (values) => Array.from(new Set(values));
export const toMovieSummary = (movie) => {
    const upcomingShowtimes = movie.showtimes
        .filter((showtime) => showtime.startsAt > new Date())
        .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
    return {
        id: movie.id,
        title: movie.title,
        slug: movie.slug,
        tagline: movie.tagline,
        synopsis: movie.synopsis,
        posterUrl: movie.posterUrl,
        backdropUrl: movie.backdropUrl,
        releaseYear: movie.releaseYear,
        rating: decimalToNumber(movie.rating),
        durationMinutes: movie.durationMinutes,
        genres: movie.genres.map((item) => item.name),
        languages: movie.languages.map((item) => item.name),
        status: movie.status.toLowerCase(),
        isTrending: movie.isTrending,
        isTopPick: movie.isTopPick,
        isUpcoming: movie.isUpcoming,
        nextShowtime: upcomingShowtimes[0]?.startsAt.toISOString() ?? null,
    };
};
const mapPricingTier = (tier) => ({
    id: tier.id,
    label: tier.label,
    price: decimalToNumber(tier.price),
    seatTypes: Array.isArray(tier.seatTypes) ? tier.seatTypes : [],
});
const mapShowtimeInfo = (showtime) => ({
    id: showtime.id,
    movieId: showtime.movieId,
    auditoriumId: showtime.auditoriumId,
    auditoriumName: showtime.auditorium.name,
    cinemaId: showtime.auditorium.cinemaId,
    cinemaName: showtime.auditorium.cinemaName,
    startsAt: showtime.startsAt.toISOString(),
    endsAt: showtime.endsAt.toISOString(),
    basePrice: decimalToNumber(showtime.basePrice),
    status: showtimeStatusToClient(showtime.status),
    seatLayoutVersion: showtime.seatLayoutVersion,
    pricingTiers: showtime.pricingTiers.map(mapPricingTier),
});
export const toMovieDetail = (movie) => {
    const metadata = parseMetadata(movie.metadata);
    const cast = Array.isArray(metadata.cast) ? unique(metadata.cast) : [];
    const showtimes = movie.showtimes
        .slice()
        .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
    const seatTypePrices = new Map();
    const earliestOnSale = showtimes.find((showtime) => showtime.status === 'ON_SALE' || showtime.status === 'SCHEDULED');
    if (earliestOnSale) {
        const basePrice = decimalToNumber(earliestOnSale.basePrice) ?? 0;
        earliestOnSale.pricingTiers.forEach((tier) => {
            const price = decimalToNumber(tier.price) ?? basePrice;
            const types = Array.isArray(tier.seatTypes) ? tier.seatTypes : [];
            types.forEach((type) => {
                const key = toLower(type);
                if (!seatTypePrices.has(key)) {
                    seatTypePrices.set(key, price);
                }
            });
        });
        if (!seatTypePrices.size) {
            seatTypePrices.set('standard', basePrice);
        }
    }
    const metadataTicketPricesRaw = metadata.ticketPrices;
    const metadataTicketPrices = metadataTicketPricesRaw && typeof metadataTicketPricesRaw === 'object'
        ? metadataTicketPricesRaw
        : {};
    const ticketPrices = Object.fromEntries(unique([
        ...Object.keys(metadataTicketPrices),
        ...Array.from(seatTypePrices.keys()),
    ]).map((key) => [key, metadataTicketPrices[key] ?? seatTypePrices.get(key) ?? 0]));
    return {
        id: movie.id,
        title: movie.title,
        slug: movie.slug,
        synopsis: movie.synopsis,
        tagline: movie.tagline,
        posterUrl: movie.posterUrl,
        backdropUrl: movie.backdropUrl,
        releaseYear: movie.releaseYear,
        rating: decimalToNumber(movie.rating),
        durationMinutes: movie.durationMinutes,
        genres: movie.genres.map((item) => item.name),
        languages: movie.languages.map((item) => item.name),
        status: movie.status.toLowerCase(),
        isTrending: movie.isTrending,
        isTopPick: movie.isTopPick,
        isUpcoming: movie.isUpcoming,
        cast,
        showtimes: showtimes.map(mapShowtimeInfo),
        ticketPrices,
        metadata,
    };
};
export const buildSeatTypeMap = (layout) => {
    const map = new Map();
    for (const row of layout.rows ?? []) {
        for (const seat of row.seats ?? []) {
            map.set(seat.seatId, seat.type);
        }
    }
    return map;
};
export const buildSeatMapWithAvailability = (layout, reservedSeatIds) => ({
    version: layout.version,
    rows: (layout.rows ?? []).map((row) => ({
        rowLabel: row.rowLabel,
        seats: (row.seats ?? []).map((seat) => ({
            seatId: seat.seatId,
            label: seat.label,
            type: seat.type,
            isAisle: Boolean(seat.isAisle),
            isAvailable: !reservedSeatIds.has(seat.seatId) && !seat.blocked,
        })),
    })),
});
//# sourceMappingURL=catalog.mappers.js.map