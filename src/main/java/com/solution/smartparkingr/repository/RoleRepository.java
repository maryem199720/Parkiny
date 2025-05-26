package com.solution.smartparkingr.repository;

import com.solution.smartparkingr.model.ERole;
import com.solution.smartparkingr.model.Role;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role,Long> {
    Optional<Role> findByName(ERole name);
}