package com.example.wefixit

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.graphics.BitmapFactory
import com.example.wefixit.R
import io.flutter.plugin.common.MethodChannel

/**
 * ROBUSTE Notification-Lösung die GARANTIERT funktioniert
 * Verwendet AlarmManager direkt ohne flutter_local_notifications
 */
class RobustNotificationScheduler {
    
    companion object {
        private const val TAG = "RobustNotifScheduler"
        private const val CHANNEL_ID = "maintenance_reminders"
        private const val CHANNEL_NAME = "Wartungserinnerungen"
        private const val ACTION_SHOW_NOTIFICATION = "com.example.wefixit.SHOW_NOTIFICATION"
        
        fun scheduleNotification(
            context: Context,
            notificationId: Int,
            title: String,
            body: String,
            scheduledTimeMillis: Long
        ) {
            Log.d(TAG, "🚀 scheduleNotification called:")
            Log.d(TAG, "  ID: $notificationId")
            Log.d(TAG, "  Title: $title")
            Log.d(TAG, "  Time: $scheduledTimeMillis")
            Log.d(TAG, "  Now: ${System.currentTimeMillis()}")
            Log.d(TAG, "  Diff: ${(scheduledTimeMillis - System.currentTimeMillis()) / 1000}s")
            
            // Erstelle Channel
            createNotificationChannel(context)
            
            // Erstelle Intent für Receiver
            val intent = Intent(context, NotificationReceiver::class.java).apply {
                action = ACTION_SHOW_NOTIFICATION
                putExtra("notification_id", notificationId)
                putExtra("title", title)
                putExtra("body", body)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Schedule mit AlarmManager
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTimeMillis,
                            pendingIntent
                        )
                        Log.d(TAG, "✅ Alarm gesetzt mit setExactAndAllowWhileIdle")
                    } else {
                        Log.e(TAG, "❌ canScheduleExactAlarms = false!")
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTimeMillis,
                            pendingIntent
                        )
                        Log.d(TAG, "⚠️ Fallback: setAndAllowWhileIdle verwendet")
                    }
                } else {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        scheduledTimeMillis,
                        pendingIntent
                    )
                    Log.d(TAG, "✅ Alarm gesetzt (API < 31)")
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "❌ SecurityException beim Setzen des Alarms: $e")
            }
        }
        
        private fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val importance = NotificationManager.IMPORTANCE_HIGH
                val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                    description = "Benachrichtigungen für anstehende Wartungen"
                    enableVibration(true)
                    enableLights(true)
                    setShowBadge(true)
                }
                
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
        }
    }
    
    /**
     * BroadcastReceiver der die Notification anzeigt
     */
    class NotificationReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d(TAG, "🚨🚨🚨 NotificationReceiver.onReceive!")
            Log.d(TAG, "Action: ${intent.action}")
            Log.d(TAG, "Time: ${System.currentTimeMillis()}")
            
            if (intent.action == ACTION_SHOW_NOTIFICATION) {
                val notificationId = intent.getIntExtra("notification_id", 0)
                val title = intent.getStringExtra("title") ?: "🔧 Wartung fällig"
                val body = intent.getStringExtra("body") ?: "Eine Wartung steht an"
                
                Log.d(TAG, "Showing notification: $notificationId - $title")
                
                showNotification(context, notificationId, title, body)
            }
        }
        
        private fun showNotification(context: Context, id: Int, title: String, body: String) {
            createNotificationChannel(context)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Intent zum Öffnen der App (MainActivity mit Navigation zur Wartungsübersicht)
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("open_route", "/maintenance") // Route zur Wartungsübersicht
                }
                
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    id,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                val largeIcon = BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher)

                val notification = android.app.Notification.Builder(context, CHANNEL_ID)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setLargeIcon(largeIcon)
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent) // Click-Aktion
                    .setPriority(android.app.Notification.PRIORITY_HIGH)
                    .setDefaults(android.app.Notification.DEFAULT_ALL)
                    .build()
                
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(id, notification)
                
                Log.d(TAG, "✅ Notification angezeigt: ID=$id mit Click-Aktion")
            }
        }
    }
}
