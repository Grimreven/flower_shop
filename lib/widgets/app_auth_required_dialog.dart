import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/auth/auth_screen.dart';
import '../utils/app_colors.dart';

class AppAuthRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const AppAuthRequiredDialog({
    super.key,
    this.title = 'Требуется вход',
    this.message =
    'Чтобы открыть этот раздел, пожалуйста, авторизуйтесь или зарегистрируйтесь.',
    this.confirmText = 'Войти',
    this.cancelText = 'Отмена',
  });

  static Future<void> show(
      BuildContext context, {
        String title = 'Требуется вход',
        String message =
        'Чтобы открыть этот раздел, пожалуйста, авторизуйтесь или зарегистрируйтесь.',
        String confirmText = 'Войти',
        String cancelText = 'Отмена',
      }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) {
        return AppAuthRequiredDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color dialogColor =
    isDark ? AppColors.darkSurfaceElevated : Colors.white;

    final Color titleColor =
    isDark ? AppColors.purpleLight : AppColors.primary;

    final Color textColor =
    isDark ? AppColors.darkForeground : AppColors.foreground;

    final Color borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    final Color cancelTextColor =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final LinearGradient buttonGradient =
    isDark ? AppColors.darkBrandGradient : AppColors.brandGradient;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: dialogColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cancelTextColor,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.primary.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: buttonGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.purple : AppColors.primary)
                              .withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.to(() => AuthScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}