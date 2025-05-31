package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.load.request.SubscriptionRequest;
import com.solution.smartparkingr.model.Subscription;
import com.solution.smartparkingr.model.SubscriptionPlan;
import com.solution.smartparkingr.model.User;
import com.solution.smartparkingr.model.Role;
import com.solution.smartparkingr.model.ERole;
import com.solution.smartparkingr.model.Payment;
import com.solution.smartparkingr.model.SubscriptionStatus;
import com.solution.smartparkingr.repository.SubscriptionPlanRepository;
import com.solution.smartparkingr.repository.SubscriptionRepository;
import com.solution.smartparkingr.repository.UserRepository;
import com.solution.smartparkingr.repository.RoleRepository;
import com.solution.smartparkingr.repository.PaymentRepository;
import com.solution.smartparkingr.service.SubscriptionService;
import com.solution.smartparkingr.service.EmailService;
import io.jsonwebtoken.io.IOException;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.HashSet;
import java.util.Set;
import java.util.Random;

@RestController
@RequestMapping("/api")
public class SubscriptionController {

    @Autowired
    private SubscriptionService subscriptionService;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private EmailService emailService;

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Value("${server.servlet.context-path:/}")
    private String contextPath;

    @Autowired
    private SubscriptionPlanRepository subscriptionPlanRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @GetMapping("/subscription-plans")
    public ResponseEntity<List<SubscriptionPlan>> getSubscriptionPlans() {
        List<SubscriptionPlan> plans = subscriptionPlanRepository.findAll();
        return ResponseEntity.ok(plans);
    }

    @PostMapping("/subscription-plans")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createSubscriptionPlan(@Valid @RequestBody SubscriptionPlan plan) {
        if (plan.getId() != null) {
            return ResponseEntity.badRequest().body(Map.of("message", "ID must not be provided for creating a new subscription plan"));
        }
        Set<String> allowedTypes = Set.of("Basique", "Premium", "Entreprise");
        if (!allowedTypes.contains(plan.getType())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Only Basique, Premium, or Entreprise types are allowed"));
        }
        SubscriptionPlan savedPlan = subscriptionPlanRepository.save(plan);
        return ResponseEntity.ok(Map.of("message", "Plan créé avec succès", "id", savedPlan.getId()));
    }

