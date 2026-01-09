package com.zzz.app.service

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
import com.zzz.app.network.HeartbeatClient
import kotlinx.coroutines.*

class HeartbeatService : Service() {

    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    private lateinit var tokenManager: NativeTokenManager
    private val heartbeatClient = HeartbeatClient()

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        tokenManager = NativeTokenManager(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 1. Intent로 전달받거나, 없으면 SharedPreferences에서 복구
        var userId = intent?.getLongExtra("USER_ID", -1L) ?: -1L
        
        if (userId == -1L) {
            userId = tokenManager.getUserId()
        }

        if (userId == -1L) {
            Log.e("HeartbeatService", "No User ID found. Stopping service.")
            stopSelf()
            return START_NOT_STICKY
        }

        startForeground(1, createNotification())

        serviceScope.launch {
            while (isActive) {
                try {
                    performHeartbeat(userId)
                } catch (e: Exception) {
                    Log.e("HeartbeatService", "Error in heartbeat loop", e)
                }
                delay(HEARTBEAT_INTERVAL_MS)
            }
        }

        return START_STICKY
    }

    private fun performHeartbeat(userId: Long) {
        val batteryLevel = getBatteryLevel()
        val isScreenOn = isScreenOn()
        val authToken = tokenManager.getAuthToken()

        Log.d("HeartbeatService", "Processing heartbeat: User=$userId, Bat=$batteryLevel, Screen=$isScreenOn")
        
        heartbeatClient.sendHeartbeat(authToken, batteryLevel, isScreenOn)
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
                "ZZZ Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        // 아이콘은 시스템 기본 아이콘 사용 (추후 mipmap/ic_launcher 등으로 변경 가능)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ZZZ")
            .setContentText("연결 유지 중...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
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