package com.zzz.core.domain.gamification;

import com.zzz.core.domain.couple.Couple;
import com.zzz.core.domain.couple.CoupleRepository;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserRepository;
import com.zzz.core.domain.user.UserStatus;
import com.zzz.core.domain.user.UserStatusRepository;
import com.zzz.core.domain.chat.ChatRepository;
import com.zzz.core.domain.chat.ChatMessage;
import com.zzz.core.domain.ai.event.AIEventPublisher;
import com.zzz.core.domain.ai.event.AIRequestEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class GamificationService {

    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final UserStatusRepository userStatusRepository;
    private final ChatRepository chatRepository;
    private final AIEventPublisher aiEventPublisher;

    @Transactional
    public void processStatusChange(Long userId, UserStatus oldStatus, UserStatus newStatus) {
        if (oldStatus == newStatus) return;

        User user = userRepository.findById(userId).orElse(null);
        if (user == null || user.getCoupleId() == null) return;

        Couple couple = coupleRepository.findById(user.getCoupleId()).orElse(null);
        if (couple == null) return;

        // 1. Grant XP Logic
        applyXpRules(userId, couple, oldStatus, newStatus);

        // 2. Sync Totem Logic
        updateSyncState(userId, couple, oldStatus, newStatus);
        
        coupleRepository.save(couple);
    }

    private void applyXpRules(Long userId, Couple couple, UserStatus oldStatus, UserStatus newStatus) {
        // 1. Wake Up (Sleep -> Online/Busy/Study)
        if (oldStatus == UserStatus.SLEEP && newStatus != UserStatus.SLEEP) {
            grantXpToCouple(couple, userId, 10, "Wake Up");
        }
        
        // 2. Go to Sleep (Online/Busy/Study -> Sleep)
        if (newStatus == UserStatus.SLEEP) {
            grantXpToCouple(couple, userId, 10, "Good Night");
        }
        
        // 3. Focus (Online -> Study)
        if (oldStatus == UserStatus.ONLINE && newStatus == UserStatus.STUDY) {
            grantXpToCouple(couple, userId, 5, "Focus Mode");
        }
    }

    private void updateSyncState(Long userId, Couple couple, UserStatus oldStatus, UserStatus newStatus) {
        User partner = couple.getUserA().getId().equals(userId) ? couple.getUserB() : couple.getUserA();
        
        // Prefer Redis status for real-time accuracy, fallback to DB
        UserStatus partnerStatus = userStatusRepository.getStatus(partner.getId())
                .orElse(partner.getStatus());

        if (newStatus == partnerStatus) {
            // Start Sync if not already started
            if (couple.getSyncStartTime() == null) {
                couple.updateSyncState(LocalDateTime.now());
                log.info("Sync started for Couple {} (Status: {})", couple.getId(), newStatus);
            }
        } else {
            // Break Sync
            if (couple.getSyncStartTime() != null) {
                // Check if Dream Log should be triggered (Sleep Sync > 4 hours)
                if (oldStatus == UserStatus.SLEEP) {
                    Duration duration = Duration.between(couple.getSyncStartTime(), LocalDateTime.now());
                    if (duration.toHours() >= 4) {
                        triggerDreamLogGeneration(couple);
                    }
                }

                couple.updateSyncState(null);
                log.info("Sync broken for Couple {}", couple.getId());
            }
        }
    }

    private void triggerDreamLogGeneration(Couple couple) {
        log.info("Triggering Dream Log for Couple {}", couple.getId());
        
        // Fetch recent chats (last 50 messages)
        List<ChatMessage> messages = chatRepository.findBySenderIdAndReceiverIdOrSenderIdAndReceiverIdOrderByCreatedAtDesc(
            couple.getUserA().getId(), couple.getUserB().getId(),
            couple.getUserA().getId(), couple.getUserB().getId(),
            PageRequest.of(0, 50)
        ).getContent();
        
        if (messages.isEmpty()) {
            log.info("No recent chats for Dream Log. Skipping.");
            return;
        }

        // Reverse to chronological order
        List<ChatMessage> reversedMessages = messages.subList(0, messages.size());
        Collections.reverse(reversedMessages);
        
        String chatHistory = reversedMessages.stream()
            .map(msg -> msg.getContent())
            .collect(Collectors.joining("\n"));
            
        AIRequestEvent event = AIRequestEvent.builder()
            .requestId(UUID.randomUUID().toString())
            .userId(String.valueOf(couple.getUserA().getId()))
            .partnerId(String.valueOf(couple.getUserB().getId()))
            .partnerName("Couples")
            .content(chatHistory)
            .type("DREAM_LOG")
            .build();
            
        aiEventPublisher.publishDreamLogRequest(event);
    }

    // Refactored to take Couple object directly to avoid re-fetching
    private void grantXpToCouple(Couple couple, Long userId, int amount, String reason) {
        couple.increaseXp(amount);
        // Save is done in caller
        log.info("Granted {} XP to Couple {} (User: {}, Reason: {}). Current Lv: {}", 
                amount, couple.getId(), userId, reason, couple.getLevel());
    }

    @Transactional
    public void grantXp(Long userId, int amount, String reason) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null || user.getCoupleId() == null) return;

        Couple couple = coupleRepository.findById(user.getCoupleId()).orElse(null);
        if (couple == null) return;

        grantXpToCouple(couple, userId, amount, reason);
        coupleRepository.save(couple);
    }
}
