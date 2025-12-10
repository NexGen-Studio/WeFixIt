package com.example.wefixit

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log

/**
 * Custom Application Klasse
 * Erstellt Notification Channel beim App-Start - GARANTIERT verfügbar
 */
class WeFixItApplication : Application() {
    
    companion object {
        private const val TAG = "WeFixItApplication"
        private const val CHANNEL_ID = "maintenance_reminders"
        private const val CHANNEL_NAME = "Maintenance Reminders"  // Flutter überschreibt dies mit Locale
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🚀 WeFixIt Application starting...")
        
        // Erstelle Notification Channel SOFORT beim App-Start
        // Damit ist er IMMER verfügbar, auch für Background-Receiver
        createNotificationChannel()
        
        Log.d(TAG, "✅ WeFixIt Application initialized")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "Benachrichtigungen für anstehende Wartungen"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            Log.d(TAG, "🔔 Notification Channel erstellt: $CHANNEL_ID")
        }
    }
}
