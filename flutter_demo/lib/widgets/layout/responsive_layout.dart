import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

typedef ResponsiveBuilder = Widget Function(
    BuildContext context, BoxConstraints constraints);

/// Centers content and applies dynamic horizontal padding based on the current
/// breakpoint. This keeps pages consistent across all screen sizes.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.builder,
    this.maxWidth,
    this.padding,
    super.key,
  });

  final ResponsiveBuilder builder;
  final double? maxWidth;
  final EdgeInsets? padding;

  double _resolveMaxWidth(double width) {
    if (maxWidth != null) return maxWidth!;
    if (width >= DSBreakpoints.xl) return 1200;
    if (width >= DSBreakpoints.lg) return 1040;
    if (width >= DSBreakpoints.md) return 880;
    return width;
  }

  EdgeInsets _resolvePadding(double width) {
    if (padding != null) return padding!;
    if (width >= DSBreakpoints.xl) {
      return const EdgeInsets.symmetric(
          horizontal: DSSpacing.xl, vertical: DSSpacing.xl);
    }
    if (width >= DSBreakpoints.lg) {
      return const EdgeInsets.symmetric(
          horizontal: DSSpacing.xl, vertical: DSSpacing.lg);
    }
    if (width >= DSBreakpoints.md) {
      return const EdgeInsets.symmetric(
          horizontal: DSSpacing.lg, vertical: DSSpacing.lg);
    }
    if (width >= DSBreakpoints.sm) {
      return const EdgeInsets.symmetric(
          horizontal: DSSpacing.md, vertical: DSSpacing.lg);
    }
    return const EdgeInsets.symmetric(
        horizontal: DSSpacing.md, vertical: DSSpacing.lg);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final resolvedPadding = _resolvePadding(width);
        final constrainedWidth = _resolveMaxWidth(width);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constrainedWidth),
            child: Padding(
              padding: resolvedPadding,
              child: builder(context, constraints),
            ),
          ),
        );
      },
    );
  }
}
