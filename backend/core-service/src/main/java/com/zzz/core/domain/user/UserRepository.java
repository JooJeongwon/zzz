package com.zzz.core.domain.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    List<User> findByStatusAndLastActiveAtBefore(UserStatus status, LocalDateTime threshold);

    @Modifying
    @Query("UPDATE User u SET u.status = :newStatus WHERE u.lastActiveAt < :threshold AND u.status = :targetStatus")
    int updateStatusForInactiveUsers(@Param("targetStatus") UserStatus targetStatus, 
                                     @Param("threshold") LocalDateTime threshold, 
                                     @Param("newStatus") UserStatus newStatus);
}
