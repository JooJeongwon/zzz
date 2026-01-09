package com.zzz.android.data.remote.dto

import com.google.gson.annotations.SerializedName

data class ChatMessageDto(
    val id: String,
    val senderId: Long,
    val receiverId: Long,
    val content: String,
    @SerializedName("aiGenerated") val isAiGenerated: Boolean,
    val createdAt: String
)

data class SendMessageRequest(
    val receiverId: Long,
    val content: String
)

data class PageResponse<T>(
    val content: List<T>,
    val totalElements: Long,
    val totalPages: Int,
    val last: Boolean,
    val size: Int,
    val number: Int
)
