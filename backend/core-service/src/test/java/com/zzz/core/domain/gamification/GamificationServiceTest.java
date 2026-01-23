package com.zzz.core.domain.gamification;

import com.zzz.core.domain.couple.Couple;
import com.zzz.core.domain.couple.CoupleRepository;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserRepository;
import com.zzz.core.domain.user.UserStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GamificationServiceTest {

    @InjectMocks
    private GamificationService gamificationService;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CoupleRepository coupleRepository;

    @Test
    @DisplayName("Wake Up (Sleep -> Online) grants 10 XP")
    void testWakeUpXp() {
        // Given
        Long userId = 1L;
        Long coupleId = 100L;
        User user = mock(User.class);
        when(user.getCoupleId()).thenReturn(coupleId);
        
        Couple couple = mock(Couple.class);
        when(couple.getLevel()).thenReturn(1);
        
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(coupleRepository.findById(coupleId)).thenReturn(Optional.of(couple));

        // When
        gamificationService.processStatusChange(userId, UserStatus.SLEEP, UserStatus.ONLINE);

        // Then
        verify(couple, times(1)).increaseXp(10);
        verify(coupleRepository, times(1)).save(couple);
    }
    
    @Test
    @DisplayName("Status change without specific rule grants no XP")
    void testNoXp() {
        // Given
        gamificationService.processStatusChange(1L, UserStatus.ONLINE, UserStatus.BUSY);
        
        // Then
        verify(coupleRepository, never()).save(any());
    }
}
