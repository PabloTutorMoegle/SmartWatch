import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/watch_data.dart';
import '../services/background_service.dart';
import '../services/notification_handler.dart';
import 'watch_constants.dart';

class WatchService extends ChangeNotifier {
  final WatchState _state = WatchState();
  WatchState get state => _state;
  bool get isConnected => _state.connected;

  final NotificationHandler notifHandler = NotificationHandler();
  StreamSubscription<AndroidNotification>? _notifSub;

  StreamSubscription<Map<String, dynamic>?>? _serviceSub;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await configureBackgroundService();

      _serviceSub?.cancel();
      _serviceSub = FlutterBackgroundService()
          .on('data')
          .listen(_onServiceData);

      _state.loading = true;
      notifyListeners();

      final running = await FlutterBackgroundService().isRunning();
      if (!running) {
        await _ensureNotificationChannel();
        await FlutterBackgroundService().startService();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      try {
        FlutterBackgroundService().invoke('data', {'action': 'get_state'});
      } catch (_) {}
    } catch (e) {
      debugPrint('BackgroundService init error: $e');
      _state.loading = false;
      notifyListeners();
    }
  }

  void _onConnectionChanged(bool connected) {
    if (connected) {
      _startNotificationForwarding();
    } else {
      _stopNotificationForwarding();
    }
  }

  void _startNotificationForwarding() {
    debugPrint('WatchService: starting notification forwarding');
    notifHandler.startListening();
    _notifSub?.cancel();
    _notifSub = notifHandler.onNotification.listen((n) {
      final title = n.title;
      final text = notifHandler.formatForWatch(n);
      debugPrint('WatchService: forwarding notif title="$title" text="$text"');
      if (title.isEmpty && text.isEmpty) return;
      try {
        FlutterBackgroundService().invoke('data', {
          'action': 'send_notification',
          'title': title,
          'text': text,
        });
      } catch (_) {}
    });
  }

  void _stopNotificationForwarding() {
    debugPrint('WatchService: stopping notification forwarding');
    _notifSub?.cancel();
    _notifSub = null;
    notifHandler.stopListening();
  }

  void _onServiceData(Map<String, dynamic>? data) {
    if (data == null) return;
    try {
      switch (data['type'] as String) {
        case 'connection':
          final wasConnected = _state.connected;
          _state.loading = false;
          _state.connected = data['connected'] == true;
          _state.deviceName = (data['name'] as String?) ?? '';
          _state.reconnecting = false;
          if (data['error'] != null) {
            _state.lastError = data['error'] as String?;
          }
          if (_state.connected != wasConnected) {
            _onConnectionChanged(_state.connected);
          }
          notifyListeners();
        case 'imu_data':
          _state.imu = ImuData(
            ax: int.parse(data['ax'] as String),
            ay: int.parse(data['ay'] as String),
            az: int.parse(data['az'] as String),
            gx: int.parse(data['gx'] as String),
            gy: int.parse(data['gy'] as String),
            gz: int.parse(data['gz'] as String),
          );
          _state.temperature = double.tryParse(data['temp'] as String);
          _state.steps = int.tryParse(data['steps'] as String) ?? 0;
          _state.time = WatchTime(
            hours: int.tryParse(data['h'] as String) ?? 0,
            minutes: int.tryParse(data['m'] as String) ?? 0,
            seconds: int.tryParse(data['s'] as String) ?? 0,
          );
          notifyListeners();
        case 'reconnecting':
          _state.loading = false;
          _state.reconnecting = true;
          _state.reconnectAttempt = data['attempt'] as int? ?? 0;
          notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing service data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> scan() async {
    final granted = await _ensureBlePermissions();
    if (!granted) return [];

    try {
      await FlutterBluePlus.stopScan();

      final devices = <Map<String, dynamic>>[];
      final sub = FlutterBluePlus.scanResults.listen((list) {
        for (final r in list) {
          final id = r.device.remoteId.toString();
          if (!devices.any((d) => d['id'] == id)) {
            devices.add({
              'id': id,
              'name': r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : id,
              'rssi': r.rssi,
            });
          }
        }
      });

      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10),
          androidUsesFineLocation: true,
        );
        await Future.delayed(const Duration(seconds: 10));
      } finally {
        await FlutterBluePlus.stopScan();
        await sub.cancel();
      }

      return devices;
    } catch (e) {
      debugPrint('Scan error: $e');
      return [];
    }
  }

  Future<void> connect(String deviceId, String? deviceName) async {
    _state.reconnecting = false;
    notifyListeners();
    try {
      FlutterBackgroundService().invoke('data', {
        'action': 'connect',
        'deviceId': deviceId,
        'deviceName': deviceName ?? '',
      });
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      FlutterBackgroundService().invoke('data', {'action': 'disconnect'});
    } catch (_) {}
    _state.reconnecting = false;
    notifyListeners();
  }

  Future<void> sendCommand(int cmd, [List<int>? data]) async {
    try {
      FlutterBackgroundService().invoke('data', {
        'action': 'send_command',
        'cmd': cmd,
        'args': data,
      });
    } catch (_) {}
  }

  Future<void> sendTime(int h, int m, int s) async {
    try {
      FlutterBackgroundService().invoke('data', {
        'action': 'send_time',
        'h': h,
        'm': m,
        's': s,
      });
    } catch (_) {}
  }

  Future<void> showTime(int h, int m, int s) async {
    try {
      FlutterBackgroundService().invoke('data', {
        'action': 'show_time',
        'h': h,
        'm': m,
        's': s,
      });
    } catch (_) {}
  }

  Future<void> _ensureNotificationChannel() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      await android.requestNotificationsPermission();
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
    } catch (_) {}
  }

  Future<bool> _ensureBlePermissions() async {
    try {
      var status = await Permission.bluetoothScan.status;
      if (status.isGranted) return true;

      status = await Permission.bluetoothScan.request();
      if (!status.isGranted) return false;

      status = await Permission.bluetoothConnect.request();
      if (!status.isGranted) return false;

      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendTestNotification() async {
    try {
      FlutterBackgroundService().invoke('data', {
        'action': 'send_notification',
        'title': 'SmartCatch TEST',
        'text': 'Notificación de prueba desde la app',
      });
    } catch (_) {}
  }

  Future<void> clearNotifications() async {
    try {
      FlutterBackgroundService().invoke('data', {'action': 'clear_notifications'});
    } catch (_) {}
  }

  Future<void> showImu() async => sendCommand(cmdShowImu);
  Future<void> showSteps() async => sendCommand(cmdShowSteps);
  Future<void> screenOff() async => sendCommand(cmdScreenOff);
  Future<void> resetSteps() async => sendCommand(cmdResetSteps);

  @override
  void dispose() {
    _notifSub?.cancel();
    notifHandler.dispose();
    _serviceSub?.cancel();
    super.dispose();
  }
}
