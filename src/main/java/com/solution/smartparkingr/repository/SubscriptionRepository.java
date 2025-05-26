package com.solution.smartparkingr.repository;

import com.solution.smartparkingr.model.Subscription;
import com.solution.smartparkingr.model.SubscriptionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    @Query("SELECT s FROM Subscription s WHERE s.user.id = :userId AND s.status = :status")
    Optional<Subscription> findByUserIdAndStatus(@Param("userId") Long userId, @Param("status") SubscriptionStatus status);

    Optional<Subscription> findBySessionId(String sessionId);

    List<Subscription> findByEndDateBeforeAndStatus(LocalDate date, SubscriptionStatus status);

    @Query("SELECT s FROM Subscription s WHERE s.endDate BETWEEN :start AND :end AND s.status = 'ACTIVE'")
    List<Subscription> findExpiringSubscriptions(LocalDateTime start, LocalDateTime end);
}