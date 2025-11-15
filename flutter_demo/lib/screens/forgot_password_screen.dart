import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../widgets/auth/auth_text_field.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const route = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    if (!isValid) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    // Clear any previous errors
    auth.clearError();
    await auth.requestPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    // If no error, navigate to OTP verification screen
    if (auth.status != AuthStatus.error) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VerifyOtpScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    }
    // Error will be displayed in the bottom banner automatically
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.status == AuthStatus.authenticating;
    final hasError = auth.status == AuthStatus.error && auth.errorMessage != null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your email address and we\'ll send you an OTP to reset your password.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            AuthTextField(
                              controller: _emailController,
                              label: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: _validateEmail,
                              onEditingComplete: _handleSubmit,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: 'Send OTP',
                                icon: Icons.email_outlined,
                                onPressed: isLoading ? null : _handleSubmit,
                                fullWidth: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Back to Sign In',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            // Error banner at the bottom
            if (hasError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: AppColors.danger,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        auth.clearError();
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

