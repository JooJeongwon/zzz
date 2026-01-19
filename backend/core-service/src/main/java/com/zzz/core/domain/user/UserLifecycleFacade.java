package com.zzz.core.domain.user;

import com.zzz.core.api.dto.HeartbeatRequest;
import com.zzz.core.domain.chat.ChatService;
import com.zzz.core.domain.couple.CoupleRepository;
import com.zzz.core.domain.notification.event.NotificationEvent;
import com.zzz.core.domain.notification.event.NotificationEventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserLifecycleFacade {

    private final UserService userService;
    private final UserStatusService userStatusService;
    private final ChatService chatService;
    private final CoupleRepository coupleRepository;
    private final NotificationEventPublisher notificationEventPublisher;
    private final UserRepository userRepository;

    @Transactional
    public void processHeartbeat(Long userId, HeartbeatRequest request) {
        // UserStatusService handles Redis update and RDB sync
        UserStatus oldStatus = userStatusService.updateHeartbeat(userId, request);
        
        // If user wakes up (SLEEP/STUDY -> ONLINE via Heartbeat), trigger Recap
        if (oldStatus == UserStatus.SLEEP || oldStatus == UserStatus.STUDY) {
             log.info("User {} woke up (Heartbeat). Triggering recap.", userId);
             chatService.createRecap(userId);
             
             // Also notify partner
             notifyPartnerStatusChange(userId, UserStatus.ONLINE);
        }
    }

    @Transactional
    public void processHeartbeatBatch(Long userId, com.zzz.core.api.dto.BatchHeartbeatRequest request) {
        if (request.getHeartbeats() == null || request.getHeartbeats().isEmpty()) return;

        // Sort by timestamp
        request.getHeartbeats().sort((a, b) -> {
            long t1 = a.getTimestamp() != null ? a.getTimestamp() : System.currentTimeMillis();
            long t2 = b.getTimestamp() != null ? b.getTimestamp() : System.currentTimeMillis();
            return Long.compare(t1, t2);
        });

        for (HeartbeatRequest hb : request.getHeartbeats()) {
            processHeartbeat(userId, hb);
        }
    }

    @Transactional
    public void updateStatus(Long userId, UserStatus newStatus) {
        // 1. DB Update
        UserStatus oldStatus = userService.updateStatusInDb(userId, newStatus);

        // 2. Redis Sync
        userStatusService.updateStatus(userId, newStatus);
        
        // 3. Recap Trigger
        if ((oldStatus == UserStatus.SLEEP || oldStatus == UserStatus.STUDY) 
            && newStatus == UserStatus.ONLINE) {
             log.info("User {} woke up (Manual). Triggering recap.", userId);
             chatService.createRecap(userId);
        }

        // 4. Notify Partner
        notifyPartnerStatusChange(userId, newStatus);
    }

    private void notifyPartnerStatusChange(Long userId, UserStatus newStatus) {
        User user = userRepository.findById(userId).orElseThrow();
        if (user.getCoupleId() != null) {
            coupleRepository.findById(user.getCoupleId()).ifPresent(couple -> {
                Long partnerId = couple.getUserA().getId().equals(userId) ? couple.getUserB().getId() : couple.getUserA().getId();
                
                NotificationEvent event = NotificationEvent.builder()
                        .type("STATUS_CHANGE")
                        .senderId(userId)
                        .receiverId(partnerId)
                        .content(newStatus.name())
                        .timestamp(System.currentTimeMillis())
                        .build();

                notificationEventPublisher.publish(event);
            });
        }
    }
}