import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceHighlight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accentSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.surfaceHighlight,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.surfaceHighlight,
      onTertiaryContainer: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFF7F1D32),
      onErrorContainer: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceTint: Colors.transparent,
      outline: AppColors.border,
      outlineVariant: AppColors.surfaceHighlight,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Color(0xFFE2E8F9),
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.accentSecondary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      useMaterial3: true,
      fontFamily: DSTextStyles.fontFamily,
      textTheme: _textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: DSTextStyles.titleMd.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceVariant,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadii.lg),
        ),
        titleTextStyle: DSTextStyles.titleMd.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: DSTextStyles.bodyMd.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.md,
          vertical: DSSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadii.md),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        hintStyle: DSTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        labelStyle:
            DSTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.lg,
            vertical: DSSpacing.sm,
          ),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSRadii.md),
          ),
          textStyle: DSTextStyles.label,
        ).merge(
          ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? AppColors.accentSecondary.withValues(alpha: 0.18)
                  : null,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.lg,
            vertical: DSSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSRadii.md),
          ),
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textPrimary,
          textStyle: DSTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: DSTextStyles.label.copyWith(letterSpacing: 0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.sm,
            vertical: DSSpacing.xs,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.accent.withValues(alpha: 0.18),
        side: const BorderSide(color: AppColors.border),
        labelStyle: DSTextStyles.bodySm.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.sm,
          vertical: DSSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadii.md),
        ),
        secondaryLabelStyle: DSTextStyles.bodySm.copyWith(color: Colors.white),
        secondarySelectedColor: AppColors.accent,
        showCheckmark: false,
      ),
      dividerColor: AppColors.border.withValues(alpha: 0.6),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.md,
          vertical: DSSpacing.sm,
        ),
        tileColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadii.md),
        ),
        titleTextStyle:
            DSTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
        subtitleTextStyle:
            DSTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        iconColor: AppColors.textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.accent.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.all(
          DSTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textMuted,
            size: 24,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 78,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: DSTextStyles.bodyMd.copyWith(
          color: AppColors.textPrimary,
        ),
        actionTextColor: AppColors.accentSecondary,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displaySmall: DSTextStyles.display.copyWith(color: scheme.onSurface),
      headlineLarge: DSTextStyles.titleLg.copyWith(color: scheme.onSurface),
      headlineMedium: DSTextStyles.titleMd.copyWith(color: scheme.onSurface),
      headlineSmall: DSTextStyles.titleSm.copyWith(color: scheme.onSurface),
      titleLarge: DSTextStyles.titleMd.copyWith(color: scheme.onSurface),
      titleMedium: DSTextStyles.titleSm.copyWith(color: scheme.onSurface),
      titleSmall: DSTextStyles.bodyMd
          .copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
      bodyLarge: DSTextStyles.bodyLg.copyWith(color: AppColors.textSecondary),
      bodyMedium: DSTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
      bodySmall: DSTextStyles.bodySm.copyWith(color: AppColors.textMuted),
      labelLarge: DSTextStyles.label.copyWith(color: scheme.onPrimary),
      labelMedium: DSTextStyles.bodySm.copyWith(color: AppColors.textMuted),
      labelSmall: DSTextStyles.bodySm
          .copyWith(fontSize: 12, color: AppColors.textMuted),
    );
  }
}
