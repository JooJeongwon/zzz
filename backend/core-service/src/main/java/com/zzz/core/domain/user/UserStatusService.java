package com.zzz.core.domain.user;

import com.zzz.core.api.dto.HeartbeatRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserStatusService {

    private final RedisTemplate<String, Object> redisTemplate;
    private final UserRepository userRepository;

    private static final String USER_STATUS_KEY_PREFIX = "user:status:";
    private static final String USER_METADATA_KEY_PREFIX = "user:metadata:";
    private static final long HEARTBEAT_TTL_MINUTES = 15; // 10분 주기 + 5분 여유

    /**
     * 사용자의 생존 신호(Heartbeat)를 Redis에 기록.
     * TTL을 갱신하여 Online 상태를 유지함.
     * 또한 RDB의 lastActiveAt을 갱신하여 스케줄러가 오판하지 않도록 함.
     */
    public UserStatus updateHeartbeat(Long userId, HeartbeatRequest request) {
        // 1. Redis 상태 갱신
        String statusKey = getUserStatusKey(userId);
        redisTemplate.opsForValue().set(statusKey, UserStatus.ONLINE.name(), Duration.ofMinutes(HEARTBEAT_TTL_MINUTES));

        // 2. Metadata 갱신
        if (request != null) {
            String metaKey = USER_METADATA_KEY_PREFIX + userId;
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("battery", request.getBatteryLevel());
            metadata.put("screenOn", request.getIsScreenOn());
            metadata.put("updatedAt", LocalDateTime.now().toString());

            redisTemplate.opsForHash().putAll(metaKey, metadata);
            redisTemplate.expire(metaKey, Duration.ofMinutes(HEARTBEAT_TTL_MINUTES));

            if (request.getBatteryLevel() != null && request.getBatteryLevel() < 5) {
                log.warn("User {} battery is low ({}%)", userId, request.getBatteryLevel());
            }
        }

        // 3. RDB 동기화 (Scheduler가 lastActiveAt을 기준으로 동작하므로 필수)
        // Atomic하게 처리되지 않지만, Redis가 우선이므로 괜찮음
        return userRepository.findById(userId)
                .map(user -> {
                    UserStatus oldStatus = user.updateHeartbeat();
                    userRepository.save(user);
                    return oldStatus;
                })
                .orElse(UserStatus.UNKNOWN);
    }

    /**
     * 사용자의 현재 상태 조회 (Redis -> DB Fallback은 상위 로직에서 결정)
     */
    public UserStatus getUserStatus(Long userId) {
        String key = getUserStatusKey(userId);
        String statusStr = (String) redisTemplate.opsForValue().get(key);
        
        if (statusStr != null) {
            return UserStatus.valueOf(statusStr);
        }
        return UserStatus.UNKNOWN; // Redis에 없으면 일단 Unknown (혹은 DB 조회 필요)
    }

    private String getUserStatusKey(Long userId) {
        return USER_STATUS_KEY_PREFIX + userId;
    }
}
