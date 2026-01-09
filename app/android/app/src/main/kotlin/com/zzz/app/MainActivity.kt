package com.zzz.app

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.zzz.app.service.HeartbeatService

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.joo.zzz.app/heartbeat"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startHeartbeat") {
                val userId = call.argument<Int>("userId")?.toLong() ?: -1L
                startHeartbeatService(userId)
                result.success("Service Started")
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startHeartbeatService(userId: Long) {
        val intent = Intent(this, HeartbeatService::class.java).apply {
            putExtra("USER_ID", userId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}