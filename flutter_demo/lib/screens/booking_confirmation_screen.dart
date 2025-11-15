import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/mock_movies.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class BookingConfirmationArguments {
  const BookingConfirmationArguments({
    required this.movie,
    required this.seats,
    required this.transactionId,
    required this.amountPaid,
    this.showtime,
    this.paymentMethodLabel,
  });

  final Movie movie;
  final List<String> seats;
  final String transactionId;
  final double amountPaid;
  final String? showtime;
  final String? paymentMethodLabel;
}

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  static const route = '/booking-confirmation';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    assert(
      args is BookingConfirmationArguments,
      'BookingConfirmationScreen requires BookingConfirmationArguments.',
    );
    final typedArgs = args as BookingConfirmationArguments;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirm'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Success checkmark icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Success!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking has been confirmed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            AppCard(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  typedArgs.movie.posterUrl,
                  height: 100,
                  width: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    width: 75,
                    color: AppColors.surfaceVariant,
                    child:
                        const Icon(Icons.movie, color: AppColors.textSecondary),
                  ),
                ),
              ),
              title: typedArgs.movie.title,
              subtitle: typedArgs.showtime ?? 'Showtime to be announced',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: typedArgs.seats
                    .map(
                      (seat) => Chip(
                        label: Text(seat),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: QrImageView(
                      data: typedArgs.transactionId,
                      backgroundColor: Colors.white,
                      size: 180,
                      embeddedImageStyle:
                          const QrEmbeddedImageStyle(size: Size(60, 60)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scan this QR at the cinema entrance',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppCard(
              title: 'Payment summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Transaction ID',
                    value: typedArgs.transactionId,
                    isMonospace: true,
                  ),
                  _InfoRow(
                    label: 'Amount paid',
                    value: '\$${typedArgs.amountPaid.toStringAsFixed(2)}',
                  ),
                  if (typedArgs.paymentMethodLabel != null)
                    _InfoRow(
                      label: 'Paid via',
                      value: typedArgs.paymentMethodLabel!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              title: 'Before you go',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: true,
                    onChanged: (_) {},
                    title: const Text(
                        'Send me a reminder 30 minutes before showtime'),
                  ),
                  SwitchListTile(
                    value: true,
                    onChanged: (_) {},
                    title: const Text('Email this ticket to me'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Share or download your ticket',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveStack(
              breakpoint: DSBreakpoints.md,
              spacing: DSSpacing.md,
              children: [
                AppButton(
                  label: 'Download PDF',
                  icon: Icons.download,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('PDF download will be available soon.')),
                    );
                  },
                  fullWidth: true,
                ),
                AppButton(
                  label: 'Share',
                  icon: Icons.ios_share,
                  variant: AppButtonVariant.subtle,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Share ticket coming soon.')),
                    );
                  },
                  fullWidth: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Complete',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                fullWidth: true,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Need help?\nVisit Support → Help & FAQs or call our 24/7 helpline.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontFeatures:
                  isMonospace ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ],
      ),
    );
  }
}
