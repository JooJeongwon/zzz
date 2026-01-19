package com.zzz.core.domain.notification.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationEvent implements Serializable {
    private String type; // "STATUS_CHANGE", "CHAT"
    private Long senderId;
    private Long receiverId;
    private String content; // Message content or New Status
    private Long timestamp;
}
