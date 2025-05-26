package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.load.request.ReservationRequest;
import com.solution.smartparkingr.model.*;
import com.solution.smartparkingr.repository.*;
import com.solution.smartparkingr.service.*;
import io.jsonwebtoken.io.IOException;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.Duration;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import com.sendgrid.*;
import com.sendgrid.helpers.mail.Mail;
import com.sendgrid.helpers.mail.objects.Content;
import com.sendgrid.helpers.mail.objects.Email;

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
                    "message", "Place de parking introuvable"
            ));
        }
        ParkingSpot parkingSpot = parkingSpotOptional.get();

        // Check if the parking spot is already reserved for the requested time
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

        // Check for active subscription
        Optional<Subscription> activeSubscription = subscriptionRepository.findByUserIdAndStatus(
                user.getId(), SubscriptionStatus.ACTIVE
        );

        // Calculate the total cost
        double amount = calculateReservationCost(
                user,
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
        reservation = reservationService.save(reservation);

        // Create payment
        String sessionId = "SMT" + System.currentTimeMillis();
        Payment payment = new Payment(
                reservation,
                amount,
                reservationRequest.getPaymentMethod(),
                "PENDING",
                sessionId,
                LocalDateTime.now()
        );
        paymentRepository.save(payment);

        // Prepare reservation ID
        String reservationId = "RES-" + reservation.getId();

        // Generate and send payment verification code (only if payment is required)
        Map<String, Object> response = new HashMap<>();
        if (amount > 0) {
            String paymentVerificationCode = String.format("%06d", new Random().nextInt(999999));
            try {
                emailService.sendPaymentVerificationEmail(reservationRequest.getEmail(), paymentVerificationCode);
                reservationService.storePaymentVerificationCode(reservationId, paymentVerificationCode);
                response.put("message", "Réservation créée. Veuillez vérifier votre paiement avec le code envoyé par email.");
                response.put("reservationId", reservationId);
                response.put("paymentVerificationCode", paymentVerificationCode);
            } catch (IOException | java.io.IOException e) {
                System.err.println("Failed to send payment verification email: " + e.getMessage());
                return ResponseEntity.status(500).body(Map.of(
                        "error", "Internal Server Error",
                        "message", "Échec de l'envoi de l'email de vérification de paiement: " + e.getMessage()
                ));
            }
        } else {
            // If no payment is required (e.g., subscription covers it), proceed directly to reservation confirmation
            reservation.setStatus(ReservationStatus.CONFIRMED);
            reservationRepository.save(reservation);

            // Send final confirmation email with QR code
            Map<String, Object> emailDetails = new HashMap<>();
            emailDetails.put("reservationId", reservationId);
            emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
            emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
            emailDetails.put("placeName", reservation.getParkingSpot().getName());
            emailDetails.put("totalAmount", reservation.getTotalCost());
            emailDetails.put("qrCodeData", reservationId);

            try {
                emailService.sendReservationConfirmationEmail(reservation.getEmail(), reservationId, emailDetails);
            } catch (IOException | java.io.IOException e) {
                System.err.println("Failed to send reservation confirmation email: " + e.getMessage());
                return ResponseEntity.status(500).body(Map.of(
                        "error", "Internal Server Error",
                        "message", "Échec de l'envoi de l'email de confirmation finale: " + e.getMessage()
                ));
            }

            response.put("message", "Réservation confirmée avec succès (aucun paiement requis).");
            response.put("reservationId", reservationId);
        }

        return ResponseEntity.ok(response);
    }

    @PostMapping("/confirmPayment")
    public ResponseEntity<?> confirmPayment(
            @RequestParam Long reservationId,
            @RequestParam String paymentVerificationCode) {
        Optional<Reservation> reservationOptional = reservationRepository.findById(reservationId);
        if (!reservationOptional.isPresent()) {
            return ResponseEntity.badRequest().body("Réservation introuvable");
        }

        Reservation reservation = reservationOptional.get();
        Payment payment = paymentRepository.findFirstByReservationId(reservation.getId())
                .orElse(null);

        if (payment == null) {
            return ResponseEntity.badRequest().body("Aucun paiement trouvé pour cette réservation");
        }

        // Convert Long reservationId to String with "RES-" prefix to match stored format
        String formattedReservationId = "RES-" + reservationId;
        String storedVerificationCode = reservationService.getPaymentVerificationCode(formattedReservationId);
        if (storedVerificationCode == null || !storedVerificationCode.equals(paymentVerificationCode)) {
            return ResponseEntity.badRequest().body("Code de vérification de paiement invalide");
        }

        // Confirm payment
        payment.setPaymentStatus("CONFIRMED");
        paymentRepository.save(payment);

        // Generate and store reservation confirmation code
        String reservationConfirmationCode = String.format("%06d", new Random().nextInt(999999));
        reservationService.storeReservationConfirmationCode(formattedReservationId, reservationConfirmationCode);

        // Send email with reservation confirmation code
        Map<String, Object> emailDetails = new HashMap<>();
        emailDetails.put("reservationId", formattedReservationId);
        emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("placeName", reservation.getParkingSpot().getName());
        emailDetails.put("totalAmount", reservation.getTotalCost());
        emailDetails.put("reservationConfirmationCode", reservationConfirmationCode);

        String emailContent = "<h2>Confirmation de paiement</h2>" +
                "<p>Votre paiement pour la réservation (ID: " + formattedReservationId + ") a été confirmé.</p>" +
                "<h3>Détails de la réservation :</h3>" +
                "<ul>" +
                "<li><strong>ID de réservation :</strong> " + formattedReservationId + "</li>" +
                "<li><strong>Début :</strong> " + emailDetails.get("startTime") + "</li>" +
                "<li><strong>Fin :</strong> " + emailDetails.get("endTime") + "</li>" +
                "<li><strong>Place :</strong> " + emailDetails.get("placeName") + "</li>" +
                "<li><strong>Montant total :</strong> " + emailDetails.get("totalAmount") + " TND</li>" +
                "</ul>" +
                "<p>Votre code de confirmation de réservation est : <strong>" + reservationConfirmationCode + "</strong></p>" +
                "<p>Veuillez entrer ce code dans l'application pour finaliser votre réservation.</p>";

        Email from = new Email(fromEmail);
        String subject = "Code de confirmation de réservation";
        Email to = new Email(reservation.getEmail());
        Content content = new Content("text/html", emailContent);
        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(sendGridApiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            if (response.getStatusCode() != 202) {
                throw new IOException("Failed to send reservation confirmation code email: HTTP " + response.getStatusCode() + " - " + response.getBody());
            }
        } catch (IOException e) {
            System.err.println("Failed to send reservation confirmation code email: " + e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Échec de l'envoi de l'email avec le code de confirmation: " + e.getMessage()
            ));
        } catch (java.io.IOException e) {
            throw new RuntimeException(e);
        }

        return ResponseEntity.ok(Map.of(
                "message", "Paiement confirmé. Veuillez utiliser le code de confirmation envoyé par email pour finaliser la réservation.",
                "reservationId", formattedReservationId
        ));
    }

    @PostMapping("/confirmReservation")
    public ResponseEntity<?> confirmReservation(
            @RequestParam Long reservationId,
            @RequestParam String reservationConfirmationCode) {
        Optional<Reservation> reservationOptional = reservationRepository.findById(reservationId);
        if (!reservationOptional.isPresent()) {
            return ResponseEntity.badRequest().body("Réservation introuvable");
        }

        Reservation reservation = reservationOptional.get();
        // Verify the reservation confirmation code
        String formattedReservationId = "RES-" + reservationId;
        String storedCode = reservationService.getReservationConfirmationCode(formattedReservationId);
        if (storedCode == null || !storedCode.equals(reservationConfirmationCode)) {
            return ResponseEntity.badRequest().body("Code de confirmation de réservation invalide");
        }

        // Confirm the reservation
        reservation.setStatus(ReservationStatus.CONFIRMED);
        reservationRepository.save(reservation);

        // Send final confirmation email with QR code
        Map<String, Object> emailDetails = new HashMap<>();
        emailDetails.put("reservationId", formattedReservationId);
        emailDetails.put("startTime", reservation.getStartTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("endTime", reservation.getEndTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        emailDetails.put("placeName", reservation.getParkingSpot().getName());
        emailDetails.put("totalAmount", reservation.getTotalCost());
        emailDetails.put("qrCodeData", formattedReservationId);

        try {
            emailService.sendReservationConfirmationEmail(reservation.getEmail(), formattedReservationId, emailDetails);
        } catch (IOException | java.io.IOException e) {
            System.err.println("Failed to send reservation confirmation email: " + e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Échec de l'envoi de l'email de confirmation finale: " + e.getMessage()
            ));
        }

        return ResponseEntity.ok(Map.of("message", "Réservation confirmée avec succès"));
    }

    @PostMapping("/sendConfirmationEmail")
    public ResponseEntity<?> sendConfirmationEmail(@RequestBody Map<String, Object> request) {
        String email = (String) request.get("email");
        String reservationId = (String) request.get("reservationId");
        @SuppressWarnings("unchecked")
        Map<String, Object> details = (Map<String, Object>) request.get("details");
        try {
            emailService.sendReservationConfirmationEmail(email, reservationId, details);
            return ResponseEntity.ok(Map.of("message", "Confirmation email sent successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Failed to send confirmation email: " + e.getMessage()
            ));
        }
    }

    private double calculateReservationCost(User user, ParkingSpot parkingSpot, Optional<Subscription> activeSubscription,
                                            LocalDateTime startTime, LocalDateTime endTime) {
        double hourlyRate = parkingSpot.getType().equals("standard") ? 5.0 : 8.0;
        long hours = Duration.between(startTime, endTime).toHours();
        if (hours <= 0) hours = 1; // Minimum 1 hour

        double baseCost = hourlyRate * hours;

        // Check subscription
        if (activeSubscription.isPresent()) {
            Subscription subscription = activeSubscription.get();
            if (Boolean.TRUE.equals(subscription.getHasPremiumSpots()) && parkingSpot.getType().equals("premium")) {
                if (subscription.getRemainingPlaces() != null && subscription.getRemainingPlaces() > 0) {
                    // Free reservation for premium spot if subscription allows and places remain
                    return 0.0;
                }
            }
        }

        double finalCost = baseCost;

        // Apply long-duration discount
        if (hours > 5) {
            finalCost *= 0.9; // 10% discount for > 5 hours
        }

        return Math.round(finalCost * 100.0) / 100.0;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleValidationErrors(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error -> {
            errors.put(error.getField(), error.getDefaultMessage());
        });
        return ResponseEntity.badRequest().body(Map.of(
                "error", "Bad Request",
                "message", "Validation failed",
                "details", errors
        ));
    }
}