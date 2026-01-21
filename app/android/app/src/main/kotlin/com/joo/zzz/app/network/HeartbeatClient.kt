package com.joo.zzz.app.network

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

    fun sendHeartbeat(authToken: String?, batteryLevel: Int, isScreenOn: Boolean, timestamp: Long = System.currentTimeMillis()): Int {
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
                    put("timestamp", timestamp)
                }

                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(jsonBody.toString())
                }

                val code = responseCode
                if (code == 200) {
                    Log.d("HeartbeatClient", "Heartbeat success")
                } else {
                    Log.e("HeartbeatClient", "Heartbeat failed: $code")
                }
                code
            }
        } catch (e: Exception) {
            Log.e("HeartbeatClient", "Network error", e)
            -1
        }
    }

    fun sendHeartbeatBatch(authToken: String?, heartbeats: List<Map<String, Any>>): Int {
        val url = URL("$API_BASE_URL/api/v1/users/heartbeat/batch")
        
        return try {
            with(url.openConnection() as HttpURLConnection) {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                if (authToken != null) {
                    setRequestProperty("Authorization", "Bearer $authToken")
                }

                val jsonHeartbeats = org.json.JSONArray()
                heartbeats.forEach { 
                    jsonHeartbeats.put(JSONObject().apply {
                        put("timestamp", it["timestamp"])
                        put("batteryLevel", it["batteryLevel"])
                        put("isScreenOn", it["isScreenOn"])
                    })
                }

                val jsonBody = JSONObject().apply {
                    put("heartbeats", jsonHeartbeats)
                }

                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(jsonBody.toString())
                }

                val code = responseCode
                if (code == 200) {
                    Log.d("HeartbeatClient", "Heartbeat Batch success")
                } else {
                    Log.e("HeartbeatClient", "Heartbeat Batch failed: $code")
                }
                code
            }
        } catch (e: Exception) {
            Log.e("HeartbeatClient", "Network error in Batch", e)
            -1
        }
    }

    fun refreshAccessToken(refreshToken: String): Pair<String, String>? {
        val url = URL("$API_BASE_URL/api/v1/users/refresh")

        return try {
            with(url.openConnection() as HttpURLConnection) {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Content-Type", "application/json")

                val jsonBody = JSONObject().apply {
                    put("refreshToken", refreshToken)
                }

                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(jsonBody.toString())
                }

                if (responseCode == 200) {
                    inputStream.bufferedReader().use { reader ->
                        val responseText = reader.readText()
                        val json = JSONObject(responseText)
                        val newAccessToken = json.getString("accessToken")
                        val newRefreshToken = json.optString("refreshToken", refreshToken) // Use old one if not rotated
                        return Pair(newAccessToken, newRefreshToken)
                    }
                } else {
                    Log.e("HeartbeatClient", "Refresh failed: $responseCode")
                    null
                }
            }
        } catch (e: Exception) {
            Log.e("HeartbeatClient", "Refresh Network error", e)
            null
        }
    }
}
