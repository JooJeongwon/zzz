package com.zzz.app.network

import android.util.Log
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class HeartbeatClient {

    companion object {
        // TODO: Build Variant 또는 gradle.properties로 분리 권장
        private const val API_BASE_URL = "http://10.0.2.2:8080"
    }

    fun sendHeartbeat(authToken: String?, batteryLevel: Int, isScreenOn: Boolean): Boolean {
        val url = URL("$API_BASE_URL/api/v1/users/heartbeat")
        
        return try {
            with(url.openConnection() as HttpURLConnection) {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                if (authToken != null) {
                    setRequestProperty("Authorization", "Bearer $authToken")
                }

                val jsonBody = JSONObject().apply {
                    put("batteryLevel", batteryLevel)
                    put("isScreenOn", isScreenOn)
                }

                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(jsonBody.toString())
                }

                val code = responseCode
                if (code == 200) {
                    Log.d("HeartbeatClient", "Heartbeat success")
                    true
                } else {
                    Log.e("HeartbeatClient", "Heartbeat failed: $code")
                    false
                }
            }
        } catch (e: Exception) {
            Log.e("HeartbeatClient", "Network error", e)
            false
        }
    }
}
