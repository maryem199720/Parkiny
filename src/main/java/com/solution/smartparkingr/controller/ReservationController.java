package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.load.request.PaymentRequest;
import com.solution.smartparkingr.load.request.ReservationRequest;
import com.solution.smartparkingr.model.*;
import com.solution.smartparkingr.repository.*;
import com.solution.smartparkingr.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.Duration;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Random;

@RestController
@RequestMapping("/api")
public class ReservationController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private ReservationRepository reservationRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private ParkingSpotRepository parkingSpotRepository;

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Autowired
    private VehicleService vehicleService;

    @Autowired
    private UserService userService;

    @Autowired
    private ReservationService reservationService;

    @Autowired
    private ParkingSpotService parkingSpotService;

    @Autowired
    private SubscriptionService subscriptionService;

    @Autowired
    private EmailService emailService;

    @Value("${server.servlet.context-path:/}")
    private String contextPath;

    @Value("${sendgrid.api.key}")
    private String sendGridApiKey;

    @Value("${email.from}")
    private String fromEmail;

    @PostMapping("/createReservation")
    public ResponseEntity<?> reserveWithMatricule(@Valid @RequestBody ReservationRequest reservationRequest) {
        // Validate time constraints
        LocalDateTime now = LocalDateTime.now();
        if (reservationRequest.getStartTime().isAfter(reservationRequest.getEndTime()) ||
                reservationRequest.getStartTime().isBefore(now)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "L'heure de début doit être avant l'heure de fin et dans le futur"
            ));
        }

        // Validate user
        Optional<User> userOptional = userRepository.findById(reservationRequest.getUserId());
        if (!userOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Utilisateur introuvable"
            ));
        }
        User user = userOptional.get();

        // Validate vehicle
        Optional<Vehicle> vehicleOptional = vehicleRepository.findByMatricule(reservationRequest.getMatricule());
        if (!vehicleOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Véhicule introuvable avec cette matricule"
            ));
        }
        Vehicle vehicle = vehicleOptional.get();

        // Validate parking spot
        Optional<ParkingSpot> parkingSpotOptional = parkingSpotRepository.findById(reservationRequest.getParkingPlaceId());
        if (!parkingSpotOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Place de parking"
            ));
        }
        ParkingSpot parkingSpot = parkingSpotOptional.get();
        if (!parkingSpot.isAvailable()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "La place de parking n'est pas disponible"
            ));
        }

        // Check if the parking spot is already reserved
        boolean isSpotReserved = reservationService.isSpotReserved(
                parkingSpot.getId(),
                reservationRequest.getStartTime(),
                reservationRequest.getEndTime()
        );
        if (isSpotReserved) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "La place est déjà réservée pour cette période"
            ));
        }

        // Check subscription
        Optional<Subscription> activeSubscription = Optional.empty();
        boolean isFreeReservation = false;
        if (reservationRequest.getSubscriptionId() != null) {
            activeSubscription = subscriptionRepository.findById(reservationRequest.getSubscriptionId());
            if (!activeSubscription.isPresent() ||
                    activeSubscription.get().getUser().getId() != user.getId() ||
                    !activeSubscription.get().getStatus().equals(SubscriptionStatus.ACTIVE)) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", "Bad Request",
                        "message", "Abonnement invalide ou non actif"
                ));
            }
            // Check remaining places for free reservation
            if (activeSubscription.get().getRemainingPlaces() != null && activeSubscription.get().getRemainingPlaces() > 0) {
                isFreeReservation = true;
            }
        } else {
            activeSubscription = subscriptionRepository.findByUserIdAndStatus(user.getId(), SubscriptionStatus.ACTIVE);
            if (activeSubscription.isPresent() && activeSubscription.get().getRemainingPlaces() != null && activeSubscription.get().getRemainingPlaces() > 0) {
                isFreeReservation = true;
            }
        }

        // Calculate total cost
        double amount = calculateReservationCost(
                parkingSpot,
                activeSubscription,
                reservationRequest.getStartTime(),
                reservationRequest.getEndTime()
        );

        // Create reservation
        Reservation reservation = new Reservation();
        reservation.setUser(user);
        reservation.setVehicle(vehicle);
        reservation.setParkingSpot(parkingSpot);
        reservation.setStartTime(reservationRequest.getStartTime());
        reservation.setEndTime(reservationRequest.getEndTime());
        reservation.setStatus(ReservationStatus.PENDING);
        reservation.setTotalCost(amount);
        reservation.setCreatedAt(LocalDateTime.now());
        reservation.setEmail(reservationRequest.getEmail());
        // Save reservation
        reservation = reservationRepository.save(reservation);

        // Prepare response
        String sessionId = "SMT" + System.currentTimeMillis();
        Map<String, Object> response = new HashMap<>();
        String reservationId = "RES-" + reservation.getId();

        if (amount > 0 && !isFreeReservation) {
            // Create payment for non-free reservations
            Payment payment = new Payment(
                    reservation,
                    amount,
                    reservationRequest.getPaymentMethod(),
                    "PENDING",
                    sessionId,
                    LocalDateTime.now()
            );
            paymentRepository.save(payment);

            // Generate and store payment verification code
            String paymentVerificationCode = String.format("%06d", new Random().nextInt(999999));
            reservationService.storePaymentVerificationCode(reservationId, paymentVerificationCode);

            try {
                Map<String, Object> emailDetails = new HashMap<>();
                emailDetails.put("reservationId", reservationId);
                emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                emailDetails.put("placeName", reservation.getParkingSpot().getName());
                emailDetails.put("totalAmount", reservation.getTotalCost());
                emailDetails.put("vehicleMatricule", reservation.getVehicle().getMatricule());
                emailDetails.put("qrCodeData", reservationId);
                emailDetails.put("paymentVerificationCode", paymentVerificationCode);
                emailService.sendReservationConfirmationEmail(reservation.getEmail(), reservationId, emailDetails);
                response.put("message", "Réservation créée. Vérifiez votre email pour le code de vérification de paiement.");
                response.put("reservationId", reservationId);
                response.put("sessionId", sessionId);
                response.put("paymentVerificationCode", paymentVerificationCode); // Include in response for frontend
            } catch (IOException e) {
                return ResponseEntity.status(500).body(Map.of(
                        "error", "Internal Server Error",
                        "message", "Échec de l'envoi de l'email de confirmation : " + e.getMessage()
                ));
            }
        } else {
            // For free reservations (subscribed users)
            String reservationConfirmationCode = String.format("%06d", new Random().nextInt(999999));
            reservationService.storeReservationConfirmationCode(reservationId, reservationConfirmationCode);
            try {
                Map<String, Object> emailDetails = new HashMap<>();
                emailDetails.put("reservationId", reservationId);
                emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                emailDetails.put("placeName", reservation.getParkingSpot().getName());
                emailDetails.put("totalAmount", reservation.getTotalCost());
                emailDetails.put("vehicleMatricule", reservation.getVehicle().getMatricule());
                emailDetails.put("qrCodeData", reservationId);
                emailDetails.put("reservationConfirmationCode", reservationConfirmationCode);
                emailService.sendReservationConfirmationEmail(reservation.getEmail(), reservationId, emailDetails);
                response.put("message", "Réservation créée. Vérifiez votre email pour le code de confirmation.");
                response.put("reservationId", reservationId);
                response.put("reservationConfirmationCode", reservationConfirmationCode);
            } catch (IOException e) {
                return ResponseEntity.status(500).body(Map.of(
                        "error", "Internal Server Error",
                        "message", "Échec de l'envoi de l'email de confirmation : " + e.getMessage()
                ));
            }
        }

        return ResponseEntity.ok(response);
    }
    @PostMapping("/payment/processPayment")
    public ResponseEntity<?> processPayment(@Valid @RequestBody PaymentRequest paymentRequest) {
        Optional<Reservation> reservationOptional = reservationRepository.findById(paymentRequest.getReservationId());
        if (!reservationOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Réservation introuvable"
            ));
        }
        Reservation reservation = reservationOptional.get();
        Payment payment = paymentRepository.findFirstByReservationId(reservation.getId())
                .orElse(null);

        if (payment == null) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Aucun paiement trouvé pour cette réservation"
            ));
        }

        // Validate amount
        if (!paymentRequest.getAmount().equals(payment.getAmount())) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Le montant du paiement ne correspond pas"
            ));
        }

        // Update payment details
        payment.setPaymentMethod(paymentRequest.getPaymentMethod());
        payment.setPaymentReference(paymentRequest.getPaymentReference());
        paymentRepository.save(payment);

        // Generate and send payment verification code
        String reservationId = "RES-" + reservation.getId();
        String paymentVerificationCode = String.format("%06d", new Random().nextInt(999999));
        reservationService.storePaymentVerificationCode(reservationId, paymentVerificationCode);

        try {
            Map<String, Object> emailDetails = new HashMap<>();
            emailDetails.put("reservationId", reservationId);
            emailDetails.put("paymentVerificationCode", paymentVerificationCode);
            emailService.sendPaymentVerificationEmail(reservation.getEmail(), paymentVerificationCode);
            return ResponseEntity.ok(Map.of(
                    "message", "Paiement soumis. Vérifiez votre email pour le code de vérification.",
                    "reservationId", reservationId,
                    "paymentVerificationCode", paymentVerificationCode
            ));
        } catch (IOException e) {
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Échec de l'envoi de l'email de vérification : " + e.getMessage()
            ));
        }
    }

    @PostMapping("/confirmPayment")
    public ResponseEntity<?> confirmPayment(
            @RequestParam String reservationId,
            @RequestParam String paymentVerificationCode) {
        Long numericId;
        String formattedReservationId;
        try {
            if (reservationId.startsWith("RES-")) {
                numericId = Long.parseLong(reservationId.replace("RES-", ""));
                formattedReservationId = reservationId;
            } else {
                numericId = Long.parseLong(reservationId);
                formattedReservationId = "RES-" + reservationId;
            }
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "ID de réservation invalide"
            ));
        }

        Optional<Reservation> reservationOptional = reservationRepository.findById(numericId);
        if (!reservationOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Réservation introuvable"
            ));
        }

        Reservation reservation = reservationOptional.get();
        Payment payment = paymentRepository.findFirstByReservationId(reservation.getId())
                .orElse(null);

        if (payment == null) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Aucun paiement trouvé pour cette réservation"
            ));
        }

        String storedVerificationCode = reservationService.getPaymentVerificationCode(formattedReservationId);
        if (storedVerificationCode == null || !storedVerificationCode.equals(paymentVerificationCode)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Code de vérification de paiement invalide"
            ));
        }

        // Confirm payment
        payment.setPaymentStatus("CONFIRMED");
        paymentRepository.save(payment);

        // Confirm reservation
        reservation.setStatus(ReservationStatus.CONFIRMED);
        reservationRepository.save(reservation);

        // Send final confirmation email
        Map<String, Object> emailDetails = new HashMap<>();
        emailDetails.put("reservationId", formattedReservationId);
        emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("placeName", reservation.getParkingSpot().getName());
        emailDetails.put("totalAmount", reservation.getTotalCost());
        emailDetails.put("vehicleMatricule", reservation.getVehicle().getMatricule());
        emailDetails.put("qrCodeData", formattedReservationId);

        try {
            emailService.sendReservationConfirmationEmail(reservation.getEmail(), formattedReservationId, emailDetails);
        } catch (IOException e) {
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Échec de l'envoi de l'email de confirmation : " + e.getMessage()
            ));
        }

        return ResponseEntity.ok(Map.of(
                "message", "Réservation confirmée avec succès.",
                "reservationId", formattedReservationId,
                "details", Map.of(
                        "startTime", emailDetails.get("startTime"),
                        "endTime", emailDetails.get("endTime"),
                        "placeName", emailDetails.get("placeName"),
                        "totalAmount", emailDetails.get("totalAmount"),
                        "vehicleMatricule", emailDetails.get("vehicleMatricule")
                )
        ));
    }

    @PostMapping("/confirmReservation")
    public ResponseEntity<?> confirmReservation(
            @RequestParam String reservationId,
            @RequestParam String reservationConfirmationCode) {
        Long numericId;
        try {
            if (!reservationId.startsWith("RES-")) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", "Bad Request",
                        "message", "Format d'ID de réservation invalide"
                ));
            }
            numericId = Long.parseLong(reservationId.replace("RES-", ""));
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "ID de réservation invalide"
            ));
        }

        Optional<Reservation> reservationOptional = reservationRepository.findById(numericId);
        if (!reservationOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Réservation introuvable"
            ));
        }

        Reservation reservation = reservationOptional.get();
        String storedCode = reservationService.getReservationConfirmationCode(reservationId);
        if (storedCode == null || !storedCode.equals(reservationConfirmationCode)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Code de confirmation de réservation invalide"
            ));
        }

        // Confirm the reservation
        reservation.setStatus(ReservationStatus.CONFIRMED);
        reservationRepository.save(reservation);

        // Update subscription remaining places
        if (reservation.getTotalCost() == 0) {
            Optional<Subscription> subscription = subscriptionRepository.findByUserIdAndStatus(
                    reservation.getUser().getId(), SubscriptionStatus.ACTIVE);
            if (subscription.isPresent()) {
                Integer remainingPlaces = subscription.get().getRemainingPlaces();
                if (remainingPlaces != null && remainingPlaces > 0) {
                    subscription.get().setRemainingPlaces(remainingPlaces - 1);
                    subscriptionRepository.save(subscription.get());
                }
            }
        }

        // Send final confirmation email
        Map<String, Object> emailDetails = new HashMap<>();
        emailDetails.put("reservationId", reservationId);
        emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("placeName", reservation.getParkingSpot().getName());
        emailDetails.put("totalAmount", reservation.getTotalCost());
        emailDetails.put("vehicleMatricule", reservation.getVehicle().getMatricule());
        emailDetails.put("qrCodeData", reservationId);

        try {
            emailService.sendReservationConfirmationEmail(reservation.getEmail(), reservationId, emailDetails);
        } catch (IOException e) {
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Échec de l'envoi de l'email de confirmation finale : " + e.getMessage()
            ));
        }

        return ResponseEntity.ok(Map.of(
                "message", "Réservation confirmée avec succès",
                "reservationId", reservationId
        ));
    }

    @PostMapping("/resendConfirmation")
    public ResponseEntity<?> resendConfirmation(@RequestParam String reservationId) {
        Long numericId;
        try {
            if (!reservationId.startsWith("RES-")) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", "Bad Request",
                        "message", "Format d'ID de réservation invalide"
                ));
            }
            numericId = Long.parseLong(reservationId.replace("RES-", ""));
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "ID de réservation invalide"
            ));
        }

        Optional<Reservation> reservationOptional = reservationRepository.findById(numericId);
        if (!reservationOptional.isPresent()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Réservation introuvable"
            ));
        }

        Reservation reservation = reservationOptional.get();
        Payment payment = paymentRepository.findFirstByReservationId(reservation.getId())
                .orElse(null);

        if (payment != null && "PENDING".equals(payment.getPaymentStatus())) {
            // Resend payment verification code
            String paymentVerificationCode = String.format("%06d", new Random().nextInt(999999));
            reservationService.storePaymentVerificationCode(reservationId, paymentVerificationCode);
            try {
                Map<String, Object> emailDetails = new HashMap<>();
                emailDetails.put("reservationId", reservationId);
                emailDetails.put("paymentVerificationCode", paymentVerificationCode);
                emailService.sendPaymentVerificationEmail(reservation.getEmail(), paymentVerificationCode);
                return ResponseEntity.ok(Map.of(
                        "message", "Email de vérification de paiement renvoyé avec succès"
                ));
            } catch (IOException e) {
                return ResponseEntity.status(500).body(Map.of(
                        "error", "Internal Server Error",
                        "message", "Échec de l'envoi de l'email de vérification : " + e.getMessage()
                ));
            }
        } else if (reservation.getTotalCost() == 0) {
            // Resend reservation confirmation code
            String reservationConfirmationCode = String.format("%06d", new Random().nextInt(999999));
            reservationService.storeReservationConfirmationCode(reservationId, reservationConfirmationCode);
            try {
                Map<String, Object> emailDetails = new HashMap<>();
                emailDetails.put("reservationId", reservationId);
                emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                emailDetails.put("placeName", reservation.getParkingSpot().getName());
                emailDetails.put("totalAmount", reservation.getTotalCost());
                emailDetails.put("vehicleMatricule", reservation.getVehicle().getMatricule());
                emailDetails.put("qrCodeData", reservationId);
                emailDetails.put("reservationConfirmationCode", reservationConfirmationCode);
                emailService.sendReservationConfirmationEmail(reservation.getEmail(), reservationId, emailDetails);
                return ResponseEntity.ok(Map.of(
                        "message", "Email de confirmation renvoyé avec succès"
                ));
            } catch (IOException e) {
                return ResponseEntity.status(500).body(Map.of(
                        "error", "Internal Server Error",
                        "message", "Échec de l'envoi de l'email de confirmation : " + e.getMessage()
                ));
            }
        } else {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", "Aucune confirmation en attente pour cette réservation"
            ));
        }
    }

    private double calculateReservationCost(
            ParkingSpot parkingSpot,
            Optional<Subscription> activeSubscription,
            LocalDateTime startTime,
            LocalDateTime endTime) {
        double hourlyRate = parkingSpot.getType().equalsIgnoreCase("standard") ? 5.0 : 8.0;
        long hours = Duration.between(startTime, endTime).toHours();
        if (hours <= 0) {
            hours = 1; // Minimum 1 hour
        }

        double baseCost = hours * hourlyRate;

        // Check subscription
        if (activeSubscription.isPresent()) {
            Subscription subscription = activeSubscription.get();
            if (subscription.getHasPremiumSpots() != null &&
                    subscription.getHasPremiumSpots() &&
                    parkingSpot.getType().equalsIgnoreCase("premium")) {
                Integer remainingPlaces = subscription.getRemainingPlaces();
                if (remainingPlaces != null && remainingPlaces > 0) {
                    // Free reservation for premium spot if places remain
                    return 0.0;
                }
            }
        }

        double cost = baseCost;

        // Apply long-duration discount
        if (hours > 5) {
            cost *= 0.9; // 10% discount for >5 hours
        }

        return Math.round(cost * 100.0) / 100.0;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleValidationErrors(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error -> {
            errors.put(error.getField(), error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid value");
        });
        return ResponseEntity.badRequest().body(Map.of(
                "error", "Bad Request",
                "message", "Validation failed",
                "details", errors
        ));
    }
}