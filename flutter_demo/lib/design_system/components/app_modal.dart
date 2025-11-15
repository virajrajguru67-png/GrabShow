import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: dismissible,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DSRadii.lg),
                  ),
                  boxShadow: [
                    DSShadows.lg,
                  ],
                  border: Border(
                    top: BorderSide(color: AppColors.surfaceHighlight),
                    left: BorderSide(color: AppColors.surfaceHighlight),
                    right: BorderSide(color: AppColors.surfaceHighlight),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.lg,
                  vertical: DSSpacing.lg,
                ),
                child: builder(context),
              ),
            ),
          ),
        ),
      );
    },
  );
}
