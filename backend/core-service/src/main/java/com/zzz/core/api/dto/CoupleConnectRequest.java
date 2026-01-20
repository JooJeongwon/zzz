package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Schema(description = "커플 연결 요청")
public class CoupleConnectRequest {
    @NotBlank(message = "Code is required")
    @Schema(description = "초대 코드", example = "A1B2C3")
    private String code;
}
