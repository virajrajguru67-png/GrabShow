import 'package:flutter/material.dart';

enum SeatType {
  standard,
  premium,
  couple,
}

class SeatInfo {
  const SeatInfo({
    required this.type,
    required this.isAvailable,
  });

  final SeatType type;
  final bool isAvailable;
}

class SeatRow {
  const SeatRow({
    required this.label,
    required this.seats,
  });

  final String label;
  final List<SeatInfo> seats;
}

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.tagline,
    required this.synopsis,
    required this.genres,
    required this.rating,
    required this.durationMinutes,
    required this.releaseYear,
    required this.posterUrl,
    required this.backdropUrl,
    this.trailerUrl,
    required this.cast,
    required this.showtimes,
    required this.seatMap,
    required this.ticketPrices,
    this.isTrending = false,
    this.isTopPick = false,
    this.isUpcoming = false,
  });

  final String id;
  final String title;
  final String tagline;
  final String synopsis;
  final List<String> genres;
  final double rating;
  final int durationMinutes;
  final int releaseYear;
  final String posterUrl;
  final String backdropUrl;
  final String? trailerUrl;
  final List<String> cast;
  final List<String> showtimes;
  final List<SeatRow> seatMap;
  final Map<SeatType, double> ticketPrices;
  final bool isTrending;
  final bool isTopPick;
  final bool isUpcoming;

  String get durationLabel {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

const mockMovies = [
  Movie(
    id: '1',
    title: 'Shadow Reckoning',
    tagline: 'Justice lives in the dark.',
    synopsis:
        'A retired detective is pulled back into the underworld when a copycat killer starts recreating the city’s most infamous crimes. As the clues lead closer to home, the line between hero and villain fades.',
    genres: ['Action', 'Thriller'],
    rating: 8.7,
    durationMinutes: 129,
    releaseYear: 2025,
    posterUrl: 'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4',
    backdropUrl: 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d',
    trailerUrl: 'dQw4w9WgXcQ', // Example YouTube video ID
    cast: ['Idris Vaughn', 'Ana Rivera', 'Miles Chen'],
    showtimes: ['12:30', '15:45', '18:00', '21:15'],
    isTrending: true,
    isTopPick: true,
    seatMap: [
      SeatRow(
        label: 'A',
        seats: [
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
        ],
      ),
      SeatRow(
        label: 'B',
        seats: [
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
        ],
      ),
      SeatRow(
        label: 'C',
        seats: [
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: false),
          SeatInfo(type: SeatType.premium, isAvailable: false),
        ],
      ),
      SeatRow(
        label: 'D',
        seats: [
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
        ],
      ),
    ],
    ticketPrices: {
      SeatType.standard: 12.0,
      SeatType.premium: 18.0,
      SeatType.couple: 28.0,
    },
  ),
  Movie(
    id: '2',
    title: 'Neon Horizons',
    tagline: 'Hope shines beyond the skyline.',
    synopsis:
        'In a neon-drenched mega-city, a rogue engineer teams up with an AI companion to expose a corporate conspiracy that threatens to end free will forever.',
    genres: ['Sci-Fi', 'Adventure'],
    rating: 8.3,
    durationMinutes: 142,
    releaseYear: 2025,
    posterUrl: 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c',
    backdropUrl: 'https://images.unsplash.com/photo-1525182008055-f88b95ff7980',
    cast: ['Lia Monroe', 'Dakari Holt', 'Ren Tsukino'],
    showtimes: ['11:00', '14:15', '17:30', '20:45'],
    isTrending: true,
    isUpcoming: true,
    seatMap: [
      SeatRow(
        label: 'A',
        seats: [
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
        ],
      ),
      SeatRow(
        label: 'B',
        seats: [
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
        ],
      ),
      SeatRow(
        label: 'C',
        seats: [
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
        ],
      ),
      SeatRow(
        label: 'D',
        seats: [
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: false),
          SeatInfo(type: SeatType.couple, isAvailable: false),
        ],
      ),
    ],
    ticketPrices: {
      SeatType.standard: 11.5,
      SeatType.premium: 17.5,
      SeatType.couple: 26.0,
    },
  ),
  Movie(
    id: '3',
    title: 'Echoes of Avalon',
    tagline: 'Legends are forged in sacrifice.',
    synopsis:
        'A young sorcerer must unite rival kingdoms when ancient magic awakens to consume their world. Destiny, betrayal, and courage collide in this epic fantasy saga.',
    genres: ['Fantasy', 'Drama'],
    rating: 7.9,
    durationMinutes: 156,
    releaseYear: 2024,
    posterUrl: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26',
    backdropUrl: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26',
    cast: ['Emilia Hart', 'Tobias Reed', 'Nyla Khan'],
    showtimes: ['10:45', '14:00', '18:30'],
    isTopPick: true,
    seatMap: [
      SeatRow(
        label: 'A',
        seats: [
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: false),
        ],
      ),
      SeatRow(
        label: 'B',
        seats: [
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: true),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: false),
          SeatInfo(type: SeatType.standard, isAvailable: false),
        ],
      ),
      SeatRow(
        label: 'C',
        seats: [
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: false),
          SeatInfo(type: SeatType.premium, isAvailable: false),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
          SeatInfo(type: SeatType.premium, isAvailable: true),
        ],
      ),
      SeatRow(
        label: 'D',
        seats: [
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
          SeatInfo(type: SeatType.couple, isAvailable: true),
        ],
      ),
    ],
    ticketPrices: {
      SeatType.standard: 10.5,
      SeatType.premium: 15.5,
      SeatType.couple: 24.0,
    },
  ),
];

extension SeatTypeX on SeatType {
  String get label {
    return switch (this) {
      SeatType.standard => 'Standard',
      SeatType.premium => 'Premium',
      SeatType.couple => 'Couple',
    };
  }

  IconData get icon {
    return switch (this) {
      SeatType.standard => Icons.event_seat,
      SeatType.premium => Icons.chair_alt,
      SeatType.couple => Icons.chair,
    };
  }
}

