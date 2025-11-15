import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

enum AppInputVariant { filled, outline, underline }

class AppInput extends StatelessWidget {
  const AppInput({
    required this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.variant = AppInputVariant.filled,
    this.maxLines = 1,
    this.minLines,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final Widget? leading;
  final Widget? trailing;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final AppInputVariant variant;
  final int? maxLines;
  final int? minLines;

  InputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadii.md),
        borderSide: BorderSide(color: color, width: 1.3),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = Theme.of(context).textTheme.bodyMedium;

    final decoration = InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: leading,
      suffixIcon: trailing,
      filled: variant != AppInputVariant.outline,
      fillColor: switch (variant) {
        AppInputVariant.underline => Colors.transparent,
        AppInputVariant.filled => AppColors.surfaceMuted,
        AppInputVariant.outline => AppColors.surface,
      },
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.sm + 2,
      ),
      border: switch (variant) {
        AppInputVariant.filled => _border(AppColors.surfaceHighlight),
        AppInputVariant.outline => _border(AppColors.border),
        AppInputVariant.underline => UnderlineInputBorder(
            borderSide:
                BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
          ),
      },
      enabledBorder: switch (variant) {
        AppInputVariant.filled => _border(AppColors.surfaceHighlight),
        AppInputVariant.outline => _border(AppColors.border),
        AppInputVariant.underline => UnderlineInputBorder(
            borderSide:
                BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
          ),
      },
      focusedBorder: switch (variant) {
        AppInputVariant.filled => _border(AppColors.accent),
        AppInputVariant.outline => _border(AppColors.accent),
      AppInputVariant.underline => const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
      },
      errorBorder: switch (variant) {
        AppInputVariant.filled => _border(AppColors.danger),
        AppInputVariant.outline => _border(AppColors.danger),
      AppInputVariant.underline => const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      },
      focusedErrorBorder: switch (variant) {
        AppInputVariant.filled => _border(AppColors.danger),
        AppInputVariant.outline => _border(AppColors.danger),
      AppInputVariant.underline => const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      },
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: baseStyle?.copyWith(color: AppColors.textMuted),
      hintStyle: baseStyle?.copyWith(color: AppColors.textMuted),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      cursorColor: AppColors.accent,
      style: baseStyle?.copyWith(color: scheme.onSurface),
      decoration: decoration,
    );
  }
}
