import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

class NotificationHandler extends ChangeNotifier {
  static const _channel = MethodChannel('smartcatch_notifications');

  final _notifController = StreamController<AndroidNotification>.broadcast();
  Stream<AndroidNotification> get onNotification => _notifController.stream;

  Timer? _pollTimer;
  bool _listening = false;

  bool get isListening => _listening;

  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('NotifHandler: hasPermission error: $e');
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      debugPrint('NotifHandler: openSettings error: $e');
    }
  }

  void startListening() {
    if (_listening) return;
    _listening = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notification') {
        await _fetchPending();
      }
    });

    _pollTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      _fetchPending();
    });

    notifyListeners();
  }

  void stopListening() {
    _listening = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    notifyListeners();
  }

  Future<void> _fetchPending() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getPendingNotifications');
      if (result == null) return;
      for (final item in result) {
        if (item is! Map) continue;
        final n = AndroidNotification(
          package: (item['package'] as String?) ?? '',
          title: (item['title'] as String?) ?? '',
          text: (item['text'] as String?) ?? '',
          category: (item['category'] as String?) ?? '',
        );
        if (n.title.isEmpty && n.text.isEmpty) continue;
        if (n.package == 'com.smartcatch.smartcatch_app') continue;
        debugPrint(
            'NotifHandler: received pkg=${n.package} title=${n.title}');
        _notifController.add(n);
      }
    } catch (e) {
      debugPrint('NotifHandler: poll error: $e');
    }
  }

  String formatForWatch(AndroidNotification n) {
    final text = n.text;
    if (n.package == 'com.android.dialer' ||
        n.package == 'com.android.incallui' ||
        n.package == 'com.google.android.dialer') {
      return n.title.isNotEmpty ? n.title : text;
    }
    return text;
  }

  @override
  void dispose() {
    _notifController.close();
    stopListening();
    super.dispose();
  }
}
