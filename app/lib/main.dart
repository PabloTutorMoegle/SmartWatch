import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble/watch_service.dart';
import 'screens/scanner_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WatchService(),
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
    final connected = context.watch<WatchService>().isConnected;
    return connected ? const DashboardScreen() : const ScannerScreen();
  }
}
