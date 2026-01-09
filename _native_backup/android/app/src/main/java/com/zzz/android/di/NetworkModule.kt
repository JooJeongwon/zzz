package com.zzz.android.di

import android.content.Context
import com.zzz.android.data.local.TokenManager
import com.zzz.android.data.remote.AuthInterceptor
import com.zzz.android.data.remote.api.UserApi
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

import com.zzz.android.data.remote.api.CoupleApi
import com.zzz.android.data.remote.api.ChatApi

object NetworkModule {
    // Emulator uses 10.0.2.2 to access host localhost
    private const val BASE_URL = "http://10.0.2.2:8080/api/v1/" // Corrected base URL to include api/v1 if not handled in interfaces? 
    // Wait, the previous file had "http://10.0.2.2:8080/". Interfaces likely have "api/v1/..." or just relative.
    // Let's check UserApi/CoupleApi or just stick to existing convention.
    // Existing: private const val BASE_URL = "http://10.0.2.2:8080/"
    // I should respect that.

    private const val BASE_URL = "http://10.0.2.2:8080/"
    
    @Volatile
    private var userApiInstance: UserApi? = null

    @Volatile
    private var coupleApiInstance: CoupleApi? = null

    @Volatile
    private var chatApiInstance: ChatApi? = null

    fun provideUserApi(context: Context): UserApi {
        return userApiInstance ?: synchronized(this) {
            userApiInstance ?: buildApi(context, UserApi::class.java).also { userApiInstance = it }
        }
    }

    fun provideCoupleApi(context: Context): CoupleApi {
        return coupleApiInstance ?: synchronized(this) {
            coupleApiInstance ?: buildApi(context, CoupleApi::class.java).also { coupleApiInstance = it }
        }
    }

    fun provideChatApi(context: Context): ChatApi {
        return chatApiInstance ?: synchronized(this) {
            chatApiInstance ?: buildApi(context, ChatApi::class.java).also { chatApiInstance = it }
        }
    }

    private fun <T> buildApi(context: Context, apiClass: Class<T>): T {
        val tokenManager = TokenManager(context)
        val authInterceptor = AuthInterceptor(tokenManager)

        val client = OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()

        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(apiClass)
    }
}
