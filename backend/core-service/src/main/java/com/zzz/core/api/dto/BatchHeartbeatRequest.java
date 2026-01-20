package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "오프라인 동안 쌓인 하트비트 데이터 일괄 전송 요청")
public class BatchHeartbeatRequest {
    @Schema(description = "하트비트 리스트")
    private List<HeartbeatRequest> heartbeats;
}
