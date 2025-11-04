package com.example.wefixit

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BroadcastReceiver der VOR jedem Notification-Event den Channel erstellt
 * Überschreibt den flutter_local_notifications Receiver
 */
class ScheduledNotificationBootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "ScheduledNotification"
        private const val CHANNEL_ID = "maintenance_reminders"
        private const val CHANNEL_NAME = "Wartungserinnerungen"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📱 onReceive: action=${intent.action}, package=${intent.component?.packageName}")
        
        // IMMER den Channel erstellen, egal was passiert
        createNotificationChannel(context)
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "✅ Boot completed - Channel erstellt")
            }
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED -> {
                Log.d(TAG, "✅ Exact alarm permission changed - Channel erstellt")
            }
            else -> {
                Log.d(TAG, "✅ Channel erstellt für flutter_local_notifications broadcast")
            }
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
            
            Log.d(TAG, "🔔 Notification Channel erstellt: $CHANNEL_ID")
        }
    }
}
