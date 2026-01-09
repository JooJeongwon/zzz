package com.zzz.core.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CoupleConnectRequest {
    @NotBlank(message = "Code is required")
    private String code;
}
