import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_user.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/avatar_image.dart';
import '../widgets/auth/social_auth_button.dart';
import 'bookings_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'notifications_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'auth_screen.dart';
import 'navigation_shell.dart';
import 'saved_theatres_screen.dart';
import 'terms_privacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: switch (auth.status) {
            AuthStatus.unknown ||
            AuthStatus.authenticating =>
              const _LoadingState(),
            AuthStatus.error => _ErrorState(
                message: auth.errorMessage,
                onRetry: () => context.read<AuthController>().loadSession(),
              ),
            AuthStatus.unauthenticated => _GuestProfileView(
                isLoading: auth.status == AuthStatus.authenticating,
                onSignIn: () => _openSignIn(context),
                onCreateAccount: () => _openSignUp(context),
                onGoogle: auth.status == AuthStatus.authenticating
                    ? null
                    : () => context.read<AuthController>().signInWithGoogle(),
                onApple: auth.status == AuthStatus.authenticating
                    ? null
                    : (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                        ? () =>
                            context.read<AuthController>().signInWithApple()
                        : null),
              ),
            AuthStatus.authenticated => _AuthenticatedProfileView(
                user: auth.user!,
                onLogout: () => _confirmLogout(context),
              ),
          },
        ),
      ),
    );
  }

  void _openSignIn(BuildContext context) {
    Navigator.of(context).pushNamed(AuthScreen.route);
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(context).pushNamed(AuthScreen.route);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await showAppModal<void>(
      context: context,
      builder: (context) => _LogoutSheet(
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          Navigator.of(context).pop();
          await context.read<AuthController>().signOut();
        },
      ),
    );
  }
}

class _AuthenticatedProfileView extends StatelessWidget {
  const _AuthenticatedProfileView({
    required this.user,
    required this.onLogout,
  });

  final AuthUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = [
      _MenuItem(
        icon: Icons.person_rounded,
        label: 'Edit profile',
        onTap: () => Navigator.of(context).pushNamed(EditProfileScreen.route),
      ),
      _MenuItem(
        icon: Icons.confirmation_number_rounded,
        label: 'My tickets',
        onTap: () => Navigator.of(context).pushNamed(BookingsScreen.route),
      ),
      _MenuItem(
        icon: Icons.notifications_active_rounded,
        label: 'Notifications & alerts',
        onTap: () => Navigator.of(context)
            .pushNamed(NotificationsSettingsScreen.route),
      ),
      _MenuItem(
        icon: Icons.credit_card_rounded,
        label: 'Payment methods',
        onTap: () =>
            Navigator.of(context).pushNamed(PaymentMethodsScreen.route),
      ),
      _MenuItem(
        icon: Icons.location_on_rounded,
        label: 'Saved theatres',
        onTap: () =>
            Navigator.of(context).pushNamed(SavedTheatresScreen.route),
      ),
      _MenuItem(
        icon: Icons.headset_mic_rounded,
        label: 'Help & support',
        onTap: () => Navigator.of(context).pushNamed(HelpSupportScreen.route),
      ),
      _MenuItem(
        icon: Icons.privacy_tip_rounded,
        label: 'Terms & privacy',
        onTap: () => Navigator.of(context).pushNamed(TermsPrivacyScreen.route),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            // Always navigate to Explore tab (NavigationShell) to avoid going to auth screen
            // This ensures the back button never takes the user to sign-in/sign-up page
            Navigator.of(context).pushReplacementNamed(NavigationShell.route);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary),
        ),
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _ProfileHeaderCard(user: user),
          const SizedBox(height: 32),
          Text(
            'Account settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ...menuItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProfileMenuTile(item: item),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Log out',
            variant: AppButtonVariant.danger,
            onPressed: onLogout,
            fullWidth: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF111827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: const [DSShadows.md],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(EditProfileScreen.route),
                child: AvatarImage(
                  avatarUrl: user.avatarUrl,
                  radius: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: AppColors.accentSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CinePass+',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accentSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_rounded,
                    color: Colors.amberAccent, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loyalty status',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        'CinePass Explorer',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.white60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView({
    required this.isLoading,
    required this.onSignIn,
    required this.onCreateAccount,
    this.onGoogle,
    this.onApple,
  });

  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to manage bookings, saved seats and loyalty rewards.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SocialAuthButton(
            icon: Icons.facebook_rounded,
            label: 'Continue with Facebook',
            onPressed: isLoading ? null : () {},
          ),
          const SizedBox(height: 12),
          SocialAuthButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onPressed: isLoading ? null : onGoogle,
          ),
          if (onApple != null) ...[
            const SizedBox(height: 12),
            SocialAuthButton(
              icon: Icons.apple,
              label: 'Continue with Apple',
              onPressed: isLoading ? null : onApple,
            ),
          ],
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.surfaceHighlight)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              Expanded(child: Divider(color: AppColors.surfaceHighlight)),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Sign in with password',
            onPressed: isLoading ? null : onSignIn,
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Create new account',
            variant: AppButtonVariant.outline,
            onPressed: isLoading ? null : onCreateAccount,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: item.onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          child: Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Text(
          'Logout',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Are you sure you want to log out?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.subtle,
                onPressed: onCancel,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Log out',
                variant: AppButtonVariant.danger,
                onPressed: onConfirm,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            message ?? 'We couldn\'t load your profile.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Retry',
            variant: AppButtonVariant.tonal,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}


