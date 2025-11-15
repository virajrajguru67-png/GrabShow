import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../widgets/seat_legend.dart';
import 'checkout_screen.dart';

class SeatSelectionArguments {
  const SeatSelectionArguments({
    required this.movie,
    this.showtime,
  });

  final Movie movie;
  final String? showtime;
}

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  static const route = '/seat-selection';

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Movie? _movie;
  String? showtime;
  final Map<String, SeatType> _selectedSeats = {};

  Movie get movie {
    if (_movie == null) {
      throw StateError('Movie not initialized. This should not happen.');
    }
    return _movie!;
  }

  void _processArguments(dynamic args) {
    if (args is! SeatSelectionArguments && args is! Movie) {
      throw FlutterError(
        'SeatSelectionScreen received invalid arguments.\n'
        'Expected: SeatSelectionArguments or Movie\n'
        'Received: ${args.runtimeType}',
      );
    }

    switch (args) {
      case SeatSelectionArguments(:final movie, :final showtime):
        if (mounted) {
          setState(() {
            _movie = movie;
            this.showtime = showtime;
          });
        } else {
          _movie = movie;
          this.showtime = showtime;
        }
      case Movie m:
        if (mounted) {
          setState(() {
            _movie = m;
            showtime = null;
          });
        } else {
          _movie = m;
          showtime = null;
        }
      default:
        throw FlutterError('Invalid arguments for SeatSelectionScreen');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_movie == null) {
      final route = ModalRoute.of(context);
      if (route != null) {
        final args = route.settings.arguments;
        if (args != null) {
          _processArguments(args);
        }
      }
    }
  }

  void _toggleSeat(SeatRow row, int index) {
    final seatInfo = row.seats[index];
    if (!seatInfo.isAvailable) return;
    final seatId = '${row.label}${index + 1}';

    setState(() {
      if (_selectedSeats.containsKey(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        _selectedSeats[seatId] = seatInfo.type;
      }
    });
  }

  double get _totalPrice {
    return _selectedSeats.values.fold<double>(
      0,
      (sum, seatType) => sum + (_movie?.ticketPrices[seatType] ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if movie is not initialized yet
    if (_movie == null) {
      final route = ModalRoute.of(context);
      if (route != null) {
        final args = route.settings.arguments;
        if (args != null && (args is SeatSelectionArguments || args is Movie)) {
          // Process arguments immediately
          _processArguments(args);
        }
      }
      
      // If still null, show loading
      if (_movie == null) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select your seats'),
            centerTitle: true,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    }
    
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your seats'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MovieSummary(movie: _movie!, showtime: showtime),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'SCREEN',
                  style: textTheme.bodyMedium?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (final row in _movie!.seatMap) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        row.label,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var index = 0;
                              index < row.seats.length;
                              index++) ...[
                            _SeatTile(
                              seatInfo: row.seats[index],
                              isSelected: _selectedSeats
                                  .containsKey('${row.label}${index + 1}'),
                              onTap: () => _toggleSeat(row, index),
                              seatId: '${row.label}${index + 1}',
                            ),
                            if (index != row.seats.length - 1)
                              const SizedBox(width: 12),
                            if (index == 1 && row.seats.length > 4)
                              const SizedBox(width: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 24,
                      child: Text(
                        row.label,
                        textAlign: TextAlign.right,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SeatLegend(pricing: _movie!.ticketPrices),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedSeats.isEmpty
                        ? 'No seats selected'
                        : '${_selectedSeats.keys.toList()..sort()}',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: _selectedSeats.isEmpty
                  ? 'Select seats to continue'
                  : 'Proceed to checkout',
              icon: Icons.lock_open,
              onPressed: _selectedSeats.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pushNamed(
                        CheckoutScreen.route,
                        arguments: CheckoutArguments(
                          movie: _movie!,
                          selectedSeats:
                              Map<String, SeatType>.from(_selectedSeats),
                          totalPrice: _totalPrice,
                          showtime: showtime ??
                              (_movie!.showtimes.isNotEmpty
                                  ? _movie!.showtimes.first
                                  : null),
                        ),
                      );
                    },
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seatInfo,
    required this.isSelected,
    required this.onTap,
    required this.seatId,
  });

  final SeatInfo seatInfo;
  final bool isSelected;
  final VoidCallback onTap;
  final String seatId;

  Color _seatColor() {
    if (!seatInfo.isAvailable) {
      return AppColors.textSecondary.withValues(alpha: 0.2);
    }
    if (isSelected) {
      return AppColors.accent;
    }
    return switch (seatInfo.type) {
      SeatType.standard => AppColors.surfaceVariant,
      SeatType.premium => AppColors.accent.withValues(alpha: 0.4),
      SeatType.couple => AppColors.success.withValues(alpha: 0.5),
    };
  }

  @override
  Widget build(BuildContext context) {
    final seatLabel = seatId.replaceAll(RegExp('[^0-9]'), '');
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _seatColor(),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          seatLabel,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _MovieSummary extends StatelessWidget {
  const _MovieSummary({required this.movie, this.showtime});

  final Movie movie;
  final String? showtime;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            movie.posterUrl,
            height: 90,
            width: 65,
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => Container(
              height: 90,
              width: 65,
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.movie, color: AppColors.textSecondary),
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                showtime ?? movie.durationLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    movie.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
