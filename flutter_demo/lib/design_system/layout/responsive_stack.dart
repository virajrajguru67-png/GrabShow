import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// ResponsiveRowColumn-like helper but with deterministic breakpoint behaviour.
class ResponsiveStack extends StatelessWidget {
  const ResponsiveStack({
    required this.children,
    this.spacing = DSSpacing.lg,
    this.runSpacing = DSSpacing.lg,
    this.breakpoint = DSBreakpoints.md,
    this.alignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double breakpoint;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isRow = constraints.maxWidth >= breakpoint;
        if (isRow) {
          return Row(
            mainAxisAlignment: alignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: [
              for (int index = 0; index < children.length; index++) ...[
                if (index != 0) SizedBox(width: spacing),
                Expanded(child: children[index]),
              ],
            ],
          );
        }

        return Column(
          mainAxisAlignment: alignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: [
            for (int index = 0; index < children.length; index++) ...[
              if (index != 0) SizedBox(height: runSpacing),
              children[index],
            ],
          ],
        );
      },
    );
  }
}
