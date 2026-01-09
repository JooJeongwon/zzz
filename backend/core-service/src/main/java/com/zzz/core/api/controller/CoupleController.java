package com.zzz.core.api.controller;

import com.zzz.core.api.dto.CoupleConnectRequest;
import com.zzz.core.api.dto.CoupleInviteResponse;
import com.zzz.core.api.dto.PartnerStatusResponse;
import com.zzz.core.domain.couple.CoupleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/couples")
@RequiredArgsConstructor
public class CoupleController {

    private final CoupleService coupleService;

    @PostMapping("/invite")
    public ResponseEntity<CoupleInviteResponse> createInvite(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(coupleService.createInviteCode(userId));
    }

    @PostMapping("/connect")
    public ResponseEntity<Void> connectCouple(
            Authentication authentication,
            @RequestBody @Valid CoupleConnectRequest request) {
        Long userId = (Long) authentication.getPrincipal();
        coupleService.connectCouple(userId, request.getCode());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/partner-status")
    public ResponseEntity<PartnerStatusResponse> getPartnerStatus(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(coupleService.getPartnerStatus(userId));
    }
}
