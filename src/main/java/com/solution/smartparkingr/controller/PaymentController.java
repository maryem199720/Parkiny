package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.model.Payment;
import com.solution.smartparkingr.model.Reservation;
import com.solution.smartparkingr.model.ReservationStatus;
import com.solution.smartparkingr.model.Subscription;
import com.solution.smartparkingr.model.SubscriptionStatus;
import com.solution.smartparkingr.repository.PaymentRepository;
import com.solution.smartparkingr.repository.ReservationRepository;
import com.solution.smartparkingr.repository.SubscriptionRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/payment")
@Tag(name = "Payment API", description = "Endpoints for managing parking payments")
public class PaymentController {

    @Autowired
    private ReservationRepository reservationRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @PostMapping("/callback")
    @Operation(summary = "Handle payment callback", description = "Handles status update after payment (SUCCESS or FAILED)")
    public ResponseEntity<?> handlePaymentCallback(
            @RequestParam @Parameter(description = "Transaction session ID") String session,
            @RequestParam @Parameter(description = "Status from gateway: SUCCESS or FAILED") String status
    ) {
        Payment payment = paymentRepository.findByTransactionId(session)
                .orElseThrow(() -> new IllegalArgumentException("Paiement introuvable pour la session : " + session));

        if (payment.getReservation() != null) {
            Reservation reservation = payment.getReservation();
            if (reservation == null) {
                return ResponseEntity.badRequest().body("Réservation associée introuvable.");
            }

            if ("SUCCESS".equalsIgnoreCase(status)) {
                payment.setPaymentStatus("PENDING_CONFIRMED"); // Payment confirmed, awaiting reservation confirmation
            } else {
                payment.setPaymentStatus("FAILED");
                reservation.setStatus(ReservationStatus.CANCELLED);

                if (reservation.getParkingSpot() != null) {
                    reservation.getParkingSpot().setAvailable(true);
                    reservation.getParkingSpot().setVehicle(null);
                    reservationRepository.save(reservation); // Save parking spot changes
                }
            }
            reservationRepository.save(reservation);
        } else if (payment.getSubscription() != null) {
            Subscription subscription = payment.getSubscription();
            if ("SUCCESS".equalsIgnoreCase(status)) {
                payment.setPaymentStatus("COMPLETED");
                subscription.setPaymentStatus("COMPLETED");
                subscription.setStatus(SubscriptionStatus.ACTIVE);
            } else {
                payment.setPaymentStatus("FAILED");
                subscription.setPaymentStatus("FAILED");
                subscription.setStatus(SubscriptionStatus.CANCELLED);
            }
            subscriptionRepository.save(subscription);
        } else {
            return ResponseEntity.badRequest().body("Aucune réservation ou abonnement associé trouvé.");
        }

        payment.setPaymentDate(LocalDateTime.now());
        paymentRepository.save(payment);

        return ResponseEntity.ok("Statut de paiement mis à jour : " + status);
    }
}