import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../navigation_shell.dart';
import 'admin_login_screen.dart';
import 'admin_settings_page.dart';
import 'admin_users_page.dart';
import 'booking_operations_page.dart';
import 'movies_manager_page.dart';
import 'notification_broadcast_page.dart';
import 'seat_map_editor_page.dart';
import 'settlements_dashboard_page.dart';
import 'showtime_scheduler_page.dart';
import 'theatre_manager_page.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  static const route = '/admin/home';

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final List<_AdminNavItem> _items;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _items = [
      _AdminNavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (navigate) => _DashboardPage(onNavigate: navigate),
      ),
      _AdminNavItem(
        label: 'Movies',
        icon: Icons.movie_filter_outlined,
        builder: (_) => const MoviesManagerPage(),
      ),
      _AdminNavItem(
        label: 'Showtimes',
        icon: Icons.schedule_outlined,
        builder: (_) => const ShowtimeSchedulerPage(),
      ),
      _AdminNavItem(
        label: 'Theatres',
        icon: Icons.theaters_outlined,
        builder: (_) => const TheatreManagerPage(),
      ),
      _AdminNavItem(
        label: 'Seat maps',
        icon: Icons.event_seat_outlined,
        builder: (_) => const SeatMapEditorPage(),
      ),
      _AdminNavItem(
        label: 'Bookings',
        icon: Icons.receipt_long_outlined,
        builder: (_) => const BookingOperationsPage(),
      ),
      _AdminNavItem(
        label: 'Settlements',
        icon: Icons.account_balance_wallet_outlined,
        builder: (_) => const SettlementsDashboardPage(),
      ),
      _AdminNavItem(
        label: 'Admin users',
        icon: Icons.admin_panel_settings_outlined,
        builder: (_) => const AdminUsersPage(),
      ),
      _AdminNavItem(
        label: 'Broadcasts',
        icon: Icons.campaign_outlined,
        builder: (_) => const NotificationBroadcastPage(),
      ),
      _AdminNavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        builder: (_) => const AdminSettingsPage(),
      ),
    ];
  }

  void _navigateTo(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isAdmin || !auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AdminLoginScreen.route, (route) => false);
      });
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 1080;
        final body = _items[_selectedIndex].builder(_navigateTo);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_items[_selectedIndex].label),
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {},
            ),
            actions: [
              FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).pushNamed(NavigationShell.route),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Open customer app'),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await context.read<AuthController>().signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      AdminLoginScreen.route, (route) => false);
                },
              ),
            ],
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _navigateTo,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final item in _items)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(
                              item.icon,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _navigateTo,
                  destinations: [
                    for (final item in _items)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Widget Function(void Function(int)) builder;
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.onNavigate});

  final void Function(int index) onNavigate;

  void _openSection(String key) {
    switch (key) {
      case 'movies':
        onNavigate(1);
        break;
      case 'notifications':
        onNavigate(8);
        break;
      case 'settlements':
        onNavigate(6);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        Text(
          'Admin Dashboard',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s a quick overview of how StreamFlix is performing today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        const _MetricGrid(),
        const SizedBox(height: 24),
        Card(
          color: AppColors.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionRow(
                  icon: Icons.movie_creation_outlined,
                  title: 'Add a new movie',
                  subtitle: 'Keep the catalogue fresh with upcoming releases',
                  onTap: () => _openSection('movies'),
                ),
                _ActionRow(
                  icon: Icons.campaign_outlined,
                  title: 'Schedule a notification',
                  subtitle: 'Send offers to users subscribed to a watchlist',
                  onTap: () => _openSection('notifications'),
                ),
                _ActionRow(
                  icon: Icons.payment_outlined,
                  title: 'Review settlements',
                  subtitle: 'Check pending payouts and reconcile transactions',
                  onTap: () => _openSection('settlements'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    const cards = [
      _MetricCard(
        label: 'Today’s revenue',
        value: '₹12,48,000',
        delta: '+8.2%',
      ),
      _MetricCard(
        label: 'Seat occupancy',
        value: '74%',
        delta: '+3.1%',
      ),
      _MetricCard(
        label: 'Active promos',
        value: '5',
        delta: '2 expiring soon',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final card in cards) ...[
                Expanded(child: card),
                const SizedBox(width: 16),
              ],
            ]..removeLast(),
          );
        }
        return Column(
          children: [
            for (final card in cards) ...[
              card,
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.delta});

  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              delta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
