package com.solution.smartparkingr.repository;

import com.solution.smartparkingr.model.User;
import com.solution.smartparkingr.model.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    Optional<Vehicle> findByUser(User user);

    Optional<Vehicle> findByMatricule(String matricule);
    List<Vehicle> findByUserId(Long userId);

    List<Vehicle> findAllByUser(User user);

    boolean existsByMatricule(String matricule);

    void deleteByMatricule(String matricule);

    List<Vehicle> findByMatriculeContainingIgnoreCase(String keyword);

    long countByUser(User user);
}
