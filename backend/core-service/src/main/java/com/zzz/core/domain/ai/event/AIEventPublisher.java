package com.zzz.core.domain.ai.event;

import com.zzz.core.global.config.RabbitMqConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class AIEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    public void publishChatRequest(AIRequestEvent event) {
        log.info("Publishing AI Chat Request: {}", event.getRequestId());
        rabbitTemplate.convertAndSend(RabbitMqConfig.AI_EXCHANGE_NAME, RabbitMqConfig.AI_REQUEST_CHAT_ROUTING_KEY, event);
    }

    public void publishRecapRequest(AIRequestEvent event) {
        log.info("Publishing AI Recap Request: {}", event.getRequestId());
        rabbitTemplate.convertAndSend(RabbitMqConfig.AI_EXCHANGE_NAME, RabbitMqConfig.AI_REQUEST_RECAP_ROUTING_KEY, event);
    }
}
