import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../theme/app_colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  static const route = '/notifications-settings';

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _bookingConfirmations = true;
  bool _bookingReminders = true;
  bool _promotionalOffers = false;
  bool _specialEvents = true;
  bool _priceAlerts = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nottlicalized Settnog'),
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
              'Notification preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _NotificationSection(
              title: 'General',
              items: [
                _NotificationItem(
                  title: 'Push notifications',
                  subtitle: 'Receive notifications on your device',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                _NotificationItem(
                  title: 'Email notifications',
                  subtitle: 'Receive notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
                _NotificationItem(
                  title: 'SMS notifications',
                  subtitle: 'Receive notifications via SMS',
                  value: _smsNotifications,
                  onChanged: (value) =>
                      setState(() => _smsNotifications = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _NotificationSection(
              title: 'Booking',
              items: [
                _NotificationItem(
                  title: 'Booking confirmations',
                  subtitle: 'Get notified when your booking is confirmed',
                  value: _bookingConfirmations,
                  onChanged: (value) =>
                      setState(() => _bookingConfirmations = value),
                ),
                _NotificationItem(
                  title: 'Booking reminders',
                  subtitle: 'Reminders before your showtime',
                  value: _bookingReminders,
                  onChanged: (value) =>
                      setState(() => _bookingReminders = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _NotificationSection(
              title: 'Promotions',
              items: [
                _NotificationItem(
                  title: 'Promotional offers',
                  subtitle: 'Get notified about special deals and discounts',
                  value: _promotionalOffers,
                  onChanged: (value) =>
                      setState(() => _promotionalOffers = value),
                ),
                _NotificationItem(
                  title: 'Special events',
                  subtitle: 'Notifications about special movie events',
                  value: _specialEvents,
                  onChanged: (value) =>
                      setState(() => _specialEvents = value),
                ),
                _NotificationItem(
                  title: 'Price alerts',
                  subtitle: 'Get notified when ticket prices drop',
                  value: _priceAlerts,
                  onChanged: (value) => setState(() => _priceAlerts = value),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save preferences',
              icon: Icons.check_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification preferences saved')),
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

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_NotificationItem> items;

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

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

