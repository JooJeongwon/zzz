package com.zzz.core.domain.couple;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CoupleRepository extends JpaRepository<Couple, Long> {
    @EntityGraph(attributePaths = {"userA", "userB"})
    Optional<Couple> findById(Long id);

    @EntityGraph(attributePaths = {"userA", "userB"})
    Optional<Couple> findByUserA_IdOrUserB_Id(Long userAId, Long userBId);
}
