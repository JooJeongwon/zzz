package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "인증 토큰 응답")
public class TokenResponse {
    @Schema(description = "액세스 토큰", example = "eyJh...abc")
    private String accessToken;
    @Schema(description = "리프레시 토큰", example = "eyJh...xyz")
    private String refreshToken;
    @Schema(description = "유저 ID", example = "1")
    private Long userId;
}
