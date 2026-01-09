package com.zzz.core.domain.user;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class UserStatusScheduler {

    private final UserRepository userRepository;

    private static final int INACTIVE_THRESHOLD_MINUTES = 30;

    /**
     * 주기적으로 실행되어 오랫동안 Heartbeat가 없는 사용자의 상태를 SLEEP으로 변경.
     * 실행 주기: 매 1분
     */
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoDetectSleepMode() {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(INACTIVE_THRESHOLD_MINUTES);
        
        int updatedCount = userRepository.updateStatusForInactiveUsers(
                UserStatus.ONLINE, 
                threshold, 
                UserStatus.SLEEP
        );

        if (updatedCount > 0) {
            log.info("Auto-updated {} users to SLEEP mode (Inactive for {} mins)", updatedCount, INACTIVE_THRESHOLD_MINUTES);
        }
    }
}
