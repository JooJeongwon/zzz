package com.zzz.core.domain.notification;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class NotificationService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);
    private final FirebaseMessaging firebaseMessaging;

    public NotificationService(@Autowired(required = false) FirebaseMessaging firebaseMessaging) {
        this.firebaseMessaging = firebaseMessaging;
    }

    public void sendStatusChangeNotification(User sender, User receiver, UserStatus newStatus) {
        if (receiver.getFcmToken() == null) {
            logger.debug("Receiver {} has no FCM token", receiver.getId());
            return;
        }

        String title = sender.getNickname() + "님의 상태가 변경되었습니다.";
        String body = getStatusMessage(sender.getNickname(), newStatus);
        
        Map<String, String> data = new HashMap<>();
        data.put("type", "STATUS_CHANGE");
        data.put("status", newStatus.name());
        data.put("userId", String.valueOf(sender.getId()));

        sendNotification(receiver.getFcmToken(), title, body, data);
    }

    public void sendChatNotification(User sender, User receiver, String content) {
        if (receiver.getFcmToken() == null) {
            logger.debug("Receiver {} has no FCM token", receiver.getId());
            return;
        }

        String title = sender.getNickname();
        // Truncate content if too long
        String body = content.length() > 50 ? content.substring(0, 50) + "..." : content;

        Map<String, String> data = new HashMap<>();
        data.put("type", "CHAT");
        data.put("senderId", String.valueOf(sender.getId()));
        data.put("content", content); // Be careful with payload size limits (4KB)

        sendNotification(receiver.getFcmToken(), title, body, data);
    }

    private void sendNotification(String token, String title, String body, Map<String, String> data) {
        if (firebaseMessaging == null) {
            logger.warn("FirebaseMessaging is not initialized. Skipping notification.");
            return;
        }

        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message.Builder messageBuilder = Message.builder()
                    .setToken(token)
                    .setNotification(notification);

            if (data != null) {
                messageBuilder.putAllData(data);
            }

            String response = firebaseMessaging.send(messageBuilder.build());
            logger.debug("Successfully sent message: {}", response);
        } catch (Exception e) {
            logger.error("Failed to send FCM message", e);
        }
    }

    private String getStatusMessage(String nickname, UserStatus status) {
        switch (status) {
            case SLEEP:
                return nickname + "님이 잠들었어요. 💤";
            case STUDY:
                return nickname + "님이 공부를 시작했어요. 📚";
            case ONLINE:
                return nickname + "님이 돌아왔어요! 👋";
            case BUSY:
                return nickname + "님이 바쁜 상태입니다. ⛔";
            case UNKNOWN:
            default:
                return nickname + "님의 상태가 확인되지 않습니다.";
        }
    }
}
