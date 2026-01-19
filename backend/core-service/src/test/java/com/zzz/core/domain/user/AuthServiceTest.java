package com.zzz.core.domain.user;

import com.zzz.core.api.dto.TokenResponse;
import com.zzz.core.api.dto.UserLoginRequest;
import com.zzz.core.api.dto.UserRegisterRequest;
import com.zzz.core.global.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @InjectMocks
    private AuthService authService;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    private User user;
    private final String EMAIL = "test@example.com";
    private final String PASSWORD = "password";
    private final String ENCODED_PASSWORD = "encoded_password";
    private final String NICKNAME = "tester";
    private final Long USER_ID = 1L;

    @BeforeEach
    void setUp() {
        user = User.builder()
                .email(EMAIL)
                .nickname(NICKNAME)
                .password(ENCODED_PASSWORD)
                .build();
    }

    @Test
    @DisplayName("register: 새로운 사용자를 저장하고 ID를 반환한다")
    void register_ShouldSaveUser() {
        // given
        UserRegisterRequest request = UserRegisterRequest.builder()
                .email(EMAIL)
                .password(PASSWORD)
                .nickname(NICKNAME)
                .build();

        given(userRepository.existsByEmail(EMAIL)).willReturn(false);
        given(passwordEncoder.encode(PASSWORD)).willReturn(ENCODED_PASSWORD);
        
        // Mocking save to return user with ID (simulated)
        // Since we can't set ID on User (no setter), we have to mock the return of save
        // But save returns the entity passed to it usually, unless we mock it to return a new instance or spy.
        // The real UserRepository.save returns the entity. 
        // User.getId() is generated.
        // For this test, we might rely on the fact that 'save' is called.
        // Or we can assume the service returns user.getId(). Since user.getId() is null initially,
        // we might face NPE if the service relies on it being set by DB.
        // AuthService.register returns userRepository.save(user).getId();
        // So we MUST return a user with ID from mock.
        
        // Reflection to set ID for testing? Or spy.
        // Let's use reflection to set ID on the 'user' object for this test scenario?
        // Or simpler: just mock save to return a mock User that has ID.
        
        given(userRepository.save(any(User.class))).willAnswer(invocation -> {
            User savedUser = invocation.getArgument(0);
            // Simulate ID generation
            java.lang.reflect.Field idField = User.class.getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(savedUser, USER_ID);
            return savedUser;
        });

        // when
        Long resultId = authService.register(request);

        // then
        assertThat(resultId).isEqualTo(USER_ID);
        verify(userRepository).save(any(User.class));
    }

    @Test
    @DisplayName("register: 이미 존재하는 이메일이면 예외를 던진다")
    void register_ShouldThrowException_WhenEmailExists() {
        // given
        UserRegisterRequest request = UserRegisterRequest.builder()
                .email(EMAIL)
                .build();

        given(userRepository.existsByEmail(EMAIL)).willReturn(true);

        // when & then
        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Already exists email");
    }

    @Test
    @DisplayName("login: 비밀번호가 일치하면 토큰을 반환한다")
    void login_ShouldReturnToken_WhenCredentialsValid() {
        // given
        UserLoginRequest request = UserLoginRequest.builder()
                .email(EMAIL)
                .password(PASSWORD)
                .build();

        // Reflection to set ID on 'user' for login test
        try {
            java.lang.reflect.Field idField = User.class.getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(user, USER_ID);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(user));
        given(passwordEncoder.matches(PASSWORD, ENCODED_PASSWORD)).willReturn(true);
        given(jwtTokenProvider.createToken(USER_ID, EMAIL)).willReturn("access_token");
        given(jwtTokenProvider.createRefreshToken(USER_ID, EMAIL)).willReturn("refresh_token");

        // when
        TokenResponse response = authService.login(request);

        // then
        assertThat(response.getAccessToken()).isEqualTo("access_token");
        assertThat(response.getRefreshToken()).isEqualTo("refresh_token");
        assertThat(response.getUserId()).isEqualTo(USER_ID);
    }

    @Test
    @DisplayName("login: 비밀번호가 틀리면 예외를 던진다")
    void login_ShouldThrowException_WhenPasswordInvalid() {
        // given
        UserLoginRequest request = UserLoginRequest.builder()
                .email(EMAIL)
                .password("wrong_password")
                .build();

        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(user));
        given(passwordEncoder.matches("wrong_password", ENCODED_PASSWORD)).willReturn(false);

        // when & then
        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid password");
    }
}
