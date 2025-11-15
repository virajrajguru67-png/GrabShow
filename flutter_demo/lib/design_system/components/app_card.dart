import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.all(DSSpacing.lg),
    this.margin,
    this.onTap,
    this.footer,
    this.backgroundColor = AppColors.surfaceVariant,
    this.borderColor,
    this.elevation = 0,
    super.key,
  });

  final Widget? child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final GestureTapCallback? onTap;
  final Widget? footer;
  final Color backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null ||
            subtitle != null ||
            leading != null ||
            trailing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DSSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: DSSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        if (child != null) child!,
        if (footer != null) ...[
          const SizedBox(height: DSSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: DSSpacing.md),
          footer!,
        ],
      ],
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: backgroundColor,
        elevation: elevation,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DSRadii.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DSRadii.lg),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
            ),
            padding: padding,
            child: body,
          ),
        ),
      ),
    );
  }
}
