package com.zzz.core.domain.user;

import java.time.Duration;
import java.util.Map;
import java.util.Optional;

public interface UserStatusRepository {
    void saveStatus(Long userId, UserStatus status, Duration ttl);
    Optional<UserStatus> getStatus(Long userId);
    
    void saveMetadata(Long userId, Map<String, Object> metadata, Duration ttl);
    void updateMetadataField(Long userId, String field, String value, Duration ttl);
    Map<Object, Object> getMetadata(Long userId);
}
