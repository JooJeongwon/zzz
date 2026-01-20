package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@Schema(description = "FCM 토큰 갱신 요청")
public class FcmTokenUpdateRequest {
    @Schema(description = "FCM 디바이스 토큰", example = "d_k3l...123")
    private String fcmToken;
}
