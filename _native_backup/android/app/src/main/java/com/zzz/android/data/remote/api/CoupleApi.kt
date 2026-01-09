package com.zzz.android.data.remote.api

import com.zzz.android.data.remote.dto.CoupleConnectRequest
import com.zzz.android.data.remote.dto.CoupleInviteResponse
import com.zzz.android.data.remote.dto.PartnerStatusResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

interface CoupleApi {
    @POST("api/v1/couples/invite")
    suspend fun createInvite(): Response<CoupleInviteResponse>

    @POST("api/v1/couples/connect")
    suspend fun connectCouple(@Body request: CoupleConnectRequest): Response<Void>

    @GET("api/v1/couples/partner-status")
    suspend fun getPartnerStatus(): Response<PartnerStatusResponse>
}
