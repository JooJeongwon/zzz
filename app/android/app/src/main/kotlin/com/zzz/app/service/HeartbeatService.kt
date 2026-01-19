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
import com.zzz.app.data.db.AppDatabase
import com.zzz.app.data.db.HeartbeatDao
import com.zzz.app.data.db.HeartbeatEntity
import com.zzz.app.network.HeartbeatClient
import kotlinx.coroutines.*

class HeartbeatService : Service() {

    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    private var heartbeatJob: Job? = null
    
    private lateinit var tokenManager: NativeTokenManager
    private val heartbeatClient = HeartbeatClient()
    private lateinit var database: AppDatabase
    private lateinit var heartbeatDao: HeartbeatDao
    
    private var currentUserId: Long = -1L

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        tokenManager = NativeTokenManager(this)
        createNotificationChannel()
        database = AppDatabase.getDatabase(this)
        heartbeatDao = database.heartbeatDao()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val intentUserId = intent?.getLongExtra("USER_ID", -1L) ?: -1L
        if (intentUserId != -1L) {
            currentUserId = intentUserId
        } else if (currentUserId == -1L) {
            currentUserId = tokenManager.getUserId()
        }

        startForeground(1, createNotification())

        if (heartbeatJob?.isActive != true) {
            heartbeatJob = serviceScope.launch {
                var backoffTime = 60 * 1000L // Start with 1 min backoff if failed

                while (isActive) {
                    if (currentUserId == -1L) {
                        currentUserId = tokenManager.getUserId()
                    }

                    if (currentUserId != -1L) {
                        try {
                            val success = performHeartbeat(currentUserId)
                            if (success) {
                                backoffTime = 60 * 1000L // Reset backoff
                                delay(HEARTBEAT_INTERVAL_MS)
                            } else {
                                Log.w("HeartbeatService", "Heartbeat critical fail. Retrying in ${backoffTime/1000}s")
                                delay(backoffTime)
                                backoffTime = (backoffTime * 2).coerceAtMost(HEARTBEAT_INTERVAL_MS)
                            }
                        } catch (e: Exception) {
                            Log.e("HeartbeatService", "Error in heartbeat loop", e)
                            delay(backoffTime)
                            backoffTime = (backoffTime * 2).coerceAtMost(HEARTBEAT_INTERVAL_MS)
                        }
                    } else {
                        Log.w("HeartbeatService", "User ID missing. Waiting...")
                        delay(60 * 1000L) 
                    }
                }
            }
        }

        return START_REDELIVER_INTENT
    }

    private suspend fun performHeartbeat(userId: Long): Boolean {
        val batteryLevel = getBatteryLevel()
        val isScreenOn = isScreenOn()
        val timestamp = System.currentTimeMillis()
        var authToken = tokenManager.getAuthToken()
        
        if (authToken == null) return false

        Log.d("HeartbeatService", "Processing heartbeat: User=$userId, Bat=$batteryLevel, Screen=$isScreenOn")
        
        // 1. Check Pending Logs
        val pendingLogs = heartbeatDao.getAll()
        val hasPending = pendingLogs.isNotEmpty()
        
        // Function to execute call
        fun executeNetworkCall(token: String): Int {
             if (hasPending) {
                val batchList = pendingLogs.map { 
                    mapOf("timestamp" to it.timestamp, "batteryLevel" to it.batteryLevel, "isScreenOn" to it.isScreenOn) 
                }.toMutableList()
                batchList.add(mapOf("timestamp" to timestamp, "batteryLevel" to batteryLevel, "isScreenOn" to isScreenOn))
                return heartbeatClient.sendHeartbeatBatch(token, batchList)
            } else {
                return heartbeatClient.sendHeartbeat(token, batteryLevel, isScreenOn, timestamp)
            }
        }
        
        try {
            var responseCode = executeNetworkCall(authToken)

            if (responseCode == 200) {
                if (hasPending) {
                    Log.d("HeartbeatService", "Batch sent successfully. Clearing logs.")
                    heartbeatDao.deleteAll()
                }
                return true
            }

            if (responseCode == 401) {
                Log.d("HeartbeatService", "Token expired (401). Attempting refresh...")
                val refreshToken = tokenManager.getRefreshToken()
                if (refreshToken != null) {
                    val newTokens = heartbeatClient.refreshAccessToken(refreshToken)
                    if (newTokens != null) {
                        Log.d("HeartbeatService", "Token refresh success. Retrying heartbeat.")
                        tokenManager.saveTokens(newTokens.first, newTokens.second)
                        authToken = newTokens.first
                        // Retry
                        val retryCode = executeNetworkCall(authToken)
                        if (retryCode == 200) {
                            if (hasPending) heartbeatDao.deleteAll()
                            return true
                        }
                    } else {
                        Log.e("HeartbeatService", "Token refresh failed.")
                    }
                } else {
                    Log.e("HeartbeatService", "No refresh token available.")
                }
            }
            
            // If we reached here, network call failed (non-200 or failed refresh)
            // Save current to DB
            Log.w("HeartbeatService", "Network/Auth failed ($responseCode). Saving to local DB.")
            heartbeatDao.insert(HeartbeatEntity(
                timestamp = timestamp,
                batteryLevel = batteryLevel,
                isScreenOn = isScreenOn
            ))
            return true // Treat as handled (offline mode) to wait full interval
            
        } catch (e: Exception) {
            Log.e("HeartbeatService", "Exception during heartbeat", e)
            // Save to DB on Exception too
            heartbeatDao.insert(HeartbeatEntity(
                timestamp = timestamp,
                batteryLevel = batteryLevel,
                isScreenOn = isScreenOn
            ))
            return true
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