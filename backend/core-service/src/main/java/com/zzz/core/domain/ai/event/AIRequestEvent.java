package com.zzz.core.domain.ai.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIRequestEvent {
    private String requestId;
    private String userId;
    private String partnerId;
    private String partnerName;
    private String content;
    private String type;
}
