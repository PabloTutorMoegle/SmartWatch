package com.smartcatch.smartcatch_app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.concurrent.ConcurrentLinkedQueue

class NotifListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getString("android.text")
            ?: extras.getString("android.bigText") ?: ""
        val packageName = sbn.packageName
        val category = extras.getString("android.category") ?: ""

        if (packageName == "com.smartcatch.smartcatch_app") return
        Log.d(TAG, "notification: $packageName title=$title")
        if (title.isEmpty() && text.isEmpty()) return

        pendingNotifications.add(
            mapOf(
                "package" to packageName,
                "title" to title,
                "text" to text,
                "category" to category,
            )
        )

        Handler(Looper.getMainLooper()).post {
            NotifBridge.channel?.invokeMethod("notification", null)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}

    companion object {
        private const val TAG = "NotifListener"

        private val pendingNotifications = ConcurrentLinkedQueue<Map<String, String>>()

        @JvmStatic
        fun getPendingNotifications(): List<Map<String, String>> {
            val list = mutableListOf<Map<String, String>>()
            while (true) {
                pendingNotifications.poll()?.let { list.add(it) } ?: break
            }
            return list
        }

        @JvmStatic
        fun hasPermission(context: Context): Boolean {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                ENABLED_NOTIFICATION_LISTENERS
            )
            if (!flat.isNullOrEmpty()) {
                for (name in flat.split(":")) {
                    val cn = ComponentName.unflattenFromString(name)
                    if (context.packageName == cn?.packageName) return true
                }
            }
            return false
        }

        @JvmStatic
        fun openSettings(context: Context) {
            context.startActivity(
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }

        private const val ENABLED_NOTIFICATION_LISTENERS =
            "enabled_notification_listeners"
    }
}
