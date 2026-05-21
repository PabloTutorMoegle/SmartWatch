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

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    _devices = await context.read<WatchService>().scan();
    if (mounted) setState(() => _scanning = false);
  }

  void _connect(BluetoothDevice device) async {
    await context.read<WatchService>().connect(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartCatch')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Buscar reloj',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Escaneando...'),
                ],
              ),
            ),
          Expanded(
            child: _devices.isEmpty && !_scanning
                ? Center(
                    child: Column(
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
                    ),
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
        ],
      ),
    );
  }
}
