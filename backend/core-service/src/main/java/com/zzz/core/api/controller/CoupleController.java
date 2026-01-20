package com.zzz.core.api.controller;

import com.zzz.core.api.dto.CoupleConnectRequest;
import com.zzz.core.api.dto.CoupleInviteResponse;
import com.zzz.core.api.dto.PartnerStatusResponse;
import com.zzz.core.domain.couple.CoupleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/couples")
@RequiredArgsConstructor
@Tag(name = "Couple API", description = "커플 연결 및 조회 API")
public class CoupleController {

    private final CoupleService coupleService;

    @PostMapping("/invite")
    @Operation(summary = "초대 코드 생성", description = "상대방을 초대하기 위한 코드를 생성합니다.")
    public ResponseEntity<CoupleInviteResponse> createInvite(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(coupleService.createInviteCode(userId));
    }

    @PostMapping("/connect")
    @Operation(summary = "커플 연결", description = "초대 코드를 입력하여 커플을 맺습니다.")
    public ResponseEntity<Void> connectCouple(
            Authentication authentication,
            @RequestBody @Valid CoupleConnectRequest request) {
        Long userId = (Long) authentication.getPrincipal();
        coupleService.connectCouple(userId, request.getCode());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/partner-status")
    @Operation(summary = "상대방 상태 조회", description = "연결된 상대방의 현재 상태 정보를 조회합니다.")
    public ResponseEntity<PartnerStatusResponse> getPartnerStatus(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(coupleService.getPartnerStatus(userId));
    }
}
