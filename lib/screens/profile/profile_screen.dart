import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import 'loyalty_card.dart';
import 'package:flower_shop/main_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.find<AuthController>();

  User? editedUser;
  bool isLoading = true;
  bool isEditing = false;
  String activeSection = 'info';

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    final profile = await authController.getProfile();
    if (!mounted) return;

    if (profile == null) {
      _showMessage("Пользователь не найден. Пожалуйста, войдите снова.");
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      editedUser = profile;
      nameController = TextEditingController(text: profile.name);
      emailController = TextEditingController(text: profile.email);
      phoneController = TextEditingController(text: profile.phone ?? '');
      addressController = TextEditingController(text: profile.address ?? '');
      isLoading = false;
    });
  }

  void _showMessage(String msg) {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  Future<void> handleSave() async {
    if (editedUser == null) return;

    setState(() => isLoading = true);
    final updated = await authController.updateProfile(editedUser!);
    if (!mounted) return;

    if (updated != null) {
      setState(() {
        editedUser = updated;
        isEditing = false;
        isLoading = false;
        nameController.text = updated.name;
        emailController.text = updated.email;
        phoneController.text = updated.phone ?? '';
        addressController.text = updated.address ?? '';
      });
      _showMessage("Профиль успешно обновлён");
    } else {
      setState(() => isLoading = false);
      _showMessage("Ошибка при обновлении профиля");
    }
  }

  void handleCancel() {
    setState(() {
      isEditing = false;
      if (editedUser != null) {
        nameController.text = editedUser!.name;
        emailController.text = editedUser!.email;
        phoneController.text = editedUser!.phone ?? '';
        addressController.text = editedUser!.address ?? '';
      }
    });
  }

  Future<void> handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authController.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );
    }
  }

  Widget _sectionButton(String id, String label, IconData icon) {
    final bool isActive = activeSection == id;
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: isActive ? Colors.pink.shade100 : Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => setState(() => activeSection = id),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.pink : Colors.grey, size: 20),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 12, color: isActive ? Colors.pink : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, Function(String) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        enabled: isEditing,
        controller: controller,
        onChanged: onChange,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    if (editedUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Профиль")),
        body: const Center(child: Text("Нет данных профиля")),
      );
    }

    final user = editedUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Профиль"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: handleLogout,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA1A1), Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.logout, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар и основные данные
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(
                        user.name.split(' ').map((n) => n[0]).join(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user.email, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.card_giftcard,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                  "${user.loyaltyLevel} • ${user.loyaltyPoints} баллов",
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Секция переключения
            Card(
              child: Row(
                children: [
                  _sectionButton('info', 'Личные данные', Icons.person),
                  _sectionButton('loyalty', 'Лояльность', Icons.card_giftcard),
                  _sectionButton('settings', 'Настройки', Icons.settings),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- Секции ---
            if (activeSection == 'info')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Личные данные",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          !isEditing
                              ? TextButton.icon(
                            onPressed: () => setState(() => isEditing = true),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text("Редактировать"),
                          )
                              : Row(
                            children: [
                              OutlinedButton(
                                  onPressed: handleCancel,
                                  child: const Text("Отмена")),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                  onPressed: handleSave,
                                  child: const Text("Сохранить")),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _inputField("Имя", nameController,
                              (val) => editedUser = editedUser!.copyWith(name: val)),
                      _inputField("Email", emailController,
                              (val) => editedUser = editedUser!.copyWith(email: val)),
                      _inputField("Телефон", phoneController,
                              (val) => editedUser = editedUser!.copyWith(phone: val)),
                      _inputField("Адрес доставки", addressController,
                              (val) => editedUser = editedUser!.copyWith(address: val)),
                    ],
                  ),
                ),
              ),

            if (activeSection == 'loyalty')
              LoyaltyCard(
                level: user.loyaltyLevel,
                points: user.loyaltyPoints,
                totalSpent: user.totalSpent,
                nextLevelPoints: user.loyaltyLevel == 'Bronze'
                    ? 1000
                    : user.loyaltyLevel == 'Silver'
                    ? 2500
                    : 5000,
                colorHex: user.loyaltyColor,
              ),

            if (activeSection == 'settings')
              Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Уведомления",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SwitchListTile(
                            title: const Text("Push-уведомления"),
                            value: true,
                            onChanged: (val) {},
                          ),
                          SwitchListTile(
                            title: const Text("Email-рассылка"),
                            value: true,
                            onChanged: (val) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.credit_card),
                          label: const Text("Способы оплаты"),
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
