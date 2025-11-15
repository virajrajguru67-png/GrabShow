import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'movie_detail_screen.dart';
import 'navigation_shell.dart';
import 'seat_selection_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const route = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _categories = [
    'All',
    'Nearby',
    'IMAX',
    '3D',
    'Dolby Atmos',
    'Family',
  ];

  String _query = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Movie> get _results {
    final base = _selectedCategory == 'All'
        ? mockMovies
        : mockMovies.where(
            (movie) => movie.genres.any(
              (genre) =>
                  genre.toLowerCase() == _selectedCategory.toLowerCase(),
            ),
          );

    if (_query.isEmpty) {
      return base.take(12).toList();
    }

    return base
        .where(
          (movie) =>
              movie.title.toLowerCase().contains(_query.toLowerCase()) ||
              movie.genres.any(
                  (genre) => genre.toLowerCase().contains(_query.toLowerCase())),
        )
        .toList();
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).pushNamed(
      MovieDetailScreen.route,
      arguments: movie,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Always navigate to Explore tab to avoid going to auth screen
                      Navigator.of(context).pushReplacementNamed(NavigationShell.route);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.surfaceHighlight),
                  boxShadow: const [DSShadows.sm],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18).copyWith(right: 6),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (value) {
                          setState(() => _query = value);
                        },
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search movies, theatres or cities...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _controller.clear();
                          });
                        },
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              if (!hasQuery) ...[
                // Show suggestions when no query
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: mockMovies.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final movie = mockMovies[index];
                      return _SuggestionTile(
                        movie: movie,
                        onTap: () => _openMovie(movie),
                      );
                    },
                  ),
                ),
              ] else ...[
              Text(
                  '${results.length} showtimes found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: results.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final movie = results[index];
                          return _SearchResultCard(
                            movie: movie,
                            onViewDetail: () => _openMovie(movie),
                            onBook: () => Navigator.of(context).pushNamed(
                              SeatSelectionScreen.route,
                              arguments: SeatSelectionArguments(
                                movie: movie,
                                showtime: movie.showtimes.isNotEmpty
                                    ? movie.showtimes.first
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.movie,
    required this.onViewDetail,
    required this.onBook,
  });

  final Movie movie;
  final VoidCallback onViewDetail;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onViewDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                        ),
                        child: Image.network(
                          movie.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => const Icon(
                            Icons.movie_creation_outlined,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      movie.title,
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: movie.genres.take(3).map((genre) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: movie.showtimes.map((time) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.surfaceHighlight,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_filled,
                                  size: 14,
                                  color: AppColors.accentSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  time,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            AppButton(
              label: 'Book',
              size: AppButtonSize.small,
              onPressed: onBook,
              icon: Icons.event_seat_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.movie,
    required this.onTap,
  });

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Image.network(
                  movie.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.genres.take(2).join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_filter_outlined,
              size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search for another title.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
