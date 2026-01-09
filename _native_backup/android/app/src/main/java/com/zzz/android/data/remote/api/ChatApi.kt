package com.zzz.android.data.remote.api

import com.zzz.android.data.remote.dto.ChatMessageDto
import com.zzz.android.data.remote.dto.PageResponse
import com.zzz.android.data.remote.dto.SendMessageRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

interface ChatApi {
    @GET("/api/v1/chat/history")
    suspend fun getChatHistory(
        @Query("partnerId") partnerId: Long,
        @Query("page") page: Int = 0,
        @Query("size") size: Int = 20
    ): Response<PageResponse<ChatMessageDto>>

    @POST("/api/v1/chat/send")
    suspend fun sendMessage(
        @Body request: SendMessageRequest
    ): Response<ChatMessageDto>
}