    @PutMapping("/subscription-plans/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateSubscriptionPlan(@PathVariable Long id, @Valid @RequestBody SubscriptionPlan plan) {
        if (plan.getId() == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "ID must be provided for updating a subscription plan"));
        }
        if (!plan.getId().equals(id)) {
            return ResponseEntity.badRequest().body(Map.of("message", "ID in request body must match the path variable"));
        }
        Optional<SubscriptionPlan> existingPlan = subscriptionPlanRepository.findById(id);
        if (existingPlan.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        SubscriptionPlan updatedPlan = existingPlan.get();
        updatedPlan.setType(plan.getType());
        updatedPlan.setMonthlyPrice(plan.getMonthlyPrice());
        updatedPlan.setParkingDurationLimit(plan.getParkingDurationLimit());
        updatedPlan.setAdvanceReservationDays(plan.getAdvanceReservationDays());
        updatedPlan.setHasPremiumSpots(plan.getHasPremiumSpots());
        updatedPlan.setHasValetService(plan.getHasValetService());
        updatedPlan.setSupportLevel(plan.getSupportLevel());
        updatedPlan.setRemainingPlacesPerMonth(plan.getRemainingPlacesPerMonth());
        updatedPlan.setIsPopular(plan.getIsPopular());
        subscriptionPlanRepository.save(updatedPlan);
        return ResponseEntity.ok(Map.of("message", "Plan mis à jour avec succès"));
    }

    @PostMapping("/admin/register")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> registerAdmin(@Valid @RequestBody User newUser) {
        if (userRepository.existsByEmail(newUser.getEmail())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Email already in use"));
        }
        if (userRepository.existsByPhone(newUser.getPhone())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Phone number already in use"));
        }
        Set<Role> adminRoles = new HashSet<>();
        Role adminRole = roleRepository.findByName(ERole.ROLE_ADMIN)
                .orElseThrow(() -> new RuntimeException("ROLE_ADMIN not found in database"));
        adminRoles.add(adminRole);
        newUser.setRoles(adminRoles);
        newUser.setPassword(passwordEncoder.encode(newUser.getPassword()));
        userRepository.save(newUser);
        return ResponseEntity.ok(Map.of("message", "Admin registered successfully"));
    }

    @PostMapping("/subscribe")
    public ResponseEntity<?> subscribe(@Valid @RequestBody SubscriptionRequest request) {
        Long userId;
        try {
            userId = Long.parseLong(request.getUserId());
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid user ID format. Must be a valid number."));
        }

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "User not found"));
        }
        User user = userOpt.get();

        Optional<SubscriptionPlan> planOpt = subscriptionPlanRepository.findByType(request.getSubscriptionType());
        if (planOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Subscription plan not found"));
        }
        SubscriptionPlan plan = planOpt.get();
        double amount = request.getAmount() != null ? request.getAmount() :
                "monthly".equalsIgnoreCase(request.getBillingCycle()) ? plan.getMonthlyPrice() : plan.getMonthlyPrice() * 12 * 0.8;

        // Validate card details (if applicable)
        if ("CARTE_BANCAIRE".equalsIgnoreCase(request.getPaymentMethod().name())) {
            if (request.getCardNumber() == null || request.getCardNumber().length() != 16 ||
                    request.getExpiryDate() == null || !request.getExpiryDate().matches("^(0[1-9]|1[0-2])/[0-9]{2}$") ||
                    request.getCvv() == null || request.getCvv().length() != 3 ||
                    request.getCardName() == null || request.getCardName().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Invalid card details"));
            }
        }

        String sessionId = subscriptionService.createSubscription(userId, request.getSubscriptionType(), request.getBillingCycle());
        Optional<Subscription> subscriptionOpt = subscriptionService.getActiveSubscriptionBySessionId(sessionId);
        if (subscriptionOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Failed to create subscription"));
        }
        Subscription subscription = subscriptionOpt.get();

        Payment payment = new Payment();
        payment.setSubscription(subscription);
        payment.setAmount(amount);
        payment.setPaymentMethod(request.getPaymentMethod());
        payment.setPaymentStatus("PENDING");
        payment.setTransactionId(sessionId);
        payment.setPaymentDate(LocalDateTime.now());
        payment.setPaymentReference(request.getPaymentReference());
        paymentRepository.save(payment);

        // Generate subscription confirmation code directly
        String subscriptionConfirmationCode = String.format("%06d", new Random().nextInt(999999));
        subscriptionService.storeSubscriptionConfirmationCode(sessionId, subscriptionConfirmationCode);

        // Send confirmation email with the code
        Map<String, Object> emailDetails = new HashMap<>();
        emailDetails.put("subscriptionId", sessionId);
        emailDetails.put("subscriptionType", subscription.getSubscriptionType());
        emailDetails.put("billingCycle", subscription.getBillingCycle());
        emailDetails.put("amount", subscription.getPrice());
        emailDetails.put("subscriptionConfirmationCode", subscriptionConfirmationCode);

        try {
            emailService.sendPaymentConfirmationEmail(user.getEmail(), sessionId, emailDetails);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Internal Server Error",
                    "message", "Échec de l'envoi de l'email de confirmation: " + e.getMessage()
            ));
        }

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Abonnement initié. Veuillez vérifier votre email pour le code de confirmation.");
        response.put("session_id", sessionId);
        response.put("paymentVerificationCode", subscriptionConfirmationCode); // Use subscriptionConfirmationCode

        return ResponseEntity.ok(response);
    }

    @PostMapping("/confirmSubscription")
    public ResponseEntity<?> confirmSubscription(
            @RequestParam String sessionId,
            @RequestParam String subscriptionConfirmationCode) {
        Optional<Subscription> subscriptionOpt = subscriptionService.getActiveSubscriptionBySessionId(sessionId);
        if (subscriptionOpt.isEmpty()) {
            return ResponseEntity.badRequest().body("Abonnement introuvable");
        }

        Subscription subscription = subscriptionOpt.get();
        String storedCode = subscriptionService.getSubscriptionConfirmationCode(sessionId);
        if (storedCode == null || !storedCode.equals(subscriptionConfirmationCode)) {
            return ResponseEntity.badRequest().body("Code de confirmation d'abonnement invalide");
        }

        // Confirm payment
        Payment payment = paymentRepository.findByTransactionId(sessionId).orElse(null);
        if (payment == null) {
            return ResponseEntity.badRequest().body("Aucun paiement trouvé pour cette session");
        }
        payment.setPaymentStatus("CONFIRMED");
        paymentRepository.save(payment);

        // Confirm subscription and apply benefits
        subscription.setStatus(SubscriptionStatus.ACTIVE);
        subscription.setPaymentStatus("COMPLETED");
        if (subscription.getRemainingPlaces() == null) {
            subscription.setRemainingPlaces(0); // Default if not set
        }
        subscriptionRepository.save(subscription);

        // Send final confirmation email without QR code
        Map<String, Object> emailDetails = new HashMap<>();
        emailDetails.put("subscriptionId", sessionId);
        emailDetails.put("subscriptionType", subscription.getSubscriptionType());
        emailDetails.put("billingCycle", subscription.getBillingCycle());
        emailDetails.put("amount", subscription.getPrice());
        emailDetails.put("startDate", subscription.getStartDate().toString());
        emailDetails.put("endDate", subscription.getEndDate().toString());

        try {
            System.out.println("Attempting to send confirmation email to: " + subscription.getUser().getEmail());
            emailService.sendSubscriptionConfirmationEmail(subscription.getUser().getEmail(), sessionId, emailDetails);
            System.out.println("Confirmation email sent successfully.");
        } catch (Exception e) {
            System.err.println("Failed to send confirmation email: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.ok(Map.of(
                    "message", "Abonnement confirmé avec succès, mais l'email de confirmation n'a pas pu être envoyé: " + e.getMessage()
            ));
        }

        return ResponseEntity.ok(Map.of("message", "Abonnement confirmé avec succès"));
    }

    @PostMapping("/subscription/callback")
    public ResponseEntity<?> handlePaymentCallback(
            @RequestParam String session,
            @RequestParam String status) {
        subscriptionService.updateSubscriptionStatus(session, status);
        return "SUCCESS".equalsIgnoreCase(status)
                ? ResponseEntity.ok("Paiement validé avec succès")
                : ResponseEntity.badRequest().body("Échec du paiement");
    }

    @PostMapping("/subscription/{id}/cancel")
    public ResponseEntity<?> cancelSubscription(@PathVariable Long id) {
        subscriptionService.cancelSubscription(id);
        return ResponseEntity.ok("Abonnement annulé avec succès");
    }

    @PostMapping("/subscription/{id}/renew")
    public ResponseEntity<?> renewSubscription(@PathVariable Long id) {
        subscriptionService.renewSubscription(id);
        return ResponseEntity.ok("Abonnement renouvelé avec succès");
    }

    @GetMapping("/subscriptions/active")
    public ResponseEntity<?> getActiveSubscription(@RequestParam String userId) {
        Long parsedUserId;
        try {
            parsedUserId = Long.parseLong(userId);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid user ID format. Must be a valid number."));
        }

        Optional<Subscription> activeSubscription = subscriptionService.getActiveSubscription(parsedUserId);
        if (activeSubscription.isPresent()) {
            Subscription subscription = activeSubscription.get();
            Map<String, Object> response = new HashMap<>();
            response.put("id", subscription.getId());
            response.put("userId", subscription.getUser().getId());
            response.put("subscriptionType", subscription.getSubscriptionType());
            response.put("billingCycle", subscription.getBillingCycle());
            response.put("status", subscription.getStatus().name());
            response.put("remainingPlaces", subscription.getRemainingPlaces());
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(404).body(Map.of(
                    "error", "Not Found",
                    "message", "Aucun abonnement actif trouvé pour cet utilisateur"
            ));
        }
    }
}