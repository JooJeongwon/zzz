package com.zzz.core.domain.user;

import com.zzz.core.api.dto.HeartbeatRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserStatusService {

    private final UserStatusRepository userStatusRepository;
    private final UserRepository userRepository;

    private static final long HEARTBEAT_TTL_MINUTES = 15; // 10분 주기 + 5분 여유

    /**
     * 사용자의 생존 신호(Heartbeat)를 Redis에 기록.
     * TTL을 갱신하여 Online 상태를 유지함.
     * 또한 RDB의 lastActiveAt을 갱신하여 스케줄러가 오판하지 않도록 함.
     */
    public UserStatus updateHeartbeat(Long userId, HeartbeatRequest request) {
        LocalDateTime timestamp = LocalDateTime.now();
        if (request != null && request.getTimestamp() != null) {
            timestamp = LocalDateTime.ofInstant(Instant.ofEpochMilli(request.getTimestamp()), ZoneId.systemDefault());
        }

        // 1. Redis 상태 갱신 (최신 데이터인 경우에만)
        if (timestamp.isAfter(LocalDateTime.now().minusMinutes(HEARTBEAT_TTL_MINUTES))) {
            userStatusRepository.saveStatus(userId, UserStatus.ONLINE, Duration.ofMinutes(HEARTBEAT_TTL_MINUTES));
        }

        // 2. Metadata 갱신
        if (request != null) {
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("battery", request.getBatteryLevel());
            metadata.put("screenOn", request.getIsScreenOn());
            metadata.put("updatedAt", timestamp.toString());

            userStatusRepository.saveMetadata(userId, metadata, Duration.ofMinutes(HEARTBEAT_TTL_MINUTES));

            if (request.getBatteryLevel() != null && request.getBatteryLevel() < 5) {
                log.warn("User {} battery is low ({}%)", userId, request.getBatteryLevel());
            }
        }

        // 3. RDB 동기화 (Scheduler가 lastActiveAt을 기준으로 동작하므로 필수)
        // Atomic하게 처리되지 않지만, Redis가 우선이므로 괜찮음
        LocalDateTime finalTimestamp = timestamp;
        return userRepository.findById(userId)
                .map(user -> {
                    // DB에는 과거 데이터라도 기록 (히스토리성)
                    UserStatus oldStatus = user.updateHeartbeat(finalTimestamp);
                    userRepository.save(user);
                    return oldStatus;
                })
                .orElse(UserStatus.UNKNOWN);
    }

    /**
     * 사용자의 상태를 수동으로 변경하고 Redis에 즉시 반영.
     */
    public void updateStatus(Long userId, UserStatus status) {
        userStatusRepository.saveStatus(userId, status, Duration.ofMinutes(HEARTBEAT_TTL_MINUTES));
        userStatusRepository.updateMetadataField(userId, "updatedAt", LocalDateTime.now().toString(), Duration.ofMinutes(HEARTBEAT_TTL_MINUTES));
    }

    /**
     * 사용자의 현재 상태 조회 (Redis -> DB Fallback은 상위 로직에서 결정)
     */
    public UserStatus getUserStatus(Long userId) {
        return userStatusRepository.getStatus(userId).orElse(UserStatus.UNKNOWN);
    }

    public Map<Object, Object> getUserMetadata(Long userId) {
        return userStatusRepository.getMetadata(userId);
    }
}