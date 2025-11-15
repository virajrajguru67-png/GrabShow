import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/auth/social_auth_button.dart';
import 'navigation_shell.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const route = '/sign-up';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await auth.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );
    if (!mounted) return;
    _handleAuthResult(auth);
  }

  Future<void> _handleGoogle() async {
    final auth = context.read<AuthController>();
    await auth.signInWithGoogle();
    if (!mounted) return;
    _handleAuthResult(auth);
  }

  Future<void> _handleApple() async {
    final auth = context.read<AuthController>();
    await auth.signInWithApple();
    if (!mounted) return;
    _handleAuthResult(auth);
  }

  void _handleAuthResult(AuthController controller) {
    if (controller.status == AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        NavigationShell.route,
        (route) => route.isFirst,
      );
    } else if (controller.status == AuthStatus.error &&
        controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage!)),
      );
      controller.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Join StreamFlix',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your account to book seats in seconds and earn exclusive rewards.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.surfaceHighlight),
                  boxShadow: const [DSShadows.md],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthTextField(
                        controller: _nameController,
                        label: 'Full name',
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: _validatePassword,
                        onEditingComplete: _handleSubmit,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Create account',
                        icon: Icons.rocket_launch_rounded,
                        onPressed: isLoading ? null : _handleSubmit,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.surfaceHighlight)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.surfaceHighlight)),
                ],
              ),
              const SizedBox(height: 24),
              SocialAuthButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onPressed: isLoading ? null : _handleGoogle,
              ),
              const SizedBox(height: 12),
              SocialAuthButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                onPressed: isLoading ? null : _handleApple,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Already have an account?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context)
                                .pushReplacementNamed(SignInScreen.route);
                          },
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    if (!isValid) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
