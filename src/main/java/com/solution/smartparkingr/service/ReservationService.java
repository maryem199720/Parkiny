package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.Reservation;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ReservationService {
    Reservation save(Reservation reservation);
    Optional<Reservation> findById(Long id);
    List<Reservation> findAll();
    void deleteById(Long id);
    void storeReservationConfirmationCode(String reservationId, String code);
    String getReservationConfirmationCode(String reservationId);
    // Custom methods
    List<Reservation> findByUserId(Long userId);
    List<Reservation> findByParkingSpotId(Long parkingSpotId);
    List<Reservation> findActiveReservations();
    void cancelReservation(Long reservationId);

    boolean isSpotReserved(Long parkingSpotId, @NotNull(message = "Start time is required") LocalDateTime startTime,
                           @NotNull(message = "End time is required") LocalDateTime endTime);

    // New methods for payment verification
    void storePaymentVerificationCode(String reservationId, String code);
    String getPaymentVerificationCode(String reservationId);
}