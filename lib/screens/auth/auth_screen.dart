import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flower_shop/controllers/auth_controller.dart';
import 'package:flower_shop/main_screen.dart';

import '../../utils/app_colors.dart';

enum AuthTab { login, register }

class AuthScreen extends StatefulWidget {
  final AuthTab initialTab;

  const AuthScreen({
    super.key,
    this.initialTab = AuthTab.login,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginLoading = false;

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _registerLoading = false;

  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialTab == AuthTab.register) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailController.text.isEmpty ||
        _loginPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _loginLoading = true);

    try {
      final success = await _authController.login(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );

      if (success) {
        if (!mounted) return;
        Get.offAll(() => const MainScreen());
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка входа')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loginLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (_registerNameController.text.isEmpty ||
        _registerEmailController.text.isEmpty ||
        _registerPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _registerLoading = true);

    try {
      final success = await _authController.register(
        _registerNameController.text.trim(),
        _registerEmailController.text.trim(),
        _registerPasswordController.text,
      );

      if (success) {
        if (!mounted) return;
        Get.offAll(() => const MainScreen());
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка регистрации')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _registerLoading = false);
      }
    }
  }

  InputDecoration _decoration(
      BuildContext context,
      String label,
      IconData icon,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: isDark ? AppColors.purpleLight : AppColors.primary,
      ),
    );
  }

  Widget _submitButton({
    required BuildContext context,
    required bool isLoading,
    required VoidCallback onPressed,
    required String title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(
          color: isDark ? AppColors.purple : AppColors.primary,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.purple : AppColors.primary)
                .withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final bgGradient = isDark
        ? const [
      AppColors.darkBackground,
      AppColors.darkBackgroundSecondary,
    ]
        : const [
      Color(0xFFFFF2F5),
      Color(0xFFFCE3EA),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkCardGradient : null,
                  color: isDark ? null : cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.purple.withValues(alpha: 0.08)
                          : AppColors.shadow,
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                ? AppColors.purple
                                : AppColors.primary)
                                .withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/flowerLogo2.png'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Добро пожаловать',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Войдите или создайте аккаунт для полного доступа к заказам и бонусам',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: EdgeInsets.zero,
                        dividerColor: Colors.transparent,
                        splashBorderRadius: BorderRadius.circular(14),
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                        indicator: BoxDecoration(
                          gradient: isDark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tabs: const [
                          Tab(
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'Вход',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'Регистрация',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 330,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Column(
                            children: [
                              TextField(
                                controller: _loginEmailController,
                                decoration: _decoration(
                                  context,
                                  'Email',
                                  Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _loginPasswordController,
                                decoration: _decoration(
                                  context,
                                  'Пароль',
                                  Icons.lock_outline_rounded,
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 24),
                              _submitButton(
                                context: context,
                                isLoading: _loginLoading,
                                onPressed: _login,
                                title: 'Войти',
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              TextField(
                                controller: _registerNameController,
                                decoration: _decoration(
                                  context,
                                  'Имя',
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _registerEmailController,
                                decoration: _decoration(
                                  context,
                                  'Email',
                                  Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _registerPasswordController,
                                decoration: _decoration(
                                  context,
                                  'Пароль',
                                  Icons.lock_outline_rounded,
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 24),
                              _submitButton(
                                context: context,
                                isLoading: _registerLoading,
                                onPressed: _register,
                                title: 'Создать аккаунт',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}