import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flower_shop/controllers/auth_controller.dart';
import 'package:flower_shop/main_screen.dart';

import '../../utils/app_colors.dart';
import '../../widgets/app_mode_switch_tile.dart';

enum AuthTab {
  login,
  register,
}

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

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
  TextEditingController();

  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
  TextEditingController();
  final TextEditingController _registerPasswordController =
  TextEditingController();

  bool _loginLoading = false;
  bool _registerLoading = false;

  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

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
    final String email = _loginEmailController.text.trim();
    final String password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все поля'),
        ),
      );
      return;
    }

    setState(() {
      _loginLoading = true;
    });

    try {
      final bool success = await _authController.login(
        email,
        password,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        if (_authController.isAdmin) {
          Get.offAllNamed('/admin');
        } else {
          Get.offAll(() => const MainScreen());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка входа'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loginLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    final String name = _registerNameController.text.trim();
    final String email = _registerEmailController.text.trim();
    final String password = _registerPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все поля'),
        ),
      );
      return;
    }

    setState(() {
      _registerLoading = true;
    });

    try {
      final bool success = await _authController.register(
        name,
        email,
        password,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        if (_authController.isAdmin) {
          Get.offAllNamed('/admin');
        } else {
          Get.offAll(() => const MainScreen());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка регистрации'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _registerLoading = false;
        });
      }
    }
  }

  InputDecoration _decoration(
      BuildContext context,
      String label,
      IconData icon,
      ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            context,
            'Email',
            Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          decoration: _decoration(
            context,
            'Пароль',
            Icons.lock_outline_rounded,
          ),
        ),
        const SizedBox(height: 24),
        _submitButton(
          context: context,
          isLoading: _loginLoading,
          onPressed: _login,
          title: 'Войти',
        ),
        const SizedBox(height: 12),
        _DemoHintCard(),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _registerNameController,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            context,
            'Имя',
            Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            context,
            'Email',
            Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _registerPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _register(),
          decoration: _decoration(
            context,
            'Пароль',
            Icons.lock_outline_rounded,
          ),
        ),
        const SizedBox(height: 24),
        _submitButton(
          context: context,
          isLoading: _registerLoading,
          onPressed: _register,
          title: 'Создать аккаунт',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final List<Color> bgGradient = isDark
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
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkCardGradient : null,
                  color: isDark ? null : cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: borderColor,
                  ),
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
                    const SizedBox(height: 10),
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
                      child: Image.asset(
                        'assets/flowerLogo2.png',
                      ),
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

                    const SizedBox(height: 18),

                    const AppModeSwitchTile(
                      compact: true,
                    ),

                    const SizedBox(height: 20),

                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: borderColor,
                        ),
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

                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: SizedBox(
                        height: _tabController.index == 0 ? 330 : 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLoginTab(context),
                            _buildRegisterTab(context),
                          ],
                        ),
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

class _DemoHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated.withValues(alpha: 0.7)
            : AppColors.primaryLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Демо-аккаунты',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Клиент: demo@flowershop.ru / 123456\nАдмин: admin@flowershop.ru / admin123',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}