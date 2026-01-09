package com.zzz.core.domain.chat;

import lombok.Builder;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Data
@Builder
@Document(collection = "chats")
public class ChatMessage {
    @Id
    private String id;
    private Long senderId;
    private Long receiverId;
    private String content;
    private boolean isAiGenerated;
    private String messageType; // TEXT, RECAP
    private LocalDateTime createdAt;
}
