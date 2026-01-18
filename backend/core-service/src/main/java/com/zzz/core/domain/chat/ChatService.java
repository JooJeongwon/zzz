package com.zzz.core.domain.chat;

import com.zzz.core.domain.chat.client.AIChatRequest;
import com.zzz.core.domain.chat.client.AIChatResponse;
import com.zzz.core.domain.chat.client.AIServiceClient;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserRepository;
import com.zzz.core.domain.user.UserStatus;
import com.zzz.core.domain.couple.Couple;
import com.zzz.core.domain.couple.CoupleRepository;
import com.zzz.core.domain.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatRepository chatRepository;
    private final UserRepository userRepository;
    private final AIServiceClient aiServiceClient;
    private final CoupleRepository coupleRepository;
    private final NotificationService notificationService;

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

        // 2. Check Receiver Status & Trigger AI
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        // Notify Receiver
        notificationService.sendChatNotification(sender, receiver, content);

        if (isUserUnavailable(receiver.getStatus())) {
            triggerAutoReply(receiver, sender, content);
        }

        return userMessage; // Return original message immediately
    }

    private boolean isUserUnavailable(UserStatus status) {
        return status == UserStatus.SLEEP || status == UserStatus.STUDY || status == UserStatus.BUSY;
    }

    private void triggerAutoReply(User receiver, User sender, String userMessageContent) {
        log.info("User {} is {}, generating AI response...", receiver.getId(), receiver.getStatus());
        try {
            AIChatResponse aiResponse = aiServiceClient.generateResponse(AIChatRequest.builder()
                    .user_id(String.valueOf(sender.getId())) // The one asking
                    .partner_id(String.valueOf(receiver.getId())) // The one sleeping (AI Persona)
                    .partner_name(receiver.getNickname()) 
                    .message(userMessageContent)
                    .build());

            if (aiResponse != null && aiResponse.getResponse() != null) {
                ChatMessage aiMessage = ChatMessage.builder()
                        .senderId(receiver.getId()) // AI replies as the receiver
                        .receiverId(sender.getId())
                        .content(aiResponse.getResponse())
                        .isAiGenerated(true)
                        .messageType("TEXT")
                        .createdAt(LocalDateTime.now())
                        .build();
                chatRepository.save(aiMessage);
                
                // Notify Sender (who is receiving the AI reply)
                notificationService.sendChatNotification(receiver, sender, aiResponse.getResponse());
            }

        } catch (Exception e) {
            log.error("Failed to generate AI response for User {}: {}", receiver.getId(), e.getMessage());
        }
    }

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
             AIChatResponse aiResponse = aiServiceClient.generateRecap(AIChatRequest.builder()
                 .user_id(String.valueOf(userId))
                 .partner_id(String.valueOf(partnerId))
                 .partner_name("Partner") // Not strictly needed for recap but required by DTO
                 .message(conversation.toString())
                 .build());
                 
             if (aiResponse.getResponse() != null && !aiResponse.getResponse().isEmpty()) {
                 ChatMessage recapMsg = ChatMessage.builder()
                     .senderId(partnerId) // Recap appears as if from Partner (or AI Agent)
                     .receiverId(userId)
                     .content(aiResponse.getResponse())
                     .isAiGenerated(true)
                     .messageType("RECAP")
                     .createdAt(LocalDateTime.now())
                     .build();
                 chatRepository.save(recapMsg);
             }
             
        } catch (Exception e) {
            log.error("Recap failed", e);
        }
    }
}