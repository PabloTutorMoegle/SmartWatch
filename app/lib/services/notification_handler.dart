import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

class AndroidNotification {
  final String package;
  final String title;
  final String text;
  final String category;

  AndroidNotification({
    required this.package,
    required this.title,
    required this.text,
    required this.category,
  });
}

enum NotifType { chat, call, email, other }

class NotificationHandler extends ChangeNotifier {
  final _notifController = StreamController<AndroidNotification>.broadcast();
  Stream<AndroidNotification> get onNotification => _notifController.stream;

  StreamSubscription<dynamic>? _portSub;
  bool _listening = false;

  bool get isListening => _listening;

  Future<bool> hasPermission() async {
    final result = await NotificationsListener.hasPermission;
    return result ?? false;
  }

  Future<void> openSettings() async {
    await NotificationsListener.openPermissionSettings();
  }

  Future<bool> _initPlugin() async {
    try {
      await NotificationsListener.initialize();
      return true;
    } catch (e) {
      debugPrint('NotifListener init error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (_listening) return;

    await _initPlugin();

    final hasPerm = await hasPermission();
    debugPrint('NotificationHandler: hasPermission=$hasPerm');

    final port = NotificationsListener.receivePort;
    debugPrint('NotificationHandler: receivePort=$port');
    if (port == null) return;

    _portSub?.cancel();
    _portSub = port.listen((event) {
      debugPrint('NotificationHandler: raw event=$event');
      if (event is NotificationEvent) {
        final pkg = event.packageName ?? '';
        final title = event.title ?? '';
        final text = event.text ?? '';
        final raw = event.raw;
        final category = raw is Map ? (raw['category'] as String? ?? '') : '';

        debugPrint('NotificationHandler: pkg=$pkg title=$title text=$text category=$category');

        if (title.isEmpty && text.isEmpty) return;

        _notifController.add(AndroidNotification(
          package: pkg,
          title: title,
          text: text,
          category: category,
        ));
      } else {
        debugPrint('NotificationHandler: unexpected event type=${event.runtimeType}');
      }
    });

    _listening = true;
    debugPrint('NotificationHandler: listening started');
  }

  Future<void> stopListening() async {
    await _portSub?.cancel();
    _portSub = null;
    _listening = false;
  }

  static bool isCall(AndroidNotification n) {
    return n.package == 'com.android.dialer' ||
        n.package == 'com.android.incallui' ||
        n.package == 'com.google.android.dialer';
  }

  static bool isChat(AndroidNotification n) {
    return n.category == 'msg' || n.category == 'chat' || n.category == 'email';
  }

  NotifType classify(AndroidNotification n) {
    if (isCall(n)) return NotifType.call;
    if (isChat(n)) return NotifType.chat;
    return NotifType.other;
  }

  String formatForWatch(AndroidNotification n) {
    final t = classify(n);
    switch (t) {
      case NotifType.call:
        return n.title.isNotEmpty ? n.title : n.text;
      case NotifType.chat:
      case NotifType.email:
      case NotifType.other:
        return n.text;
    }
  }

  @override
  void dispose() {
    _notifController.close();
    stopListening();
    super.dispose();
  }
}
