package com.zzz.core.domain.ai.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIResponseEvent {
    private String originalRequestId;
    private String userId;
    private String partnerId;
    private String content;
    private String type;
}
