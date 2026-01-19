package com.zzz.core.infrastructure.persistence;

import com.zzz.core.domain.user.UserStatus;
import com.zzz.core.domain.user.UserStatusRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Repository;

import java.time.Duration;
import java.util.Map;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class RedisUserStatusRepository implements UserStatusRepository {

    private final RedisTemplate<String, Object> redisTemplate;

    private static final String USER_STATUS_KEY_PREFIX = "user:status:";
    private static final String USER_METADATA_KEY_PREFIX = "user:metadata:";

    @Override
    public void saveStatus(Long userId, UserStatus status, Duration ttl) {
        String key = getUserStatusKey(userId);
        redisTemplate.opsForValue().set(key, status.name(), ttl);
    }

    @Override
    public Optional<UserStatus> getStatus(Long userId) {
        String key = getUserStatusKey(userId);
        String statusStr = (String) redisTemplate.opsForValue().get(key);
        if (statusStr != null) {
            return Optional.of(UserStatus.valueOf(statusStr));
        }
        return Optional.empty();
    }

    @Override
    public void saveMetadata(Long userId, Map<String, Object> metadata, Duration ttl) {
        String key = getUserMetadataKey(userId);
        redisTemplate.opsForHash().putAll(key, metadata);
        redisTemplate.expire(key, ttl);
    }

    @Override
    public void updateMetadataField(Long userId, String field, String value, Duration ttl) {
        String key = getUserMetadataKey(userId);
        redisTemplate.opsForHash().put(key, field, value);
        redisTemplate.expire(key, ttl);
    }

    @Override
    public Map<Object, Object> getMetadata(Long userId) {
        String key = getUserMetadataKey(userId);
        return redisTemplate.opsForHash().entries(key);
    }

    private String getUserStatusKey(Long userId) {
        return USER_STATUS_KEY_PREFIX + userId;
    }

    private String getUserMetadataKey(Long userId) {
        return USER_METADATA_KEY_PREFIX + userId;
    }
}
