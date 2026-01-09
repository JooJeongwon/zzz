package com.zzz.core.api.controller;

import com.zzz.core.domain.chat.ChatMessage;
import com.zzz.core.domain.chat.ChatService;
import com.zzz.core.global.security.JwtTokenProvider;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @GetMapping("/history")
    public ResponseEntity<Page<ChatMessage>> getChatHistory(
            @RequestParam Long partnerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long userId = Long.parseLong(authentication.getName());

        Page<ChatMessage> history = chatService.getChatHistory(
                userId, partnerId, PageRequest.of(page, size));
        
        return ResponseEntity.ok(history);
    }

    @PostMapping("/send")
    public ResponseEntity<ChatMessage> sendMessage(@RequestBody SendMessageRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long senderId = Long.parseLong(authentication.getName());

        ChatMessage result = chatService.sendMessage(senderId, request.getReceiverId(), request.getContent());
        return ResponseEntity.ok(result);
    }

    @Data
    public static class SendMessageRequest {
        private Long receiverId;
        private String content;
    }
}
