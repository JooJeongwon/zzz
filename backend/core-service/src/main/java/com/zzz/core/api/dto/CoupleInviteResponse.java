package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "커플 초대 코드 응답")
public class CoupleInviteResponse {
    @Schema(description = "초대 코드", example = "A1B2C3")
    private String code;
    @Schema(description = "만료 시간(초)", example = "86400")
    private Long expiresSeconds;
}
