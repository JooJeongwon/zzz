package com.zzz.core.domain.user;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Getter
@Table(name = "users")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String nickname;

    @Column(nullable = false)
    private String password; // 실제로는 Encrypted

    private String timezone;

    private String fcmToken;

    @Enumerated(EnumType.STRING)
    private UserStatus status;

    private LocalDateTime lastActiveAt;

    private Long coupleId;

    @Builder
    public User(String email, String nickname, String password) {
        this.email = email;
        this.nickname = nickname;
        this.password = password;
        this.status = UserStatus.ONLINE;
        this.lastActiveAt = LocalDateTime.now();
        this.timezone = "Asia/Seoul";
    }

    public void updateTimezone(String timezone) {
        this.timezone = timezone;
    }

    public void updateFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public UserStatus updateStatus(UserStatus status) {
        UserStatus oldStatus = this.status;
        this.status = status;
        this.lastActiveAt = LocalDateTime.now();
        return oldStatus;
    }

    public UserStatus updateHeartbeat() {
        return updateHeartbeat(LocalDateTime.now());
    }

    public UserStatus updateHeartbeat(LocalDateTime timestamp) {
        UserStatus oldStatus = this.status;
        this.lastActiveAt = timestamp;
        // Assuming ONLINE if heartbeat is received, though logic might be more complex later
        if (this.status == UserStatus.UNKNOWN || this.status == UserStatus.SLEEP) {
             this.status = UserStatus.ONLINE;
        }
        return oldStatus;
    }

    public void setCoupleId(Long coupleId) {
        this.coupleId = coupleId;
    }
}
