package com.example.wefixit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.wefixit/notifications"
    private val NAV_CHANNEL = "com.example.wefixit/navigation"
    companion object {
        private var pendingRoute: String? = null
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        
        // Prüfe Intent beim App-Start (z.B. durch Notification-Click)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        intent?.getStringExtra("open_route")?.let { route ->
            Log.d("MainActivity", "📱 Handling intent with route: $route")
            if (!sendRouteToFlutter(route)) {
                Log.w("MainActivity", "⚠️ FlutterEngine not ready yet - caching route")
                pendingRoute = route
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNotification" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val scheduledTime = call.argument<Long>("scheduledTime") ?: 0L
                        
                        RobustNotificationScheduler.scheduleNotification(
                            this,
                            id,
                            title,
                            body,
                            scheduledTime
                        )
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to schedule notification: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        pendingRoute?.let { route ->
            if (sendRouteToFlutter(route)) {
                Log.d("MainActivity", "✅ Delivered pending route to Flutter: $route")
                pendingRoute = null
            }
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "maintenance_reminders"
            val channelName = "Wartungserinnerungen"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Benachrichtigungen für anstehende Wartungen"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun sendRouteToFlutter(route: String): Boolean {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return false
        MethodChannel(messenger, NAV_CHANNEL).invokeMethod("navigate", route)
        Log.d("MainActivity", "✅ Route sent to Flutter: $route")
        return true
    }
}
