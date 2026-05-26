import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ble/watch_service.dart';
import '../ble/watch_constants.dart';
import '../models/watch_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _lastNotifTitle = '';
  String _lastNotifText = '';
  bool _notifPerm = false;

  @override
  void initState() {
    super.initState();
    final svc = context.read<WatchService>();

    svc.notifHandler.hasPermission().then((p) {
      if (mounted) setState(() => _notifPerm = p);
    });

    svc.notifHandler.onNotification.listen((n) {
      if (mounted) {
        setState(() {
          _lastNotifTitle = n.title;
          _lastNotifText = n.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notif: ${n.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

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
                _NotifStatusCard(
                  listening: service.notifHandler.isListening,
                  hasPermission: _notifPerm,
                  lastTitle: _lastNotifTitle,
                  lastText: _lastNotifText,
                ),
                const SizedBox(height: 12),
                _TimeCard(state: state),
                const SizedBox(height: 12),
                _ImuCard(state: state),
                const SizedBox(height: 12),
                _StepsCard(state: state),
                const SizedBox(height: 12),
                _CommandsCard(service: service),
                const SizedBox(height: 12),
                _NotifDebugCard(debug: service.notifDebug),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifStatusCard extends StatelessWidget {
  final bool listening;
  final bool hasPermission;
  final String lastTitle;
  final String lastText;

  const _NotifStatusCard({
    required this.listening,
    required this.hasPermission,
    required this.lastTitle,
    required this.lastText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = listening && hasPermission;
    final color = active ? Colors.green : (listening ? Colors.orange : Colors.red);
    final label = active ? 'Activo' : (listening ? 'Sin permiso' : 'Inactivo');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.notifications_active : Icons.notifications_off,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Notificaciones', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
            if (lastTitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text('Última:', style: theme.textTheme.labelSmall),
              Text(lastTitle, style: theme.textTheme.bodyMedium),
              if (lastText.isNotEmpty)
                Text(lastText, style: theme.textTheme.bodySmall),
            ],
            if (!active) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.settings, size: 16),
                  label: Text(listening ? 'Conceder permiso' : 'Abrir ajustes notificaciones'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    context.read<WatchService>().notifHandler.openSettings();
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
                _cmdBtn('Test notif', Icons.notifications, () {
                  service.sendTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test notification sent'), duration: Duration(seconds: 1)),
                  );
                }),
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

class _NotifDebugCard extends StatelessWidget {
  final NotificationDebugInfo? debug;

  const _NotifDebugCard({required this.debug});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (debug == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.bug_report, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Notificaciones debug', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text('Esperando...', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final statusColor = debug!.status == 'enviado'
        ? Colors.green
        : debug!.status == 'error'
            ? Colors.red
            : Colors.orange;
    final statusIcon = debug!.status == 'enviado'
        ? Icons.check_circle
        : debug!.status == 'error'
            ? Icons.error
            : Icons.hourglass_top;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, size: 20, color: Colors.cyan),
                const SizedBox(width: 8),
                Text('Notificación debug', style: theme.textTheme.titleSmall),
                const Spacer(),
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 4),
                Text(debug!.status, style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
            const Divider(height: 12),
            _debugRow('App', debug!.appName),
            _debugRow('Preview', debug!.preview),
            _debugRow('Package', debug!.package),
            _debugRow('Título orig', debug!.originalTitle),
            _debugRow('Texto orig', debug!.originalText),
            _debugRow('Hora', '${debug!.timestamp.hour}:${debug!.timestamp.minute}:${debug!.timestamp.second}'),
            if (debug!.error != null) ...[
              const SizedBox(height: 4),
              Text('Error: ${debug!.error}', style: TextStyle(color: Colors.red, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
