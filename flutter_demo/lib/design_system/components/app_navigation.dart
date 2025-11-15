import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppNavbarDestination {
  const AppNavbarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
    this.customIcon,
    this.customSelectedIcon,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget? badge;
  final Widget? customIcon;
  final Widget? customSelectedIcon;
}

class AppNavbar extends StatelessWidget {
  const AppNavbar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.height = 68,
    super.key,
  });

  final List<AppNavbarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.surfaceHighlight),
          boxShadow: const [DSShadows.md],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.accent.withValues(alpha: 0.16),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
            height: height,
            backgroundColor: Colors.transparent,
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: destination.badge != null,
                    backgroundColor: AppColors.danger,
                    label: destination.badge,
                    child: destination.customIcon ?? Icon(
                      destination.icon,
                      color: AppColors.textMuted,
                    ),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: destination.badge != null,
                    backgroundColor: AppColors.danger,
                    label: destination.badge,
                    child: destination.customSelectedIcon ?? Icon(
                      destination.selectedIcon,
                      color: AppColors.accent,
                    ),
                  ),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSidebarDestination {
  const AppSidebarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget? badge;
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.width = 88,
    this.extended = true,
    this.compact = false,
    super.key,
  });

  final List<AppSidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final double width;
  final bool extended;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.surface,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended && !compact,
      minWidth: compact ? 64 : width,
      labelType:
          compact ? NavigationRailLabelType.all : NavigationRailLabelType.none,
      selectedIconTheme: const IconThemeData(
        color: AppColors.accent,
        size: 26,
      ),
      unselectedIconTheme: const IconThemeData(
        color: AppColors.textMuted,
        size: 24,
      ),
      selectedLabelTextStyle: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent),
      unselectedLabelTextStyle: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: AppColors.textMuted),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Badge(
              isLabelVisible: destination.badge != null,
              backgroundColor: AppColors.danger,
              label: destination.badge,
              child: Icon(destination.icon),
            ),
            selectedIcon: Badge(
              isLabelVisible: destination.badge != null,
              backgroundColor: AppColors.danger,
              label: destination.badge,
              child: Icon(destination.selectedIcon),
            ),
            label: Text(destination.label),
          ),
      ],
    );
  }
}
