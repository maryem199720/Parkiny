package com.solution.smartparkingr.repository;

import com.solution.smartparkingr.model.ParkingSpot;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ParkingSpotRepository extends JpaRepository<ParkingSpot, Long> {
    Optional<ParkingSpot> findFirstByAvailableTrue();
    boolean existsByName(String name);
}