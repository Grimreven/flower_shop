import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class AppDialogActions extends StatelessWidget {
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isDanger;

  const AppDialogActions({
    super.key,
    this.cancelText = 'Отмена',
    required this.confirmText,
    required this.onCancel,
    required this.onConfirm,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor:
              isDark ? AppColors.purpleLight : AppColors.primary,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(cancelText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
              isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(confirmText),
            ),
          ),
        ),
      ],
    );
  }
}