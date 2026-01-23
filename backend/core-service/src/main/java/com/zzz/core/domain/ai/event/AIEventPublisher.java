package com.zzz.core.domain.ai.event;

import com.zzz.core.global.config.RabbitMqConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class AIEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Retryable(
            retryFor = {Exception.class}, 
            maxAttempts = 3,
            backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    public void publishChatRequest(AIRequestEvent event) {
        log.info("Publishing AI Chat Request: {}", event.getRequestId());
        rabbitTemplate.convertAndSend(RabbitMqConfig.AI_EXCHANGE_NAME, RabbitMqConfig.AI_REQUEST_CHAT_ROUTING_KEY, event);
    }

    public void publishRecapRequest(AIRequestEvent event) {
        log.info("Publishing AI Recap Request: {}", event.getRequestId());
        rabbitTemplate.convertAndSend(RabbitMqConfig.AI_EXCHANGE_NAME, RabbitMqConfig.AI_REQUEST_RECAP_ROUTING_KEY, event);
    }

    public void publishDreamLogRequest(AIRequestEvent event) {
        log.info("Publishing AI Dream Log Request: {}", event.getRequestId());
        rabbitTemplate.convertAndSend(RabbitMqConfig.AI_EXCHANGE_NAME, RabbitMqConfig.AI_REQUEST_DREAM_ROUTING_KEY, event);
    }
}
