package com.zzz.core.api.controller;

import com.zzz.core.api.dto.TokenResponse;
import com.zzz.core.api.dto.UserLoginRequest;
import com.zzz.core.api.dto.UserRegisterRequest;
import com.zzz.core.domain.user.AuthService;
import com.zzz.core.domain.user.UserService;
import com.zzz.core.domain.user.UserLifecycleFacade;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "User API", description = "유저 및 인증 관련 API")
public class UserController {

    private final UserService userService;
    private final UserLifecycleFacade userLifecycleFacade;
    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "회원가입", description = "새로운 유저를 등록합니다.")
    public ResponseEntity<Void> register(@RequestBody @Valid UserRegisterRequest request) {
        Long userId = authService.register(request);
        return ResponseEntity.created(URI.create("/api/v1/users/" + userId)).build();
    }

    @PostMapping("/login")
    @Operation(summary = "로그인", description = "이메일과 비밀번호로 로그인하여 토큰을 발급받습니다.")
    public ResponseEntity<TokenResponse> login(@RequestBody @Valid UserLoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    @Operation(summary = "토큰 재발급", description = "리프레시 토큰을 사용하여 액세스 토큰을 재발급받습니다.")
    public ResponseEntity<TokenResponse> refresh(@RequestBody com.zzz.core.api.dto.RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refresh(request.getRefreshToken()));
    }

    @PostMapping("/heartbeat")
    @Operation(summary = "하트비트 전송", description = "앱이 활성화되어 있음을 서버에 알리고 배터리 정보를 갱신합니다.")
    public ResponseEntity<Void> heartbeat(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.HeartbeatRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userLifecycleFacade.processHeartbeat(userId, request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/heartbeat/batch")
    @Operation(summary = "오프라인 하트비트 일괄 전송", description = "네트워크 연결 시 오프라인 동안 쌓인 하트비트 데이터를 일괄 전송합니다.")
    public ResponseEntity<Void> heartbeatBatch(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.BatchHeartbeatRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userLifecycleFacade.processHeartbeatBatch(userId, request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/status")
    @Operation(summary = "상태 변경", description = "유저의 상태(SLEEP, STUDY 등)를 수동으로 변경합니다.")
    public ResponseEntity<Void> updateStatus(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.UserStatusUpdateRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userLifecycleFacade.updateStatus(userId, UserStatus.valueOf(request.getStatus()));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/fcm-token")
    @Operation(summary = "FCM 토큰 갱신", description = "푸시 알림을 위한 FCM 토큰을 갱신합니다.")
    public ResponseEntity<Void> updateFcmToken(
            org.springframework.security.core.Authentication authentication,
            @RequestBody com.zzz.core.api.dto.FcmTokenUpdateRequest request) {
        Long userId = Long.parseLong(authentication.getName());
        userService.updateFcmToken(userId, request.getFcmToken());
        return ResponseEntity.ok().build();
    }
}