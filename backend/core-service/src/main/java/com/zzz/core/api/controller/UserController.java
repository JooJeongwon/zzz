package com.zzz.core.api.controller;

import com.zzz.core.api.dto.TokenResponse;
import com.zzz.core.api.dto.UserLoginRequest;
import com.zzz.core.api.dto.UserRegisterRequest;
import com.zzz.core.domain.user.AuthService;
import com.zzz.core.domain.user.UserService;
import com.zzz.core.domain.user.UserLifecycleFacade;
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
    private final UserLifecycleFacade userLifecycleFacade;
    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<Void> register(@RequestBody @Valid UserRegisterRequest request) {
        Long userId = authService.register(request);
        return ResponseEntity.created(URI.create("/api/v1/users/" + userId)).build();
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody @Valid UserLoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@RequestBody com.zzz.core.api.dto.RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refresh(request.getRefreshToken()));
    }

    @PostMapping("/heartbeat")
    public ResponseEntity<Void> heartbeat(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.HeartbeatRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userLifecycleFacade.processHeartbeat(userId, request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/heartbeat/batch")
    public ResponseEntity<Void> heartbeatBatch(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.BatchHeartbeatRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userLifecycleFacade.processHeartbeatBatch(userId, request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/status")
    public ResponseEntity<Void> updateStatus(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.UserStatusUpdateRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userLifecycleFacade.updateStatus(userId, UserStatus.valueOf(request.getStatus()));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/fcm-token")
    public ResponseEntity<Void> updateFcmToken(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.FcmTokenUpdateRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userService.updateFcmToken(userId, request.getFcmToken());
        return ResponseEntity.ok().build();
    }
}