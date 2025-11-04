package com.example.wefixit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.util.Log

/**
 * ContentProvider der VOR ALLEM ANDEREN läuft
 * Erstellt Notification Channel GARANTIERT vor jedem Receiver
 */
class NotificationChannelProvider : ContentProvider() {
    
    companion object {
        private const val TAG = "NotificationChannel"
        private const val CHANNEL_ID = "maintenance_reminders"
        private const val CHANNEL_NAME = "Wartungserinnerungen"
    }
    
    override fun onCreate(): Boolean {
        Log.d(TAG, "🚀🚀🚀 ContentProvider.onCreate() - Erstelle Channel!")
        
        context?.let { ctx ->
            createNotificationChannel(ctx)
        }
        
        return true
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
            
            Log.d(TAG, "🔔🔔🔔 Notification Channel erstellt: $CHANNEL_ID")
        }
    }
    
    // Unused but required
    override fun query(uri: Uri, projection: Array<String>?, selection: String?, selectionArgs: Array<String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<String>?): Int = 0
}
