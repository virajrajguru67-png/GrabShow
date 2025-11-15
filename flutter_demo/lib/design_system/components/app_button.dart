import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

enum AppButtonVariant { primary, secondary, tonal, outline, subtle, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;

  EdgeInsetsGeometry get _padding => switch (size) {
        AppButtonSize.small => const EdgeInsets.symmetric(
            horizontal: DSSpacing.sm,
            vertical: DSSpacing.xs,
          ),
        AppButtonSize.medium => const EdgeInsets.symmetric(
            horizontal: DSSpacing.lg,
            vertical: DSSpacing.sm,
          ),
        AppButtonSize.large => const EdgeInsets.symmetric(
            horizontal: DSSpacing.xl,
            vertical: DSSpacing.md,
          ),
      };

  double get _fontSize => switch (size) {
        AppButtonSize.small => 14,
        AppButtonSize.medium => 16,
        AppButtonSize.large => 18,
      };

  BorderRadius get _radius => BorderRadius.circular(DSRadii.md);

  ButtonStyle _baseStyle(
    Color foreground,
    Color background, {
    Color? overlay,
    BorderSide? border,
  }) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(_padding),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: _fontSize,
          letterSpacing: 0.2,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: _radius,
          side: border ?? BorderSide.none,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) {
            return background.withValues(alpha: 0.35);
          }
          return background;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) {
            return foreground.withValues(alpha: 0.5);
          }
          return foreground;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? (overlay ?? foreground.withValues(alpha: 0.08))
            : null,
      ),
      elevation: WidgetStateProperty.all(0),
      animationDuration: const Duration(milliseconds: 180),
    );
  }

  ButtonStyle _resolveStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return _baseStyle(
          Colors.white,
          AppColors.accent,
          overlay: AppColors.accentSecondary.withValues(alpha: 0.24),
        );
      case AppButtonVariant.secondary:
        return _baseStyle(
          Colors.white,
          AppColors.accentSecondary,
          overlay: AppColors.accent.withValues(alpha: 0.18),
        );
      case AppButtonVariant.tonal:
        return _baseStyle(
          AppColors.textPrimary,
          AppColors.surfaceHighlight,
          overlay: AppColors.textPrimary.withValues(alpha: 0.12),
        );
      case AppButtonVariant.outline:
        return _baseStyle(
          AppColors.accent,
          Colors.transparent,
          overlay: AppColors.accent.withValues(alpha: 0.12),
          border: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.6),
            width: 1.4,
          ),
        );
      case AppButtonVariant.subtle:
        return _baseStyle(
          AppColors.textPrimary,
          AppColors.surfaceMuted,
          overlay: AppColors.accent.withValues(alpha: 0.1),
        );
      case AppButtonVariant.danger:
        return _baseStyle(
          Colors.white,
          AppColors.danger,
          overlay: AppColors.danger.withValues(alpha: 0.2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    Widget buildLabel() {
      final text = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
        ),
      );

      if (icon != null || trailingIcon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(child: text),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 20),
            ],
          ],
        );
      }

      return text;
    }

    final button = FilledButton(
      onPressed: onPressed,
      style: style,
      child: buildLabel(),
    );

    if (variant == AppButtonVariant.outline ||
        variant == AppButtonVariant.subtle) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: buildLabel(),
        ),
      );
    }

    if (variant == AppButtonVariant.tonal) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: style,
          child: buildLabel(),
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: button,
    );
  }
}
