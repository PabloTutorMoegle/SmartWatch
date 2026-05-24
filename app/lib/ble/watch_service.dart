import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/watch_data.dart';
import 'watch_constants.dart';

class WatchService extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _charCommand;
  BluetoothCharacteristic? _charTime;

  StreamSubscription? _imuSub;
  StreamSubscription? _connSub;

  final WatchState _state = WatchState();
  WatchState get state => _state;

  bool get isConnected => _state.connected;

  Future<List<ScanResult>> scan() async {
    await FlutterBluePlus.stopScan();

    final results = <ScanResult>[];
    final sub = FlutterBluePlus.scanResults.listen((list) {
      for (final r in list) {
        if (!results.any((e) => e.device.remoteId == r.device.remoteId)) {
          results.add(r);
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
      await Future.delayed(const Duration(seconds: 11));
    } finally {
      await FlutterBluePlus.stopScan();
      await sub.cancel();
    }

    return results.where((r) =>
        r.device.platformName.isNotEmpty ||
        r.rssi > -90).toList();
  }

  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _disconnected();
      }
    });

    await device.connect();
    await _discoverServices(device);
    _state.connected = true;
    _state.deviceName = device.platformName;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _disconnected();
  }

  void _disconnected() {
    _state.connected = false;
    _state.deviceName = '';
    _imuSub?.cancel();
    _charCommand = null;
    _charTime = null;
    notifyListeners();
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
      _state.imu = ImuData(
        ax: int.parse(parts[0]),
        ay: int.parse(parts[1]),
        az: int.parse(parts[2]),
        gx: int.parse(parts[3]),
        gy: int.parse(parts[4]),
        gz: int.parse(parts[5]),
      );
      _state.temperature = double.tryParse(parts[6]);
      _state.steps = int.tryParse(parts[7]) ?? 0;
      _state.time = WatchTime(
        hours: int.tryParse(parts[8]) ?? 0,
        minutes: int.tryParse(parts[9]) ?? 0,
        seconds: int.tryParse(parts[10]) ?? 0,
      );
      notifyListeners();
    }
  }

  Future<void> sendCommand(int cmd, [List<int>? data]) async {
    final cmdData = buildCommand(cmd, data);
    await _charCommand?.write(cmdData, withoutResponse: true);
  }

  Future<void> sendTime(int h, int m, int s) async {
    await _charTime?.write([h, m, s], withoutResponse: true);
  }

  Future<void> showTime(int h, int m, int s) async {
    await _charCommand?.write(buildTimeCommand(h, m, s), withoutResponse: true);
  }

  Future<void> showImu() async => sendCommand(cmdShowImu);
  Future<void> showSteps() async => sendCommand(cmdShowSteps);
  Future<void> screenOff() async => sendCommand(cmdScreenOff);
  Future<void> resetSteps() async => sendCommand(cmdResetSteps);

  @override
  void dispose() {
    _imuSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
