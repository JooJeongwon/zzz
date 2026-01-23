package com.zzz.core.domain.chat;

import com.zzz.core.domain.ai.event.AIEventPublisher;
import com.zzz.core.domain.ai.event.AIRequestEvent;
import com.zzz.core.domain.chat.event.MessageSentEvent;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserRepository;
import com.zzz.core.domain.couple.Couple;
import com.zzz.core.domain.couple.CoupleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatRepository chatRepository;
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final AIEventPublisher aiEventPublisher;
    private final ApplicationEventPublisher eventPublisher;

    public Page<ChatMessage> getChatHistory(Long userId, Long partnerId, Pageable pageable) {
        return chatRepository.findBySenderIdAndReceiverIdOrSenderIdAndReceiverIdOrderByCreatedAtDesc(
                userId, partnerId, partnerId, userId, pageable);
    }
    
    public ChatMessage sendMessage(Long senderId, Long receiverId, String content) {
        // 1. Save User Message
        ChatMessage userMessage = ChatMessage.builder()
                .senderId(senderId)
                .receiverId(receiverId)
                .content(content)
                .isAiGenerated(false)
                .messageType("TEXT")
                .createdAt(LocalDateTime.now())
                .build();
        chatRepository.save(userMessage);

        // 2. Publish Event
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        eventPublisher.publishEvent(MessageSentEvent.builder()
                .senderId(senderId)
                .receiverId(receiverId)
                .content(content)
                .receiverStatus(receiver.getStatus())
                .receiverNickname(receiver.getNickname())
                .build());

        return userMessage;
    }

    @Async
    public void createRecap(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        if (user.getCoupleId() == null) return;

        Couple couple = coupleRepository.findById(user.getCoupleId())
                .orElseThrow(() -> new IllegalArgumentException("Couple not found"));
        
        Long partnerId = couple.getUserA().getId().equals(userId) ? couple.getUserB().getId() : couple.getUserA().getId();
        
        // Fetch last 30 messages for context
        Pageable limit = PageRequest.of(0, 30);
        Page<ChatMessage> recentMessages = chatRepository.findBySenderIdAndReceiverIdOrSenderIdAndReceiverIdOrderByCreatedAtDesc(
            userId, partnerId, partnerId, userId, limit
        );
        
        if (recentMessages.isEmpty()) return;

        StringBuilder conversation = new StringBuilder();
        List<ChatMessage> reversed = new ArrayList<>(recentMessages.getContent());
        Collections.reverse(reversed);
        
        for (ChatMessage msg : reversed) {
             String sender = msg.getSenderId().equals(userId) ? "Me" : "Partner";
             if (msg.isAiGenerated()) sender = "Me (AI)";
             conversation.append(sender).append(": ").append(msg.getContent()).append("\n");
        }

        try {
            AIRequestEvent event = AIRequestEvent.builder()
                    .requestId(UUID.randomUUID().toString())
                    .userId(String.valueOf(userId))
                    .partnerId(String.valueOf(partnerId))
                    .partnerName("Partner")
                    .content(conversation.toString())
                    .type("RECAP")
                    .build();

            aiEventPublisher.publishRecapRequest(event);
             
        } catch (Exception e) {
            log.error("Failed to publish AI Recap request", e);
        }
    }
}
