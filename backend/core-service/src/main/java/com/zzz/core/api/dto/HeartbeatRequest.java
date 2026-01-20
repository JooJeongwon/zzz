package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "하트비트(생존신호) 전송 요청")
public class HeartbeatRequest {
    @Schema(description = "배터리 잔량(%)", example = "85")
    private Integer batteryLevel;
    @Schema(description = "화면 켜짐 여부", example = "true")
    private Boolean isScreenOn;
    @Schema(description = "데이터 생성 시간(Epoch millis)", example = "1705647000000")
    private Long timestamp;
}
