package com.zzz.core.domain.couple;

import java.time.Duration;
import java.util.Optional;

public interface CoupleInviteRepository {
    void saveInviteCode(String code, Long userId, Duration ttl);
    Optional<Long> getUserIdByCode(String code);
    void deleteInviteCode(String code);
}
