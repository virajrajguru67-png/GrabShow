import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../widgets/auth/auth_text_field.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  static const route = '/verify-otp';
  final String email;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isOtpVerified = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    auth.clearError();

    final success = await auth.verifyOtp(widget.email, _otpController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() {
        _isOtpVerified = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final hasError = auth.errorMessage != null;

    // After OTP verification, show password reset form
    if (_isOtpVerified) {
      return ResetPasswordScreen(
        email: widget.email,
        otp: _otpController.text.trim(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verify OTP',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter the 6-digit OTP sent to',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AuthTextField(
                        controller: _otpController,
                        label: 'OTP',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: _validateOtp,
                        onEditingComplete: _handleVerify,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: auth.status == AuthStatus.authenticating
                            ? 'Verifying...'
                            : 'Verify OTP',
                        onPressed: auth.status == AuthStatus.authenticating
                            ? null
                            : _handleVerify,
                        fullWidth: true,
                        icon: auth.status == AuthStatus.authenticating
                            ? null
                            : Icons.verified_user,
                      ),
                      // Show OTP in development mode
                      if (auth.resetOtp != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Development Mode - OTP:',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                auth.resetOtp!,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                  letterSpacing: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

