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
  StreamSubscription? _tempSub;
  StreamSubscription? _buttonSub;
  StreamSubscription? _connSub;

  final WatchState _state = WatchState();
  WatchState get state => _state;

  bool get isConnected => _state.connected;

  Future<List<ScanResult>> scan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    final results = <ScanResult>[];
    final completer = Completer<List<ScanResult>>();
    late StreamSubscription sub;

    sub = FlutterBluePlus.scanResults.listen((list) {
      for (final r in list) {
        final name = r.device.platformName;
        if (name.contains(targetDeviceName) ||
            r.device.remoteId.toString().contains(targetDeviceName)) {
          if (!results.any((e) => e.device.remoteId == r.device.remoteId)) {
            results.add(r);
          }
        }
        if (results.isNotEmpty) {
          completer.complete(results);
          sub.cancel();
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    try {
      return await completer.future.timeout(const Duration(seconds: 11));
    } catch (_) {
      return results;
    } finally {
      await FlutterBluePlus.stopScan();
      sub.cancel();
    }
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
    await _device!.disconnect();
    _disconnected();
  }

  void _disconnected() {
    _state.connected = false;
    _state.deviceName = '';
    _imuSub?.cancel();
    _tempSub?.cancel();
    _buttonSub?.cancel();
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
          } else if (uuid == charTempUuid.toLowerCase()) {
            _tempSub = chr.onValueReceived.listen(_parseTemp);
            await chr.setNotifyValue(true);
          } else if (uuid == charButtonUuid.toLowerCase()) {
            _buttonSub = chr.onValueReceived.listen(_parseButton);
            await chr.setNotifyValue(true);
          } else if (uuid == charCommandUuid.toLowerCase()) {
            _charCommand = chr;
          } else if (uuid == charTimeUuid.toLowerCase()) {
            _charTime = chr;
            await chr.setNotifyValue(true);
            chr.onValueReceived.listen(_parseTime);
          }
        }
      }
    }
  }

  void _parseImu(List<int> data) {
    final str = utf8.decode(data);
    final parts = str.split(',');
    if (parts.length >= 6) {
      _state.imu = ImuData(
        ax: int.parse(parts[0]),
        ay: int.parse(parts[1]),
        az: int.parse(parts[2]),
        gx: int.parse(parts[3]),
        gy: int.parse(parts[4]),
        gz: int.parse(parts[5]),
      );
      notifyListeners();
    }
  }

  void _parseTemp(List<int> data) {
    final str = utf8.decode(data);
    _state.temperature = double.tryParse(str);
    notifyListeners();
  }

  void _parseButton(List<int> data) {
    _state.buttonState = utf8.decode(data);
    notifyListeners();
  }

  void _parseTime(List<int> data) {
    if (data.length >= 3) {
      _state.time = WatchTime(hours: data[0], minutes: data[1], seconds: data[2]);
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
    _tempSub?.cancel();
    _buttonSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
