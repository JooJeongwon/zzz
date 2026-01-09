package com.zzz.android.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.zzz.android.R
import com.zzz.android.data.remote.dto.HeartbeatRequest
import com.zzz.android.di.NetworkModule
import kotlinx.coroutines.*

import com.zzz.android.data.local.TokenManager

class HeartbeatService : Service() {

    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        var userId = intent?.getLongExtra("USER_ID", -1L) ?: -1L
        
        if (userId == -1L) {
            val tokenManager = TokenManager(this)
            userId = tokenManager.getUserIdSync()
        }

        if (userId == -1L) {
            Log.e("HeartbeatService", "No User ID provided. Stopping service.")
            stopSelf()
            return START_NOT_STICKY
        }

        startForeground(1, createNotification())

        serviceScope.launch {
            while (isActive) {
                try {
                    sendHeartbeat(userId)
                } catch (e: Exception) {
                    Log.e("HeartbeatService", "Error sending heartbeat", e)
                }
                delay(HEARTBEAT_INTERVAL_MS)
            }
        }

        return START_STICKY
    }

    private suspend fun sendHeartbeat(userId: Long) {
        val batteryLevel = getBatteryLevel()
        val isScreenOn = isScreenOn()
        
        Log.d("HeartbeatService", "Sending heartbeat for user $userId: Battery=$batteryLevel%, ScreenOn=$isScreenOn")
        
        try {
            val response = NetworkModule.provideUserApi(this).sendHeartbeat(
                userId = userId,
                request = HeartbeatRequest(batteryLevel, isScreenOn)
            )
            if (response.isSuccessful) {
                Log.d("HeartbeatService", "Heartbeat success")
            } else {
                Log.e("HeartbeatService", "Heartbeat failed: ${response.code()}")
            }
        } catch (e: Exception) {
            Log.e("HeartbeatService", "Heartbeat network error", e)
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun isScreenOn(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isInteractive
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Heartbeat Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ZZZ Running")
            .setContentText("Keeping your connection alive.")
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Placeholder icon
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceJob.cancel()
    }

    companion object {
        const val CHANNEL_ID = "HeartbeatChannel"
        private const val HEARTBEAT_INTERVAL_MS = 10 * 60 * 1000L // 10 minutes
    }
}
