import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/auth/social_auth_button.dart';
import 'admin/admin_login_screen.dart';
import 'navigation_shell.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const route = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
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
    final theme = Theme.of(context);

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
                    'Sign In',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome back',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Securely manage your movie tickets, favourite theatres and loyalty perks.',
                style: theme.textTheme.bodyLarge?.copyWith(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Sign in',
                        onPressed: isLoading ? null : _handleSubmit,
                        fullWidth: true,
                        icon: Icons.login_rounded,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context)
                                .pushReplacementNamed(SignUpScreen.route);
                          },
                    child: const Text('Create one'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AdminLoginScreen.route);
                  },
                  child: const Text('Admin access'),
                ),
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
