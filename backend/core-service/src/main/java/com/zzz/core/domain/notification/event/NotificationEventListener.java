package com.zzz.core.domain.notification.event;

import com.zzz.core.domain.notification.NotificationService;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserRepository;
import com.zzz.core.domain.user.UserStatus;
import com.zzz.core.global.config.RabbitMqConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationEventListener {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    @RabbitListener(queues = RabbitMqConfig.NOTIFICATION_QUEUE)
    public void handleNotificationEvent(NotificationEvent event) {
        log.info("Received NotificationEvent: {}", event);
        try {
            User sender = userRepository.findById(event.getSenderId()).orElse(null);
            User receiver = userRepository.findById(event.getReceiverId()).orElse(null);

            if (sender == null || receiver == null) {
                log.warn("User not found for notification event: sender={}, receiver={}", event.getSenderId(), event.getReceiverId());
                return;
            }

            if ("CHAT".equals(event.getType())) {
                notificationService.sendChatNotification(sender, receiver, event.getContent());
            } else if ("STATUS_CHANGE".equals(event.getType())) {
                try {
                    UserStatus status = UserStatus.valueOf(event.getContent());
                    notificationService.sendStatusChangeNotification(sender, receiver, status);
                } catch (IllegalArgumentException e) {
                    log.error("Invalid UserStatus in event: {}", event.getContent());
                }
            }
        } catch (Exception e) {
            log.error("Error handling notification event", e);
        }
    }
}
