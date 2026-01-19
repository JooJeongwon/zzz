package com.zzz.core.domain.notification.event;

import com.zzz.core.global.config.RabbitMqConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    public void publish(NotificationEvent event) {
        log.info("Publishing NotificationEvent: {}", event);
        rabbitTemplate.convertAndSend(RabbitMqConfig.EXCHANGE_NAME, "notification.event", event);
    }
}
