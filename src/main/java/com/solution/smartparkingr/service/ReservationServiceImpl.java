package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.Reservation;
import com.solution.smartparkingr.model.ReservationStatus;
import com.solution.smartparkingr.model.Subscription;
import com.solution.smartparkingr.model.SubscriptionStatus;
import com.solution.smartparkingr.model.VerificationCode;
import com.solution.smartparkingr.repository.ReservationRepository;
import com.solution.smartparkingr.repository.SubscriptionRepository;
import com.solution.smartparkingr.repository.VerificationCodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ReservationServiceImpl implements ReservationService {

    private final ReservationRepository reservationRepository;
    private final VerificationCodeRepository verificationCodeRepository;
    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Autowired
    public ReservationServiceImpl(ReservationRepository reservationRepository, VerificationCodeRepository verificationCodeRepository) {
        this.reservationRepository = reservationRepository;
        this.verificationCodeRepository = verificationCodeRepository;
    }

    @Override
    public Reservation save(Reservation reservation) {
        // Check if this is a free reservation due to subscription
        if (reservation.getTotalCost() == 0.0) {
            Optional<Subscription> activeSubscription = subscriptionRepository.findByUserIdAndStatus(
                    reservation.getUser().getId(), SubscriptionStatus.ACTIVE);
            activeSubscription.ifPresent(subscription -> {
                if (subscription.getRemainingPlaces() != null && subscription.getRemainingPlaces() > 0) {
                    subscription.setRemainingPlaces(subscription.getRemainingPlaces() - 1);
                    subscriptionRepository.save(subscription);
                }
            });
        }
        return reservationRepository.save(reservation);
    }

    @Override
    public Optional<Reservation> findById(Long id) {
        return reservationRepository.findById(id);
    }

    @Override
    public List<Reservation> findAll() {
        return reservationRepository.findAll();
    }

    @Override
    public void deleteById(Long id) {
        reservationRepository.deleteById(id);
    }

    @Override
    public List<Reservation> findByUserId(Long userId) {
        return reservationRepository.findByUserId(userId);
    }

    @Override
    public List<Reservation> findByParkingSpotId(Long parkingSpotId) {
        return reservationRepository.findByParkingSpot_Id(parkingSpotId);
    }

    @Override
    public List<Reservation> findActiveReservations() {
        return reservationRepository.findByStatus(ReservationStatus.CONFIRMED);
    }

    @Override
    public void cancelReservation(Long reservationId) {
        Optional<Reservation> reservation = reservationRepository.findById(reservationId);
        reservation.ifPresent(r -> {
            r.setStatus(ReservationStatus.CANCELLED);
            reservationRepository.save(r);
        });
    }

    @Override
    public boolean isSpotReserved(Long parkingSpotId, LocalDateTime startTime, LocalDateTime endTime) {
        List<Reservation> conflictingReservations = reservationRepository.findByParkingSpotIdAndTimeOverlap(
                parkingSpotId, startTime, endTime);
        return !conflictingReservations.isEmpty();
    }

    @Override
    public void storePaymentVerificationCode(String reservationId, String code) {
        LocalDateTime expiryDate = LocalDateTime.now().plusMinutes(15); // Expire in 15 minutes
        VerificationCode verificationCode = new VerificationCode(reservationId, code, expiryDate);
        verificationCodeRepository.save(verificationCode);
    }

    @Override
    public String getPaymentVerificationCode(String reservationId) {
        Optional<VerificationCode> verificationCode = verificationCodeRepository.findById(reservationId);
        if (verificationCode.isPresent() && verificationCode.get().getExpiryDate().isAfter(LocalDateTime.now())) {
            return verificationCode.get().getCode();
        }
        return null; // Return null if expired or not found
    }

    @Override
    public void storeReservationConfirmationCode(String reservationId, String code) {
        LocalDateTime expiryDate = LocalDateTime.now().plusMinutes(15); // Expire in 15 minutes
        VerificationCode verificationCode = new VerificationCode(reservationId + "_RES", code, expiryDate);
        verificationCodeRepository.save(verificationCode);
    }

    @Override
    public String getReservationConfirmationCode(String reservationId) {
        Optional<VerificationCode> verificationCode = verificationCodeRepository.findById(reservationId + "_RES");
        if (verificationCode.isPresent() && verificationCode.get().getExpiryDate().isAfter(LocalDateTime.now())) {
            return verificationCode.get().getCode();
        }
        return null; // Return null if expired or not found
    }
}