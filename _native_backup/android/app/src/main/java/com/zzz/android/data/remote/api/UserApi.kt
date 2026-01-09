package com.zzz.android.data.remote.api

import com.zzz.android.data.remote.dto.HeartbeatRequest
import com.zzz.android.data.remote.dto.TokenResponse
import com.zzz.android.data.remote.dto.UserLoginRequest
import com.zzz.android.data.remote.dto.UserRegisterRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.Header
import retrofit2.http.POST

interface UserApi {

    @POST("/api/v1/users/register")
    suspend fun register(@Body request: UserRegisterRequest): Response<Void>

    @POST("/api/v1/users/login")
    suspend fun login(@Body request: UserLoginRequest): Response<TokenResponse>

    @POST("/api/v1/users/heartbeat")
    suspend fun sendHeartbeat(
        @Header("X-User-Id") userId: Long,
        @Body request: HeartbeatRequest
    ): Response<Void>

    @POST("/api/v1/users/status")
    suspend fun updateStatus(
        @Body request: UserStatusUpdateRequest
    ): Response<Void>
}
