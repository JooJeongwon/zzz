package com.zzz.core.domain.user;

import com.zzz.core.api.dto.HeartbeatRequest;
import com.zzz.core.domain.gamification.GamificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserStatusServiceTest {

    @InjectMocks
    private UserStatusService userStatusService;

    @Mock
    private UserStatusRepository userStatusRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private GamificationService gamificationService;

    private User user;
    private final Long USER_ID = 1L;

    @BeforeEach
    void setUp() {
        user = User.builder()
                .email("test@example.com")
                .nickname("tester")
                .password("password")
                .build();
    }

    @Test
    @DisplayName("updateHeartbeat: 최신 데이터면 Redis와 DB 모두 갱신한다")
    void updateHeartbeat_ShouldUpdateRedisAndDb_WhenDataIsRecent() {
        // given
        HeartbeatRequest request = HeartbeatRequest.builder()
                .batteryLevel(80)
                .isScreenOn(true)
                .timestamp(System.currentTimeMillis())
                .build();

        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        // when
        UserStatus result = userStatusService.updateHeartbeat(USER_ID, request);

        // then
        // 1. Redis Saved
        verify(userStatusRepository).saveStatus(eq(USER_ID), eq(UserStatus.ONLINE), any(Duration.class));
        verify(userStatusRepository).saveMetadata(eq(USER_ID), any(), any(Duration.class));
        
        // 2. DB Saved
        verify(userRepository).save(user);
        
        // 3. Gamification Triggered
        verify(gamificationService).processStatusChange(eq(USER_ID), any(), any());
    }

    @Test
    @DisplayName("updateHeartbeat: 오래된 데이터면 Redis는 갱신하지 않고 DB만 갱신한다")
    void updateHeartbeat_ShouldSkipRedis_WhenDataIsOld() {
        // given
        // 30 minutes ago
        long oldTime = System.currentTimeMillis() - Duration.ofMinutes(30).toMillis();
        
        HeartbeatRequest request = HeartbeatRequest.builder()
                .batteryLevel(80)
                .isScreenOn(true)
                .timestamp(oldTime)
                .build();

        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        // when
        userStatusService.updateHeartbeat(USER_ID, request);

        // then
        // 1. Redis Update Skipped (saveStatus should NOT be called)
        verify(userStatusRepository, never()).saveStatus(anyLong(), any(), any());
        
        // 2. DB Saved (History is preserved)
        verify(userRepository).save(user);
        
        // 3. Gamification Triggered (Even for old data processing? Logic says yes)
        verify(gamificationService).processStatusChange(eq(USER_ID), any(), any());
    }

    @Test
    @DisplayName("updateStatus: 수동 변경 시 Redis와 DB에 반영된다")
    void updateStatus_ShouldUpdateRedisAndDb() {
        // given
        UserStatus newStatus = UserStatus.STUDY;
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        // when
        userStatusService.updateStatus(USER_ID, newStatus);

        // then
        verify(userStatusRepository).saveStatus(eq(USER_ID), eq(newStatus), any(Duration.class));
        verify(userStatusRepository).updateMetadataField(eq(USER_ID), eq("updatedAt"), anyString(), any(Duration.class));
        verify(userRepository).save(user);
        verify(gamificationService).processStatusChange(eq(USER_ID), any(), eq(newStatus));
    }
}
