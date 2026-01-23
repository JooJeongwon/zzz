package com.zzz.core.domain.ai.event;

import com.zzz.core.domain.chat.ChatMessage;
import com.zzz.core.domain.chat.ChatRepository;
import com.zzz.core.domain.notification.event.NotificationEvent;
import com.zzz.core.domain.notification.event.NotificationEventPublisher;
import com.zzz.core.global.config.RabbitMqConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.AmqpRejectAndDontRequeueException;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;
import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class AIResponseListener {

    private final ChatRepository chatRepository;
    private final NotificationEventPublisher notificationEventPublisher;

    @RabbitListener(queues = RabbitMqConfig.AI_RESPONSE_QUEUE)
    public void handleAIResponse(AIResponseEvent event) {
        try {
            log.info("Received AI Response for request: {}", event.getOriginalRequestId());

            if (event.getContent() == null || event.getContent().isEmpty()) {
                return;
            }

            Long senderId = Long.valueOf(event.getPartnerId());
            Long receiverId = Long.valueOf(event.getUserId());

            String messageType = "TEXT";
            if ("RECAP".equals(event.getType())) {
                messageType = "RECAP";
            } else if ("DREAM_LOG".equals(event.getType())) {
                messageType = "DREAM_LOG";
            }

            ChatMessage aiMessage = ChatMessage.builder()
                    .senderId(senderId)
                    .receiverId(receiverId)
                    .content(event.getContent())
                    .isAiGenerated(true)
                    .messageType(messageType)
                    .createdAt(LocalDateTime.now())
                    .build();

            chatRepository.save(aiMessage);

            // Notify Receiver (The original requester)
            publishChatNotification(senderId, receiverId, event.getContent());
        } catch (NumberFormatException e) {
            log.error("Invalid format in AI Response: partnerId={} userId={}. Sending to DLQ.", event.getPartnerId(), event.getUserId(), e);
            throw new AmqpRejectAndDontRequeueException("Invalid number format in AI response", e);
        } catch (Exception e) {
            log.error("Unexpected error processing AI Response. Sending to DLQ.", e);
            throw new AmqpRejectAndDontRequeueException("Unexpected error in AI response processing", e);
        }
    }

    private void publishChatNotification(Long senderId, Long receiverId, String content) {
        NotificationEvent event = NotificationEvent.builder()
                .type("CHAT")
                .senderId(senderId)
                .receiverId(receiverId)
                .content(content)
                .timestamp(System.currentTimeMillis())
                .build();
        notificationEventPublisher.publish(event);
    }
}
