package com.zzz.core.infrastructure.persistence;

import com.zzz.core.domain.couple.CoupleInviteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Repository;

import java.time.Duration;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class RedisCoupleInviteRepository implements CoupleInviteRepository {

    private final RedisTemplate<String, Object> redisTemplate;
    private static final String INVITE_CODE_PREFIX = "couple:invite:";

    @Override
    public void saveInviteCode(String code, Long userId, Duration ttl) {
        String key = INVITE_CODE_PREFIX + code;
        redisTemplate.opsForValue().set(key, userId.toString(), ttl);
    }

    @Override
    public Optional<Long> getUserIdByCode(String code) {
        String key = INVITE_CODE_PREFIX + code;
        String userIdStr = (String) redisTemplate.opsForValue().get(key);
        if (userIdStr != null) {
            return Optional.of(Long.parseLong(userIdStr));
        }
        return Optional.empty();
    }

    @Override
    public void deleteInviteCode(String code) {
        String key = INVITE_CODE_PREFIX + code;
        redisTemplate.delete(key);
    }
}
