import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const route = '/help-support';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _HelpSection(
              title: 'Frequently Asked Questions',
              items: const [
                _HelpItem(
                  question: 'How do I book tickets?',
                  answer:
                      'Select a movie, choose your showtime, pick your seats, and proceed to checkout. You can pay using UPI, card, or wallet.',
                ),
                _HelpItem(
                  question: 'Can I cancel my booking?',
                  answer:
                      'Yes, you can cancel your booking up to 2 hours before the showtime. Go to "My tickets" and select the booking you want to cancel.',
                ),
                _HelpItem(
                  question: 'How do I change my payment method?',
                  answer:
                      'Go to Profile > Payment methods to add, remove, or set a default payment method.',
                ),
                _HelpItem(
                  question: 'What if I miss my show?',
                  answer:
                      'Unfortunately, we cannot refund tickets for missed shows. However, you can cancel up to 2 hours before showtime.',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _HelpSection(
              title: 'Contact Support',
              items: [
                _HelpItem(
                  question: 'Email Support',
                  answer: 'support@grabshow.com',
                  onTap: () async {
                    final uri = Uri.parse('mailto:support@grabshow.com');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                _HelpItem(
                  question: 'Phone Support',
                  answer: '+1 (555) 123-4567',
                  onTap: () async {
                    final uri = Uri.parse('tel:+15551234567');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                _HelpItem(
                  question: 'Live Chat',
                  answer: 'Available 24/7',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live chat feature coming soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _HelpSection(
              title: 'Resources',
              items: [
                _HelpItem(
                  question: 'Booking Guide',
                  answer: 'Step-by-step guide to booking tickets',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking guide coming soon')),
                    );
                  },
                ),
                _HelpItem(
                  question: 'Payment Help',
                  answer: 'Troubleshooting payment issues',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment help coming soon')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_HelpItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: item,
          ),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.question,
    required this.answer,
    this.onTap,
  });

  final String question;
  final String answer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

