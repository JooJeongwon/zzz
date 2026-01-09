package com.zzz.core.domain.couple;

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

    @Column(nullable = false)
    private Long userAId;

    @Column(nullable = false)
    private Long userBId;

    private LocalDateTime startedAt;

    public Couple(Long userAId, Long userBId) {
        this.userAId = userAId;
        this.userBId = userBId;
        this.startedAt = LocalDateTime.now();
    }
}
