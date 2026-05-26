import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_constants.dart';

class BleBackgroundManager {
  final void Function(Map<String, dynamic>) onInvoke;
  final Future<void> Function(String title, String content) updateNotification;

  BleBackgroundManager({
    required this.onInvoke,
    required this.updateNotification,
  });

  BluetoothDevice? _device;
  BluetoothCharacteristic? _charCommand;
  BluetoothCharacteristic? _charTime;
  StreamSubscription<List<int>>? _imuSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  String? _savedDeviceId;
  bool _shouldReconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _savedDeviceId = prefs.getString('last_device_id');

    if (_savedDeviceId != null) {
      await updateNotification('SmartCatch', 'Buscando reloj…');
      _tryAutoConnect();
    } else {
      await updateNotification('SmartCatch', 'Listo');
    }
  }

  void handleCommand(Map<String, dynamic> msg) {
    switch (msg['action'] as String) {
      case 'get_state':
        _sendCurrentState();
      case 'connect':
        _handleConnect(msg['deviceId'] as String, msg['deviceName'] as String?);
      case 'disconnect':
        _handleDisconnect();
      case 'send_command':
        _handleSendCommand(
          msg['cmd'] as int,
          (msg['args'] as List?)?.cast<int>(),
        );
      case 'send_time':
        _handleSendTime(
          msg['h'] as int,
          msg['m'] as int,
          msg['s'] as int,
        );
      case 'show_time':
        _handleShowTime(
          msg['h'] as int,
          msg['m'] as int,
          msg['s'] as int,
        );
      case 'send_notification':
        _handleSendNotification(
          msg['title'] as String,
          msg['text'] as String,
        );
      case 'clear_notifications':
        _handleClearNotifications();
    }
  }

  void _sendCurrentState() {
    if (_device != null) {
      onInvoke({
        'type': 'connection',
        'connected': true,
        'name': _device!.platformName.isNotEmpty
            ? _device!.platformName
            : _device!.remoteId.toString(),
      });
    } else if (_shouldReconnect) {
      onInvoke({
        'type': 'reconnecting',
        'attempt': _reconnectAttempts,
      });
    } else {
      onInvoke({
        'type': 'connection',
        'connected': false,
      });
    }
    if (_device != null) {
      onInvoke({'type': 'request_latest_data'});
    }
  }

  Future<void> _handleConnect(String deviceId, String? deviceName) async {
    _savedDeviceId = deviceId;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_device_id', deviceId);

    await updateNotification('SmartCatch', 'Conectando…');

    try {
      await FlutterBluePlus.stopScan();

      BluetoothDevice? target;
      final scanSub = FlutterBluePlus.scanResults.listen((list) {
        for (final r in list) {
          if (r.device.remoteId.toString() == deviceId) {
            target = r.device;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );

      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      await scanSub.cancel();

      if (target == null) {
        onInvoke({'type': 'connection', 'connected': false, 'error': 'Dispositivo no encontrado'});
        await updateNotification('SmartCatch', 'Dispositivo no encontrado');
        return;
      }

      await _doConnect(target!);
    } catch (e) {
      onInvoke({'type': 'connection', 'connected': false, 'error': e.toString()});
      await updateNotification('SmartCatch', 'Error de conexión');
    }
  }

  Future<void> _doConnect(BluetoothDevice device) async {
    _connSub?.cancel();
    _connSub = device.connectionState.listen(_onConnectionStateChanged);

    await device.connect();
    print('[BleBg] connected MTU=${device.mtuNow}');
    await _discoverServices(device);
    _device = device;

    onInvoke({
      'type': 'connection',
      'connected': true,
      'name': device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString(),
    });

    await updateNotification('SmartCatch', 'Conectado');
  }

  void _onConnectionStateChanged(BluetoothConnectionState state) {
    if (state == BluetoothConnectionState.disconnected) {
      _device = null;
      _charCommand = null;
      _charTime = null;
      _imuSub?.cancel();
      _imuSub = null;

      onInvoke({'type': 'connection', 'connected': false});

      if (_shouldReconnect) {
        _scheduleReconnect();
      } else {
        updateNotification('SmartCatch', 'Desconectado');
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _shouldReconnect = false;
      updateNotification('SmartCatch', 'Reconexión agotada');
      return;
    }

    _reconnectAttempts++;

    final delays = [5, 30, 60, 120, 180, 300];
    final idx = (_reconnectAttempts - 1).clamp(0, delays.length - 1);
    final delay = Duration(seconds: delays[idx]);

    onInvoke({'type': 'reconnecting', 'attempt': _reconnectAttempts});
    updateNotification('SmartCatch', 'Reconectando en ${delay.inSeconds}s…');

    _reconnectTimer = Timer(delay, () async {
      if (!_shouldReconnect) return;

      try {
        await FlutterBluePlus.stopScan();

        BluetoothDevice? found;
        final scanSub = FlutterBluePlus.scanResults.listen((list) {
          for (final r in list) {
            if (r.device.remoteId.toString() == _savedDeviceId ||
                r.device.platformName == 'SmartWatch-Pro') {
              found = r.device;
            }
          }
        });

        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10),
          androidUsesFineLocation: true,
        );
        await Future.delayed(const Duration(seconds: 10));
        await FlutterBluePlus.stopScan();
        await scanSub.cancel();

        if (found != null && _shouldReconnect) {
          _reconnectAttempts = 0;
          await updateNotification('SmartCatch', 'Reconectando…');
          await _doConnect(found!);
        } else if (_shouldReconnect) {
          _scheduleReconnect();
        }
      } catch (_) {
        if (_shouldReconnect) _scheduleReconnect();
      }
    });
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final svc in services) {
      if (svc.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (final chr in svc.characteristics) {
          final uuid = chr.uuid.toString().toLowerCase();
          if (uuid == charImuUuid.toLowerCase()) {
            _imuSub = chr.onValueReceived.listen(_parseImu);
            await chr.setNotifyValue(true);
          } else if (uuid == charCommandUuid.toLowerCase()) {
            _charCommand = chr;
          } else if (uuid == charTimeUuid.toLowerCase()) {
            _charTime = chr;
          }
        }
      }
    }
  }

  void _parseImu(List<int> data) {
    final str = utf8.decode(data);
    final parts = str.split(',');
    if (parts.length >= 11) {
      onInvoke({
        'type': 'imu_data',
        'ax': parts[0],
        'ay': parts[1],
        'az': parts[2],
        'gx': parts[3],
        'gy': parts[4],
        'gz': parts[5],
        'temp': parts[6],
        'steps': parts[7],
        'h': parts[8],
        'm': parts[9],
        's': parts[10],
      });

      updateNotification('SmartCatch', '${parts[7]} pasos');
    }
  }

  void _handleDisconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _device?.disconnect();
    _device = null;
    _charCommand = null;
    _charTime = null;
    _imuSub?.cancel();
    _imuSub = null;
    _connSub?.cancel();
    _connSub = null;

    SharedPreferences.getInstance().then((p) => p.remove('last_device_id'));
    _savedDeviceId = null;

    updateNotification('SmartCatch', 'Desconectado');
  }

  Future<void> _handleSendCommand(int cmd, List<int>? args) async {
    final data = buildCommand(cmd, args);
    await _charCommand?.write(data, withoutResponse: true);
  }

  Future<void> _handleSendTime(int h, int m, int s) async {
    await _charTime?.write([h, m, s], withoutResponse: true);
  }

  Future<void> _handleShowTime(int h, int m, int s) async {
    await _charCommand?.write(buildTimeCommand(h, m, s), withoutResponse: true);
  }

  Future<void> _handleSendNotification(String title, String text) async {
    try {
      final data = buildSendNotification(title, text);
      print('[BleBg] writing notif cmd len=${data.length} charCommand=${_charCommand != null}');
      if (_charCommand == null) {
        print('[BleBg] charCommand is null, cannot send notification');
        onInvoke({'type': 'notif_send_result', 'success': false, 'error': 'charCommand null'});
        return;
      }
      print('[BleBg] sending: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(" ")}');
      await _charCommand!.write(data, withoutResponse: false);
      print('[BleBg] write completed successfully');
      onInvoke({'type': 'notif_send_result', 'success': true});
    } catch (e) {
      print('[BleBg] send notification error: $e');
      onInvoke({'type': 'notif_send_result', 'success': false, 'error': e.toString()});
    }
  }

  Future<void> _handleClearNotifications() async {
    print('[BleBg] clearing notifications charCommand=${_charCommand != null}');
    await _charCommand?.write([cmdClearNotifications], withoutResponse: true);
  }

  void _tryAutoConnect() {
    if (_savedDeviceId == null) return;
    _handleConnect(_savedDeviceId!, null);
  }
}
