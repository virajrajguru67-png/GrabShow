import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import 'admin/admin_home_screen.dart';
import 'auth_screen.dart';
import 'navigation_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthController>();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding =
        prefs.getBool('has_completed_onboarding') ?? false;
    if (auth.status == AuthStatus.unknown) {
      await auth.loadSession();
    }

    if (!mounted) return;

    final navigator = Navigator.of(context);

    if (auth.isAuthenticated && auth.isAdmin) {
      navigator.pushReplacementNamed(AdminHomeScreen.route);
      return;
    }

    if (!hasCompletedOnboarding) {
      navigator.pushReplacementNamed(OnboardingScreen.route);
      return;
    }

    if (auth.isAuthenticated) {
      navigator.pushReplacementNamed(NavigationShell.route);
    } else {
      navigator.pushReplacementNamed(AuthScreen.route);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'StreamFlix',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'TICKETS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
