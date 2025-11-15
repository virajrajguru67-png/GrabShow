import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../components/app_navigation.dart';

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.badge,
    this.customIcon,
    this.customSelectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
  final Widget? badge;
  final Widget? customIcon;
  final Widget? customSelectedIcon;
}

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    required this.destinations,
    this.appBar,
    this.backgroundColor = AppColors.background,
    this.floatingActionButton,
    this.fabLocation,
    this.railWidth = 84,
    this.navbarHeight = 72,
    this.initialIndex = 0,
    this.onDestinationSelected,
    this.persistentFooterButtons,
    super.key,
  }) : assert(destinations.length >= 2, 'Provide at least two destinations');

  final List<AdaptiveDestination> destinations;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? fabLocation;
  final double railWidth;
  final double navbarHeight;
  final int initialIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Widget>? persistentFooterButtons;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  late int _index = widget.initialIndex;

  @override
  void didUpdateWidget(covariant AdaptiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _index) {
      _index = widget.initialIndex;
    }
  }

  void _handleSelect(int value) {
    if (_index == value) return;
    setState(() => _index = value);
    widget.onDestinationSelected?.call(value);
  }

  List<Widget> get _pages =>
      widget.destinations.map((dest) => dest.builder(context)).toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= DSBreakpoints.lg;
        final isTablet = width >= DSBreakpoints.md;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: widget.backgroundColor,
            appBar: widget.appBar,
            floatingActionButton: widget.floatingActionButton,
            floatingActionButtonLocation: widget.fabLocation,
            body: Row(
              children: [
                AppSidebar(
                  width: widget.railWidth,
                  selectedIndex: _index,
                  destinations: [
                    for (final destination in widget.destinations)
                      AppSidebarDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: destination.label,
                        badge: destination.badge,
                      ),
                  ],
                  onDestinationSelected: _handleSelect,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: _pages,
                  ),
                ),
              ],
            ),
          );
        }

        if (isTablet) {
          return Scaffold(
            backgroundColor: widget.backgroundColor,
            appBar: widget.appBar,
            floatingActionButton: widget.floatingActionButton,
            floatingActionButtonLocation: widget.fabLocation,
            body: Row(
              children: [
                AppSidebar(
                  width: widget.railWidth - 16,
                  extended: false,
                  selectedIndex: _index,
                  destinations: [
                    for (final destination in widget.destinations)
                      AppSidebarDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: destination.label,
                        badge: destination.badge,
                      ),
                  ],
                  onDestinationSelected: _handleSelect,
                  compact: true,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: _pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: widget.backgroundColor,
          appBar: widget.appBar,
          floatingActionButton: widget.floatingActionButton,
          floatingActionButtonLocation: widget.fabLocation,
          body: IndexedStack(
            index: _index,
            children: _pages,
          ),
          bottomNavigationBar: AppNavbar(
            height: widget.navbarHeight,
            selectedIndex: _index,
            destinations: [
              for (final destination in widget.destinations)
                AppNavbarDestination(
                  icon: destination.icon,
                  selectedIcon: destination.selectedIcon,
                  label: destination.label,
                  badge: destination.badge,
                  customIcon: destination.customIcon,
                  customSelectedIcon: destination.customSelectedIcon,
                ),
            ],
            onDestinationSelected: _handleSelect,
          ),
          persistentFooterButtons: widget.persistentFooterButtons,
        );
      },
    );
  }
}
