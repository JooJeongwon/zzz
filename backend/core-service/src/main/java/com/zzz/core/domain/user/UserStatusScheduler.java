package com.zzz.core.domain.user;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class UserStatusScheduler {

    private final UserRepository userRepository;
    private final UserStatusService userStatusService;

    private static final int INACTIVE_THRESHOLD_MINUTES = 30;

    /**
     * 주기적으로 실행되어 오랫동안 Heartbeat가 없는 사용자의 상태를 업데이트.
     * 실행 주기: 매 1분
     */
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoDetectSleepMode() {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(INACTIVE_THRESHOLD_MINUTES);
        
        // 1. Find candidates (ONLINE users inactive for 30 mins)
        List<User> inactiveUsers = userRepository.findByStatusAndLastActiveAtBefore(UserStatus.ONLINE, threshold);
        
        for (User user : inactiveUsers) {
            detectAndChangeStatus(user);
        }

        if (!inactiveUsers.isEmpty()) {
            log.info("Processed {} inactive users.", inactiveUsers.size());
        }
    }

    private void detectAndChangeStatus(User user) {
        Map<Object, Object> metadata = userStatusService.getUserMetadata(user.getId());
        
        // 1. Check Battery (Discharged)
        // Redis stores numbers as String or Integer depending on serializer. Safer to parse.
        int battery = parseBattery(metadata.get("battery"));
        if (battery >= 0 && battery < 5) {
            updateUserStatus(user, UserStatus.DISCHARGED, "Battery low (" + battery + "%)");
            return;
        }

        // 2. Check Sleep Time (Night time in user's timezone)
        String timezone = user.getTimezone() != null ? user.getTimezone() : "Asia/Seoul";
        try {
            ZoneId zoneId = ZoneId.of(timezone);
            ZonedDateTime userTime = ZonedDateTime.now(zoneId);
            int hour = userTime.getHour();

            // 23:00 ~ 06:00 is considered Sleep time
            if (hour >= 23 || hour < 6) {
                updateUserStatus(user, UserStatus.SLEEP, "Night time (" + hour + "h)");
                return;
            }
        } catch (Exception e) {
            log.warn("Invalid timezone for user {}: {}", user.getId(), timezone);
        }

        // 3. Default to UNKNOWN
        updateUserStatus(user, UserStatus.UNKNOWN, "Inactive");
    }

    private int parseBattery(Object batteryObj) {
        if (batteryObj == null) return -1;
        try {
            return Integer.parseInt(batteryObj.toString());
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private void updateUserStatus(User user, UserStatus newStatus, String reason) {
        log.info("Auto-changing status for user {} to {} (Reason: {})", user.getId(), newStatus, reason);
        user.updateStatus(newStatus);
        userRepository.save(user);
        userStatusService.updateStatus(user.getId(), newStatus);
    }
}
