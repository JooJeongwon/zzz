package com.zzz.core.api.dto;

import com.zzz.core.domain.user.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerStatusResponse {
    private Long userId;
    private String nickname;
    private UserStatus status;
    private LocalDateTime lastActiveAt;
    private Integer batteryLevel; // Optional
}
