package com.smartcatch.smartcatch_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smartcatch_notifications"
        )
        NotifBridge.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> {
                    result.success(NotifListenerService.hasPermission(this))
                }
                "openSettings" -> {
                    NotifListenerService.openSettings(this)
                    result.success(true)
                }
                "getPendingNotifications" -> {
                    result.success(NotifListenerService.getPendingNotifications())
                }
                else -> result.notImplemented()
            }
        }
    }
}
