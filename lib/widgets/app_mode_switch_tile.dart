import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../controllers/app_mode_controller.dart';
import '../utils/app_colors.dart';

class AppModeSwitchTile extends StatelessWidget {
  const AppModeSwitchTile({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppModeController controller = Get.find<AppModeController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final AppRunMode currentMode = controller.mode.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              currentMode: currentMode,
              compact: compact,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Text(
              currentMode == AppRunMode.demo
                  ? 'Сейчас приложение работает на тестовых данных без базы данных.'
                  : 'Сейчас приложение работает через сервер и PostgreSQL.',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                height: 1.3,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    title: 'Демо',
                    icon: Icons.phone_android_rounded,
                    selected: currentMode == AppRunMode.demo,
                    isDark: isDark,
                    onTap: () {
                      _confirmChange(
                        context: context,
                        controller: controller,
                        mode: AppRunMode.demo,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    title: 'Сервер',
                    icon: Icons.storage_rounded,
                    selected: currentMode == AppRunMode.server,
                    isDark: isDark,
                    onTap: () {
                      _confirmChange(
                        context: context,
                        controller: controller,
                        mode: AppRunMode.server,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmChange({
    required BuildContext context,
    required AppModeController controller,
    required AppRunMode mode,
  }) async {
    if (controller.mode.value == mode) {
      return;
    }

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final bool isDemo = mode == AppRunMode.demo;

        return AlertDialog(
          title: const Text('Сменить режим?'),
          content: Text(
            isDemo
                ? 'Приложение переключится на локальные тестовые данные. Текущая сессия будет сброшена.'
                : 'Приложение переключится на сервер и PostgreSQL. Текущая сессия будет сброшена.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Переключить'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await controller.setMode(mode);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.currentMode,
    required this.compact,
    required this.isDark,
  });

  final AppRunMode currentMode;
  final bool compact;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool isDemo = currentMode == AppRunMode.demo;

    return Row(
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                AppColors.purple,
                AppColors.purpleLight,
              ]
                  : [
                AppColors.primary,
                AppColors.accent,
              ],
            ),
          ),
          child: Icon(
            isDemo ? Icons.phone_android_rounded : Icons.storage_rounded,
            color: Colors.white,
            size: compact ? 18 : 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Режим работы',
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDemo ? 'Демо-режим' : 'Сервер + PostgreSQL',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.purpleLight : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isDark ? AppColors.purple : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? activeColor
                  : isDark
                  ? AppColors.darkBorder
                  : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? activeColor
                    : isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? activeColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}