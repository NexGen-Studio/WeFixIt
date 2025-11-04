package com.example.wefixit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Custom BroadcastReceiver für flutter_local_notifications
 * Erstellt Channel VOR jeder Notification-Anzeige
 */
class CustomScheduledNotificationReceiver : com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver() {
    
    companion object {
        private const val TAG = "CustomScheduledNotif"
        private const val CHANNEL_ID = "maintenance_reminders"
        private const val CHANNEL_NAME = "Wartungserinnerungen"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📱📱📱 CustomScheduledNotificationReceiver.onReceive CALLED!")
        Log.d(TAG, "Intent action: ${intent.action}")
        Log.d(TAG, "Intent extras: ${intent.extras}")
        
        // Erstelle Channel IMMER vor der Notification
        createNotificationChannel(context)
        Log.d(TAG, "🔔🔔🔔 Channel erstellt!")
        
        // Rufe die Original-Implementation auf
        super.onReceive(context, intent)
        
        Log.d(TAG, "✅✅✅ Super.onReceive completed - Notification sollte angezeigt werden!")
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
