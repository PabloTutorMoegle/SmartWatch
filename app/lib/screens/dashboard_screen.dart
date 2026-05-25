import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ble/watch_service.dart';
import '../ble/watch_constants.dart';
import '../models/watch_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WatchService>();
    final state = service.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.deviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () => service.disconnect(),
            tooltip: 'Desconectar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.reconnecting)
            Container(
              width: double.infinity,
              color: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('Reconectando… (intento ${state.reconnectAttempt})'),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TimeCard(state: state),
                const SizedBox(height: 12),
                _ImuCard(state: state),
                const SizedBox(height: 12),
                _StepsCard(state: state),
                const SizedBox(height: 12),
                _CommandsCard(service: service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final WatchState state;
  const _TimeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final time = state.time;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Hora del reloj', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              time?.formatted ?? '--:--:--',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text('${state.temperature?.toStringAsFixed(1) ?? "--"} °C',
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _ImuCard extends StatelessWidget {
  final WatchState state;
  const _ImuCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final imu = state.imu;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IMU', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (imu != null) ...[
              _imuRow('Acc', imu.ax, imu.ay, imu.az),
              const SizedBox(height: 4),
              _imuRow('Gyro', imu.gx, imu.gy, imu.gz),
              const SizedBox(height: 4),
              Text('Acc (G): ${imu.axG.toStringAsFixed(2)}, ${imu.ayG.toStringAsFixed(2)}, ${imu.azG.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ] else
              const Text('Esperando datos...'),
          ],
        ),
      ),
    );
  }

  Widget _imuRow(String label, int x, int y, int z) {
    return Text('$label: $x, $y, $z', style: const TextStyle(fontFamily: 'monospace'));
  }
}

class _StepsCard extends StatelessWidget {
  final WatchState state;
  const _StepsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pasos', style: Theme.of(context).textTheme.titleMedium),
                Text('${state.steps}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: 'monospace')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandsCard extends StatelessWidget {
  final WatchService service;
  const _CommandsCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comandos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _cmdBtn('Hora', Icons.access_time, () => service.sendCommand(cmdShowTime)),
                _cmdBtn('IMU', Icons.sensors, () => service.sendCommand(cmdShowImu)),
                _cmdBtn('Pasos', Icons.directions_walk, () => service.sendCommand(cmdShowSteps)),
                _cmdBtn('Apagar', Icons.power_settings_new, () => service.sendCommand(cmdScreenOff)),
                _cmdBtn('Reset pasos', Icons.restart_alt, () => service.sendCommand(cmdResetSteps)),
                _cmdBtn('Sync hora', Icons.sync, () => _syncTime(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cmdBtn(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  void _syncTime(BuildContext context) {
    final now = DateTime.now();
    service.showTime(now.hour, now.minute, now.second);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hora enviada: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}')),
    );
  }
}
