package com.zzz.core.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HeartbeatRequest {
    private Integer batteryLevel;
    private Boolean isScreenOn;
}
