package com.zzz.core.api.controller;

import com.zzz.core.domain.chat.ChatMessage;
import com.zzz.core.domain.chat.ChatService;
import com.zzz.core.global.security.JwtTokenProvider;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "Chat API", description = "채팅 관련 API")
public class ChatController {

    private final ChatService chatService;

    @GetMapping("/history")
    @Operation(summary = "채팅 기록 조회", description = "상대방과의 과거 채팅 내역을 페이징하여 조회합니다.")
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
    @Operation(summary = "메시지 전송", description = "상대방에게 메시지를 전송합니다.")
    public ResponseEntity<ChatMessage> sendMessage(@RequestBody SendMessageRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long senderId = Long.parseLong(authentication.getName());

        ChatMessage result = chatService.sendMessage(senderId, request.getReceiverId(), request.getContent());
        return ResponseEntity.ok(result);
    }

    @Data
    @Schema(description = "메시지 전송 요청")
    public static class SendMessageRequest {
        @Schema(description = "수신자 ID", example = "2")
        private Long receiverId;
        @Schema(description = "메시지 내용", example = "안녕, 자니?")
        private String content;
    }
}
