package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "상태 변경 요청")
public class UserStatusUpdateRequest {
    @Schema(description = "변경할 상태 (ONLINE, SLEEP, STUDY, BUSY)", example = "SLEEP")
    private String status; // ONLINE, SLEEP, STUDY, BUSY
}
