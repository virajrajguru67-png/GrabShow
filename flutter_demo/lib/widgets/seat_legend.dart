import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';

class SeatLegend extends StatelessWidget {
  const SeatLegend({
    super.key,
    required this.pricing,
  });

  final Map<SeatType, double> pricing;

  Color _colorForSeat(SeatType type) {
    return switch (type) {
      SeatType.standard => AppColors.surfaceVariant,
      SeatType.premium => AppColors.accent,
      SeatType.couple => AppColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        for (final entry in pricing.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _colorForSeat(entry.key),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.key.label} • \$${entry.value.toStringAsFixed(0)}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Available',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Reserved',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
