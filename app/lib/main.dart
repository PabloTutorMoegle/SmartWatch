import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble/watch_service.dart';
import 'screens/scanner_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => WatchService()..init(),
      child: const SmartCatchApp(),
    ),
  );
}

class SmartCatchApp extends StatelessWidget {
  const SmartCatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<WatchService>();
    final state = svc.state;
    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return state.connected ? const DashboardScreen() : const ScannerScreen();
  }
}
