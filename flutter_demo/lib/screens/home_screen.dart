import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../data/mock_movies.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/movie_poster_card.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = '/explore';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _heroController = PageController(viewportFraction: 0.84);
  final List<String> _filters = [
    'All',
    'Nearby',
    '2D',
    '3D',
    'IMAX',
    'Luxury',
  ];

  String _activeFilter = 'All';
  String _query = '';
  int _heroIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  List<Movie> get _trending =>
      mockMovies.where((movie) => movie.isTrending).toList();

  List<Movie> get _newReleases =>
      mockMovies.where((movie) => movie.isUpcoming || movie.isTopPick).toList();

  List<Movie> get _topPicks =>
      mockMovies.where((movie) => movie.isTopPick).toList();

  List<Movie> _applyFilters(List<Movie> movies) {
    final filteredByGenre = _activeFilter == 'All'
        ? movies
        : movies
            .where(
              (movie) => movie.genres.any(
                (genre) =>
                    genre.toLowerCase().contains(_activeFilter.toLowerCase()),
              ),
            )
            .toList();

    if (_query.isEmpty) return filteredByGenre;

    return filteredByGenre
        .where(
          (movie) =>
              movie.title.toLowerCase().contains(_query.toLowerCase()) ||
              movie.genres.any(
                (genre) =>
                    genre.toLowerCase().contains(_query.toLowerCase()),
              ),
        )
        .toList();
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).pushNamed(
      MovieDetailScreen.route,
      arguments: movie,
    );
  }

  void _openProfile() {
    Navigator.of(context).pushNamed(ProfileScreen.route);
  }

  void _openSearch() {
    Navigator.of(context).pushNamed(SearchScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final heroMovies =
        _trending.isNotEmpty ? _trending : mockMovies.take(6).toList();
    final trending = _applyFilters(_trending.isNotEmpty ? _trending : mockMovies);
    final latest = _applyFilters(_newReleases);
    final recommendations = _applyFilters(_topPicks.isNotEmpty
        ? _topPicks
        : List<Movie>.from(mockMovies)..shuffle(Random(7)));

    const greeting = 'GrabShow';
    const subtitle = '';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeTopBar(
                greeting: greeting,
                subtitle: subtitle,
                isAuthenticated: auth.isAuthenticated && auth.user != null,
                avatarInitials: auth.isAuthenticated && auth.user != null
                    ? _initialsFromName(auth.user!.displayName)
                    : null,
                onAvatarTap: _openProfile,
              ),
              const SizedBox(height: 24),
              _SearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                onTap: _openSearch,
                onFilterTap: () => setState(() {
                  final currentIndex = _filters.indexOf(_activeFilter);
                  final nextIndex = (currentIndex + 1) % _filters.length;
                  _activeFilter = _filters[nextIndex];
                }),
              ),
              const SizedBox(height: 20),
              _FilterPills(
                filters: _filters,
                activeFilter: _activeFilter,
                onFilterSelected: (value) {
                  setState(() => _activeFilter = value);
                },
              ),
              const SizedBox(height: 28),
              _HeroCarousel(
                controller: _heroController,
                movies: heroMovies,
                currentIndex: _heroIndex,
                onPageChanged: (index) => setState(() => _heroIndex = index),
                onBook: _openMovie,
              ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Home Seavvn',
                subtitle: 'Tomglurid Save',
                actionLabel: 'View all',
                onActionTap: () => setState(() {
                  _activeFilter = 'All';
                  _query = '';
                  _searchController.clear();
                }),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 310,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trending.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, index) {
                    final movie = trending[index];
                    return MoviePosterCard(
                      movie: movie,
                      onTap: () => _openMovie(movie),
                      width: 180,
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
              _SectionHeader(
                title: 'Tonight\'s Showtimes',
                subtitle: 'Quick access to the next available screenings',
                actionLabel: 'View all',
                onActionTap: () => setState(() {
                  _activeFilter = 'All';
                }),
              ),
              const SizedBox(height: 18),
              _ShowtimeList(
                movies: latest.take(4).toList(),
                onWatchNow: _openMovie,
              ),
              const SizedBox(height: 32),
              const _SectionHeader(
                title: 'Reconnimonded 4.0. You',
                subtitle: 'Based on your booking history and favourites',
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final movie = recommendations[index];
                    return _MiniPosterTile(
                      movie: movie,
                      onTap: () => _openMovie(movie),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              _PremiumCallout(onStart: () {
                if (heroMovies.isNotEmpty) {
                  _openMovie(heroMovies.first);
                }
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.greeting,
    required this.subtitle,
    required this.isAuthenticated,
    required this.onAvatarTap,
    this.avatarInitials,
  });

  final String greeting;
  final String subtitle;
  final bool isAuthenticated;
  final VoidCallback onAvatarTap;
  final String? avatarInitials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(
          Icons.local_movies_rounded,
          color: AppColors.accent,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'GrabShow',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 24,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed(SearchScreen.route);
          },
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onTap,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: const [DSShadows.sm],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search movies, theatres or cities',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [DSShadows.sm],
              ),
              child: const Icon(
                Icons.event_seat_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({
    required this.filters,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = filter == activeFilter;
          return ChoiceChip(
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                filter,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            selected: isActive,
            onSelected: (_) => onFilterSelected(filter),
          );
        },
      ),
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.controller,
    required this.movies,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onBook,
  });

  final PageController controller;
  final List<Movie> movies;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Movie> onBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: controller,
            padEnds: false,
            itemCount: movies.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  right: 16,
                  top: currentIndex == index ? 0 : 12,
                  bottom: currentIndex == index ? 0 : 12,
                ),
                child: _HeroCard(
                  movie: movie,
                  isFocused: currentIndex == index,
                  onBook: () => onBook(movie),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < movies.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: currentIndex == i ? 28 : 10,
                decoration: BoxDecoration(
                  color: currentIndex == i
                      ? AppColors.accent
                      : AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.movie,
    required this.isFocused,
    required this.onBook,
  });

  final Movie movie;
  final bool isFocused;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onBook,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.surfaceMuted),
              child: Image.network(
                movie.backdropUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => const Icon(
                  Icons.local_movies,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 18, color: Colors.orangeAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Trending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${movie.releaseYear}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.circle, size: 6, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(
                        movie.durationLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    movie.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.tagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Book tickets',
                          icon: Icons.event_seat_rounded,
                          size: AppButtonSize.small,
                          onPressed: onBook,
                          fullWidth: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'View details',
                          icon: Icons.info_outline_rounded,
                          variant: AppButtonVariant.tonal,
                          size: AppButtonSize.small,
                          onPressed: onBook,
                          fullWidth: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isFocused)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _ShowtimeList extends StatelessWidget {
  const _ShowtimeList({
    required this.movies,
    required this.onWatchNow,
  });

  final List<Movie> movies;
  final ValueChanged<Movie> onWatchNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final movie in movies)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _ShowtimeListTile(
              movie: movie,
              onTap: () => onWatchNow(movie),
            ),
          ),
      ],
    );
  }
}

