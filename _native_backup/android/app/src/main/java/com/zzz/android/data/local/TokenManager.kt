package com.zzz.android.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.onStart

class TokenManager(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "auth_prefs_secure",
        masterKey,
        EncryptedSharedPreferences.PrefKey.EncryptedSharedPreferencesPrefKey.AES256_SIV,
        EncryptedSharedPreferences.PrefValue.EncryptedSharedPreferencesPrefValue.AES256_GCM
    )

    companion object {
        private const val ACCESS_TOKEN_KEY = "access_token"
        private const val USER_ID_KEY = "user_id"
    }

    val accessToken: Flow<String?> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
            if (key == ACCESS_TOKEN_KEY) {
                trySend(prefs.getString(ACCESS_TOKEN_KEY, null))
            }
        }
        sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
        awaitClose { sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener) }
    }.onStart {
        emit(sharedPreferences.getString(ACCESS_TOKEN_KEY, null))
    }

    val userId: Flow<Long?> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
            if (key == USER_ID_KEY) {
                val value = prefs.getLong(USER_ID_KEY, -1L)
                trySend(if (value != -1L) value else null)
            }
        }
        sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
        awaitClose { sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener) }
    }.onStart {
        val value = sharedPreferences.getLong(USER_ID_KEY, -1L)
        emit(if (value != -1L) value else null)
    }

    fun getAccessTokenSync(): String? {
        return sharedPreferences.getString(ACCESS_TOKEN_KEY, null)
    }

    fun getUserIdSync(): Long {
        return sharedPreferences.getLong(USER_ID_KEY, -1L)
    }

    fun saveToken(token: String, userId: Long) {
        sharedPreferences.edit()
            .putString(ACCESS_TOKEN_KEY, token)
            .putLong(USER_ID_KEY, userId)
            .apply()
    }

    fun clearToken() {
        sharedPreferences.edit()
            .remove(ACCESS_TOKEN_KEY)
            .remove(USER_ID_KEY)
            .apply()
    }
}