package com.solution.smartparkingr.repository;

import com.solution.smartparkingr.model.VerificationCode;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VerificationCodeRepository extends JpaRepository<VerificationCode, String> {
}