class _ShowtimeListTile extends StatelessWidget {
  const _ShowtimeListTile({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 86,
              width: 86,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.surfaceMuted),
                child: Image.network(
                  movie.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => const Icon(
                    Icons.movie_filter_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${movie.genres.take(2).join(' • ')} • ${movie.releaseYear}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movie.showtimes.take(4).map((time) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_filled,
                              size: 14, color: AppColors.accentSecondary),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppButton(
            label: 'Book',
            onPressed: onTap,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }
}

class _MiniPosterTile extends StatelessWidget {
  const _MiniPosterTile({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        height: 260,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    movie.backdropUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => const Icon(
                      Icons.local_movies_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.genres.take(2).join(' • '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_filled,
                    size: 16, color: AppColors.accentSecondary),
                const SizedBox(width: 6),
                Text(
                  movie.showtimes.isNotEmpty ? movie.showtimes.first : 'TBA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Colors.amberAccent),
                const SizedBox(width: 4),
                Text(
                  movie.rating.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _PremiumCallout extends StatelessWidget {
  const _PremiumCallout({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF111827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: const [DSShadows.md],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'CinePass+ Member',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accentSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Skip queues with priority bookings.',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Unlock zero convenience fees, seat recommendations and exclusive premiere access.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Explore membership',
            onPressed: onStart,
            icon: Icons.workspace_premium_outlined,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

