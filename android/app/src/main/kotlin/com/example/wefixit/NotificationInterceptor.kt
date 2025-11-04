package com.example.wefixit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Interceptor der VOR flutter_local_notifications läuft
 * Erstellt Channel und leitet Intent weiter
 */
class NotificationInterceptor : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "NotifInterceptor"
        private const val CHANNEL_ID = "maintenance_reminders"
        private const val CHANNEL_NAME = "Wartungserinnerungen"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "🚨🚨🚨 INTERCEPTOR onReceive!")
        Log.d(TAG, "Action: ${intent.action}")
        Log.d(TAG, "Component: ${intent.component}")
        Log.d(TAG, "Extras: ${intent.extras}")
        
        // Erstelle Channel IMMER
        createNotificationChannel(context)
        
        // Leite Intent an flutter_local_notifications weiter
        val forwardIntent = Intent(intent).apply {
            component = android.content.ComponentName(
                "com.example.wefixit",
                "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            )
        }
        
        try {
            context.sendBroadcast(forwardIntent)
            Log.d(TAG, "✅ Intent weitergeleitet an flutter_local_notifications")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Fehler beim Weiterleiten: $e")
            
            // Fallback: Zeige Notification selbst
            showNotificationFallback(context, intent)
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
            
            Log.d(TAG, "🔔🔔🔔 Channel erstellt: $CHANNEL_ID")
        }
    }
    
    private fun showNotificationFallback(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val title = intent.getStringExtra("title") ?: "🔧 Wartung fällig"
                val body = intent.getStringExtra("body") ?: "Eine Wartung steht an"
                val notificationId = intent.getIntExtra("notification_id", 0)
                
                val notification = android.app.Notification.Builder(context, CHANNEL_ID)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setAutoCancel(true)
                    .build()
                
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(notificationId, notification)
                
                Log.d(TAG, "🚨 FALLBACK Notification angezeigt!")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Fallback fehlgeschlagen: $e")
            }
        }
    }
}
