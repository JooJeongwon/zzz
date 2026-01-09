package com.zzz.core.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoupleInviteResponse {
    private String code;
    private Long expiresSeconds;
}
