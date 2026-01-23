package com.zzz.core.domain.chat.event;

import com.zzz.core.domain.ai.event.AIEventPublisher;
import com.zzz.core.domain.ai.event.AIRequestEvent;
import com.zzz.core.domain.notification.event.NotificationEvent;
import com.zzz.core.domain.notification.event.NotificationEventPublisher;
import com.zzz.core.domain.user.UserStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class ChatEventListener {

    private final AIEventPublisher aiEventPublisher;
    private final NotificationEventPublisher notificationEventPublisher;

    @Async
    @EventListener
    public void handleMessageSent(MessageSentEvent event) {
        // 1. Send Notification
        publishChatNotification(event);

        // 2. Trigger AI if needed
        if (isUserUnavailable(event.getReceiverStatus())) {
            triggerAutoReply(event);
        }
    }

    private boolean isUserUnavailable(UserStatus status) {
        return status == UserStatus.SLEEP || status == UserStatus.STUDY || status == UserStatus.BUSY;
    }

    private void publishChatNotification(MessageSentEvent event) {
        NotificationEvent notif = NotificationEvent.builder()
                .type("CHAT")
                .senderId(event.getSenderId())
                .receiverId(event.getReceiverId())
                .content(event.getContent())
                .timestamp(System.currentTimeMillis())
                .build();
        notificationEventPublisher.publish(notif);
    }

    private void triggerAutoReply(MessageSentEvent event) {
        log.info("User {} is {}, publishing AI Chat request...", event.getReceiverId(), event.getReceiverStatus());
        try {
            AIRequestEvent aiEvent = AIRequestEvent.builder()
                    .requestId(UUID.randomUUID().toString())
                    .userId(String.valueOf(event.getSenderId()))
                    .partnerId(String.valueOf(event.getReceiverId()))
                    .partnerName(event.getReceiverNickname())
                    .content(event.getContent())
                    .type("CHAT")
                    .build();
            
            aiEventPublisher.publishChatRequest(aiEvent);

        } catch (Exception e) {
            log.error("Failed to publish AI Chat request for User {}: {}", event.getReceiverId(), e.getMessage());
        }
    }
}
