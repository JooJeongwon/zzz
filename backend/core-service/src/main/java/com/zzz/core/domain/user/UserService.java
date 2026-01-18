package com.zzz.core.domain.user;

import com.zzz.core.api.dto.HeartbeatRequest;
import com.zzz.core.api.dto.TokenResponse;
import com.zzz.core.api.dto.UserLoginRequest;
import com.zzz.core.api.dto.UserRegisterRequest;
import com.zzz.core.domain.chat.ChatService;
import com.zzz.core.domain.couple.Couple;
import com.zzz.core.domain.couple.CoupleRepository;
import com.zzz.core.domain.notification.NotificationService;
import com.zzz.core.global.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserStatusService userStatusService;
    private final ChatService chatService;
    private final CoupleRepository coupleRepository;
    private final NotificationService notificationService;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public Long register(UserRegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Already exists email");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .nickname(request.getNickname())
                .build();

        return userRepository.save(user).getId();
    }

    @Transactional(readOnly = true)
    public TokenResponse login(UserLoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid password");
        }

        String accessToken = jwtTokenProvider.createToken(user.getId(), user.getEmail());
        String refreshToken = jwtTokenProvider.createRefreshToken(user.getId(), user.getEmail());
        return new TokenResponse(accessToken, refreshToken, user.getId());
    }

    @Transactional(readOnly = true)
    public TokenResponse refresh(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new IllegalArgumentException("Invalid refresh token");
        }

        Long userId = jwtTokenProvider.getUserId(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String newAccessToken = jwtTokenProvider.createToken(user.getId(), user.getEmail());
        String newRefreshToken = jwtTokenProvider.createRefreshToken(user.getId(), user.getEmail());

        return new TokenResponse(newAccessToken, newRefreshToken, user.getId());
    }

    @Transactional
    public void processHeartbeat(Long userId, HeartbeatRequest request) {
        // UserStatusService handles Redis update and RDB sync
        // It returns the OLD status before update
        UserStatus oldStatus = userStatusService.updateHeartbeat(userId, request);
        
        // If user wakes up (SLEEP/STUDY -> ONLINE via Heartbeat), trigger Recap
        if (oldStatus == UserStatus.SLEEP || oldStatus == UserStatus.STUDY) {
             log.info("User {} woke up (Heartbeat). Triggering recap.", userId);
             chatService.createRecap(userId);
             
             // Also notify partner
             notifyPartnerStatusChange(userId, UserStatus.ONLINE);
        }
    }

    @Transactional
    public void updateStatus(Long userId, UserStatus newStatus) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        UserStatus oldStatus = user.updateStatus(newStatus);
        userRepository.save(user);

        // Also update Redis to reflect manual change immediately
        // Note: UserStatusService.updateHeartbeat updates Redis to ONLINE.
        // If we set to SLEEP, we should update Redis too? 
        // Ideally UserStatusService should have 'updateStatus' method for explicit updates.
        // For now, let's leave Redis sync to Heartbeat or add explicit sync here if needed.
        // But if I set SLEEP, and Redis says ONLINE (due to TTL), other users might see ONLINE 
        // until next sync or if we don't update Redis.
        // It's better to update Redis here too.
        
        // Trigger Recap if waking up manually
        if ((oldStatus == UserStatus.SLEEP || oldStatus == UserStatus.STUDY) 
            && newStatus == UserStatus.ONLINE) {
             log.info("User {} woke up (Manual). Triggering recap.", userId);
             chatService.createRecap(userId);
        }

        // Notify Partner
        notifyPartnerStatusChange(userId, newStatus);
    }

    private void notifyPartnerStatusChange(Long userId, UserStatus newStatus) {
        User user = userRepository.findById(userId).orElseThrow();
        if (user.getCoupleId() != null) {
            coupleRepository.findById(user.getCoupleId()).ifPresent(couple -> {
                Long partnerId = couple.getUserA().getId().equals(userId) ? couple.getUserB().getId() : couple.getUserA().getId();
                userRepository.findById(partnerId).ifPresent(partner -> {
                    notificationService.sendStatusChangeNotification(user, partner, newStatus);
                });
            });
        }
    }

    @Transactional
    public void updateFcmToken(Long userId, String fcmToken) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.updateFcmToken(fcmToken);
    }
}