package com.zzz.core.domain.couple;

import com.zzz.core.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Getter
@Table(name = "couples")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Couple {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_a_id", nullable = false)
    private User userA;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_b_id", nullable = false)
    private User userB;

    private LocalDateTime startedAt;

    @Column(nullable = false)
    private int xp = 0;

    @Column(nullable = false)
    private int level = 1;

    private LocalDateTime syncStartTime;

    public Couple(User userA, User userB) {
        this.userA = userA;
        this.userB = userB;
        this.startedAt = LocalDateTime.now();
        this.xp = 0;
        this.level = 1;
    }

    public void increaseXp(int amount) {
        this.xp += amount;
        // Simple Level-up Logic: Level * 100 XP required for next level
        // e.g. Lv 1 -> 100 XP -> Lv 2
        // Lv 2 -> 200 XP -> Lv 3 (Total 300)
        while (this.xp >= getRequiredXpForNextLevel()) {
            this.xp -= getRequiredXpForNextLevel();
            this.level++;
        }
    }

    private int getRequiredXpForNextLevel() {
        return this.level * 100;
    }

    public void updateSyncState(LocalDateTime startTime) {
        this.syncStartTime = startTime;
    }
}
