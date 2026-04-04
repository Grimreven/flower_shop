import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const String _orderNotificationsKey = 'settings_order_notifications';
  static const String _promoNotificationsKey = 'settings_promo_notifications';
  static const String _loyaltyNotificationsKey = 'settings_loyalty_notifications';
  static const String _darkThemeKey = 'settings_dark_theme';

  final orderNotifications = true.obs;
  final promoNotifications = true.obs;
  final loyaltyNotifications = true.obs;
  final darkTheme = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    orderNotifications.value = prefs.getBool(_orderNotificationsKey) ?? true;
    promoNotifications.value = prefs.getBool(_promoNotificationsKey) ?? true;
    loyaltyNotifications.value = prefs.getBool(_loyaltyNotificationsKey) ?? true;
    darkTheme.value = prefs.getBool(_darkThemeKey) ?? false;
  }

  Future<void> setOrderNotifications(bool value) async {
    orderNotifications.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_orderNotificationsKey, value);
  }

  Future<void> setPromoNotifications(bool value) async {
    promoNotifications.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promoNotificationsKey, value);
  }

  Future<void> setLoyaltyNotifications(bool value) async {
    loyaltyNotifications.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loyaltyNotificationsKey, value);
  }

  Future<void> setDarkTheme(bool value) async {
    darkTheme.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkThemeKey, value);
  }
}