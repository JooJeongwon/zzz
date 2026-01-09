package com.zzz.android.data.remote.dto

data class PartnerStatusResponse(
    val userId: Long,
    val nickname: String,
    val status: String,
    val lastActiveAt: String?,
    val batteryLevel: Int?
)

data class CoupleInviteResponse(
    val code: String,
    val expiresInSeconds: Long
)

data class CoupleConnectRequest(
    val code: String
)
