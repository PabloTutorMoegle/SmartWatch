import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../ble/ble_background_manager.dart';

@pragma('vm:entry-point')
void backgroundServiceEntry(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = FlutterLocalNotificationsPlugin();
  {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
    final android = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'smartcatch_ble',
          'SmartCatch BLE',
          description: 'Mantiene la conexión Bluetooth con el reloj',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }
  }

  final manager = BleBackgroundManager(
    onInvoke: (data) => service.invoke('data', data),
    updateNotification: (title, content) async {
      await notifications.show(
        888,
        title,
        content,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'smartcatch_ble',
            'SmartCatch BLE',
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            showWhen: false,
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    },
  );

  await manager.init();

  service.on('data').listen((data) {
    if (data case Map<String, dynamic> msg) {
      manager.handleCommand(msg);
    }
  });
}

Future<void> configureBackgroundService() async {
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundServiceEntry,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'smartcatch_ble',
      initialNotificationTitle: 'SmartCatch',
      initialNotificationContent: 'Iniciando servicio…',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: (_) {},
    ),
  );
}
