import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../widgets/seat_legend.dart';
import '../widgets/youtube_player_widget.dart';
import 'home_screen.dart';
import 'seat_selection_screen.dart';

class MovieDetailArguments {
  const MovieDetailArguments({required this.movie});

  final Movie movie;
}

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  static const route = '/movie-detail';

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Movie? _movie;
  String _selectedShowtime = '';

  Movie? get movie => _movie;

  void _processArguments(dynamic args) {
    if (args is! MovieDetailArguments && args is! Movie) {
      throw FlutterError(
        'MovieDetailScreen received invalid arguments.\n'
        'Expected: Movie or MovieDetailArguments\n'
        'Received: ${args.runtimeType}',
      );
    }

    final movie = switch (args) {
      Movie m => m,
      MovieDetailArguments m => m.movie,
      _ => throw FlutterError('Invalid arguments for MovieDetailScreen')
    };

    // Always use setState to ensure proper widget updates
    if (mounted) {
      setState(() {
        _movie = movie;
        _selectedShowtime = _movie!.showtimes.isNotEmpty ? _movie!.showtimes.first : '';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize immediately when dependencies are available
    if (_movie == null) {
      final route = ModalRoute.of(context);
      if (route != null) {
        final args = route.settings.arguments;
        if (args != null) {
          // Process synchronously if possible
          _processArguments(args);
        } else {
          // If args are null, try again after a frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_movie == null && mounted) {
              final retryRoute = ModalRoute.of(context);
              final retryArgs = retryRoute?.settings.arguments;
              if (retryArgs != null) {
                _processArguments(retryArgs);
              }
            }
          });
        }
      }
    }
  }

  void _handleShowtimeTap(String value) {
    setState(() {
      _selectedShowtime = value;
    });
  }

  void _openSeats() {
    if (_movie == null) return;
    Navigator.of(context).pushNamed(
      SeatSelectionScreen.route,
      arguments: SeatSelectionArguments(
        movie: _movie!,
        showtime: _selectedShowtime.isEmpty ? null : _selectedShowtime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Try to get arguments one more time if movie is null
    if (_movie == null) {
      final route = ModalRoute.of(context);
      if (route != null) {
        final args = route.settings.arguments;
        if (args != null && (args is Movie || args is MovieDetailArguments)) {
          // Process arguments - this will call setState and trigger rebuild
          _processArguments(args);
          // Return loading while setState is processing
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed(HomeScreen.route);
                  }
                },
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
      
      // If no arguments found, show loading
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(HomeScreen.route);
              }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final castChips = movie!.cast.take(6).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Backdrop(movie: movie!),
            Padding(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),  
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie!.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie!.tagline,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetaChip(
                        icon: Icons.star,
                        label: movie!.rating.toStringAsFixed(1),
                      ),
                      _MetaChip(
                        icon: Icons.schedule,
                        label: movie!.durationLabel,
                      ),
                      _MetaChip(
                        icon: Icons.calendar_today,
                        label: '${movie!.releaseYear}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Storyline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie!.synopsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Genres',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final genre in movie!.genres)
                        Chip(
                          label: Text(genre),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Showtimes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final showtime in movie!.showtimes)
                        ChoiceChip(
                          label: Text(showtime),
                          selected: _selectedShowtime == showtime,
                          onSelected: (_) => _handleShowtimeTap(showtime),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cast',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final member in castChips)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Text(
                                    member
                                        .split(' ')
                                        .map((e) => e[0])
                                        .take(2)
                                        .join(),
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  member,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ticket prices',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SeatLegend(pricing: movie!.ticketPrices),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Select seats',
                    icon: Icons.event_seat,
                    onPressed: movie!.seatMap.isEmpty ? null : _openSeats,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topSafeArea = statusBarHeight + appBarHeight;
    
    return Stack(
      children: [
     SizedBox(
  height: 240 + appBarHeight,  // <-- Change to just appBarHeight
          width: double.infinity,
          child: movie.trailerUrl != null
              ? Stack(
                  children: [
                    Positioned(
                      top: appBarHeight + 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: YouTubePlayerWidget(
                            videoId: movie.trailerUrl!,
                            height: 240,
                          ),
                        ),
                      ),
                    ),
                    // Add gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Add a transparent overlay in the AppBar area to ensure buttons are clickable
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topSafeArea,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                )
              : Image.network(
                  movie.backdropUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, _, __) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.movie,
                        size: 96, color: AppColors.textSecondary),
                  ),
                ),
        ),
        // Gradient overlay for image (only when no trailer)
        if (movie.trailerUrl == null)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
