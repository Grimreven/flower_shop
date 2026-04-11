import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
      macOS: iosInitializationSettings,
    );

    await _plugin.initialize(initializationSettings);

    await _createAndroidChannel();

    _initialized = true;
  }

  Future<void> _createAndroidChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_status_channel',
      'Статусы заказов',
      description: 'Уведомления об изменении статуса заказа',
      importance: Importance.max,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlatform?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlatform?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosPlatform =
    _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await iosPlatform?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final MacOSFlutterLocalNotificationsPlugin? macPlatform =
    _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    await macPlatform?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showOrderStatusNotification({
    required int orderId,
    required String title,
    required String body,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'order_status_channel',
      'Статусы заказов',
      channelDescription: 'Уведомления об изменении статуса заказа',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Обновление заказа',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(
      orderId,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'general_channel',
      'Общие уведомления',
      channelDescription: 'Общие уведомления приложения',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlatform != null) {
      final bool? enabled = await androidPlatform.areNotificationsEnabled();
      return enabled ?? false;
    }

    return true;
  }

  Future<void> debugShowTestNotification() async {
    if (kDebugMode) {
      await showSimpleNotification(
        id: 999001,
        title: 'Тестовое уведомление',
        body: 'Уведомления работают корректно',
      );
    }
  }
}