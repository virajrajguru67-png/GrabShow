import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/layout/responsive_layout.dart';
import 'navigation_shell.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  static const route = '/bookings';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Always navigate to Explore tab to avoid going to auth screen
            Navigator.of(context).pushReplacementNamed(NavigationShell.route);
          },
        ),
      ),
      body: ResponsiveLayout(
        builder: (context, _) => auth.isAuthenticated
            ? const _BookingsContent()
            : _NotAuthenticated(
                onSignIn: () => Navigator.of(context).pushNamed('/sign-in'),
              ),
      ),
    );
  }
}

class _BookingsContent extends StatelessWidget {
  const _BookingsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            'Payment Methods',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _PaymentMethodOption(
                  title: 'toond Platicton',
                  icon: Icons.credit_card_rounded,
                  isSelected: true,
                ),
                const Divider(height: 24),
                _PaymentMethodOption(
                  title: 'Wouse Gel',
                  icon: Icons.account_balance_wallet_rounded,
                  isSelected: false,
                ),
                const Divider(height: 24),
                _PaymentMethodOption(
                  title: 'Transtion',
                  icon: Icons.account_balance_rounded,
                  isSelected: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.title,
    required this.icon,
    required this.isSelected,
  });

  final String title;
  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        if (isSelected)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            ),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _NotAuthenticated extends StatelessWidget {
  const _NotAuthenticated({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 72, color: AppColors.textMuted),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Log in to see your bookings',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          ),
          const SizedBox(height: DSSpacing.xs),
          Text(
            'Securely store and manage all your tickets in one place.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.lg),
          ElevatedButton(
            onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            child: const Text('Sign in'),
          ),
        ],
        ),
      ),
    );
  }
}
