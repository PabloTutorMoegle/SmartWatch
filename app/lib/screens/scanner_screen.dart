import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble/watch_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<ScanResult> _devices = [];
  bool _scanning = false;
  bool _scanned = false;
  String? _error;

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _scanned = true;
      _error = null;
      _devices = [];
    });
    try {
      _devices = await context.read<WatchService>().scan();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _scanning = false);
  }

  void _connect(BluetoothDevice device) async {
    await context.read<WatchService>().connect(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartCatch')),
      body: Center(
        child: _scanning
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Escaneando...'),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  )
                : !_scanned
                    ? FilledButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('Escanear'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      )
                    : _devices.isEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No se encontraron dispositivos'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _startScan,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Escanear de nuevo'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _devices.length,
                            itemBuilder: (_, i) {
                              final d = _devices[i];
                              final name = d.device.platformName.isNotEmpty
                                  ? d.device.platformName
                                  : d.device.remoteId.toString();
                              return ListTile(
                                leading: const Icon(Icons.watch),
                                title: Text(name),
                                subtitle: Text('${d.rssi} dBm'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _connect(d.device),
                              );
                            },
                          ),
      ),
    );
  }
}
