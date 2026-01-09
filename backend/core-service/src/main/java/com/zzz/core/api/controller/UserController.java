package com.zzz.core.api.controller;

import com.zzz.core.api.dto.TokenResponse;
import com.zzz.core.api.dto.UserLoginRequest;
import com.zzz.core.api.dto.UserRegisterRequest;
import com.zzz.core.domain.user.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;

import com.zzz.core.domain.user.UserStatus;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<Void> register(@RequestBody @Valid UserRegisterRequest request) {
        Long userId = userService.register(request);
        return ResponseEntity.created(URI.create("/api/v1/users/" + userId)).build();
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody @Valid UserLoginRequest request) {
        return ResponseEntity.ok(userService.login(request));
    }

    @PostMapping("/heartbeat")
    public ResponseEntity<Void> heartbeat(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.HeartbeatRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userService.processHeartbeat(userId, request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/status")
    public ResponseEntity<Void> updateStatus(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.UserStatusUpdateRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userService.updateStatus(userId, UserStatus.valueOf(request.getStatus()));
        return ResponseEntity.ok().build();
    }
}
