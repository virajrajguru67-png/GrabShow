import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

typedef ResponsiveGridItemBuilder = Widget Function(
    BuildContext context, int index, double width);

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = DSSpacing.lg,
    this.runSpacing = DSSpacing.lg,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.xs = 1,
    this.sm = 2,
    this.md = 3,
    this.lg = 4,
    this.xl = 5,
    super.key,
  });

  final int itemCount;
  final ResponsiveGridItemBuilder itemBuilder;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final int xs;
  final int sm;
  final int md;
  final int lg;
  final int xl;

  int _resolveColumns(double width) {
    if (width >= DSBreakpoints.xl) return xl;
    if (width >= DSBreakpoints.lg) return lg;
    if (width >= DSBreakpoints.md) return md;
    if (width >= DSBreakpoints.sm) return sm;
    return xs;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _resolveColumns(constraints.maxWidth);
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: alignment,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (int index = 0; index < itemCount; index++)
              SizedBox(
                width: itemWidth,
                child: itemBuilder(context, index, itemWidth),
              ),
          ],
        );
      },
    );
  }
}
