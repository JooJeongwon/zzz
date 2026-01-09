package com.zzz.android.data.remote.dto

import com.google.gson.annotations.SerializedName

data class UserRegisterRequest(
    @SerializedName("email") val email: String,
    @SerializedName("password") val password: String,
    @SerializedName("nickname") val nickname: String
)
