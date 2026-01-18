package com.zzz.app.service

import android.content.Context
import android.content.SharedPreferences

class NativeTokenManager(context: Context) {
    // Flutter의 SharedPreferences 플러그인은 기본적으로 "FlutterSharedPreferences"라는 이름의 XML을 사용합니다.
    private val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    companion object {
        // Flutter shared_preferences 패키지는 키 앞에 "flutter." 접두사를 붙여서 저장합니다.
        private const val KEY_USER_ID = "flutter.user_id"
        private const val KEY_AUTH_TOKEN = "flutter.accessToken"
        private const val KEY_REFRESH_TOKEN = "flutter.refreshToken"
    }

    fun getUserId(): Long {
        // Flutter에서 정수를 저장할 때 Int로 저장될 수도 있고 Long으로 저장될 수도 있으므로 안전하게 처리합니다.
        return if (prefs.contains(KEY_USER_ID)) {
            try {
                prefs.getLong(KEY_USER_ID, -1L)
            } catch (e: ClassCastException) {
                // 만약 Int로 저장되었다면 catch해서 처리
                prefs.getInt(KEY_USER_ID, -1).toLong()
            }
        } else {
            -1L
        }
    }

    fun getAuthToken(): String? {
        return prefs.getString(KEY_AUTH_TOKEN, null)
    }

    fun getRefreshToken(): String? {
        return prefs.getString(KEY_REFRESH_TOKEN, null)
    }

    fun saveTokens(accessToken: String, refreshToken: String?) {
        val editor = prefs.edit()
        editor.putString(KEY_AUTH_TOKEN, accessToken)
        if (refreshToken != null) {
            editor.putString(KEY_REFRESH_TOKEN, refreshToken)
        }
        editor.apply()
    }
}
