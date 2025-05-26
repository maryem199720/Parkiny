package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.*;
import com.solution.smartparkingr.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
public class SubscriptionServiceImpl implements SubscriptionService {

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Autowired
    private SubscriptionPlanRepository subscriptionPlanRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    private final Map<String, String> paymentVerificationCodes = new HashMap<>();
    private final Map<String, String> subscriptionConfirmationCodes = new HashMap<>();

    @Override
    public Subscription save(Subscription subscription) {
        return subscriptionRepository.save(subscription);
    }

    @Override
    public String createSubscription(Long userId, String subscriptionType, String billingCycle) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé avec l'ID: " + userId));
        SubscriptionPlan plan = subscriptionPlanRepository.findByType(subscriptionType)
                .orElseThrow(() -> new IllegalArgumentException("Plan d'abonnement non trouvé: " + subscriptionType));

        LocalDate startDate = LocalDate.now();
        LocalDate endDate = "MONTHLY".equalsIgnoreCase(billingCycle) ? startDate.plusMonths(1) : startDate.plusYears(1);
        double price = "MONTHLY".equalsIgnoreCase(billingCycle) ? plan.getMonthlyPrice() : plan.getMonthlyPrice() * 9.6;

        String sessionId = "SMT" + System.currentTimeMillis();
        Subscription subscription = new Subscription();
        subscription.setUser(user);
        subscription.setSubscriptionType(subscriptionType);
        subscription.setStartDate(startDate);
        subscription.setEndDate(endDate);
        subscription.setStatus(SubscriptionStatus.PENDING);
        subscription.setPrice(price);
        subscription.setBillingCycle(billingCycle);
        subscription.setParkingDurationLimit(plan.getParkingDurationLimit());
        subscription.setAdvanceReservationDays(plan.getAdvanceReservationDays());
        subscription.setHasPremiumSpots(plan.getHasPremiumSpots());
        subscription.setHasValetService(plan.getHasValetService());
        subscription.setSupportLevel(plan.getSupportLevel());
        subscription.setRemainingPlaces(plan.getRemainingPlacesPerMonth());
        subscription.setPaymentStatus("PENDING");
        subscription.setSessionId(sessionId);
        subscription.setAutoRenewal(false);

        subscriptionRepository.save(subscription);
        return sessionId;
    }

    @Override
    public Optional<Subscription> getActiveSubscription(Long userId) {
        return subscriptionRepository.findByUserIdAndStatus(userId, SubscriptionStatus.ACTIVE);
    }

    @Override
    public Optional<Subscription> getActiveSubscriptionBySessionId(String sessionId) {
        return subscriptionRepository.findBySessionId(sessionId).filter(s -> SubscriptionStatus.ACTIVE.equals(s.getStatus()) || SubscriptionStatus.PENDING.equals(s.getStatus()));
    }

    @Override
    public void cancelSubscription(Long subscriptionId) {
        Subscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new IllegalArgumentException("Abonnement non trouvé"));
        subscription.setStatus(SubscriptionStatus.CANCELLED);
        subscriptionRepository.save(subscription);
    }

    @Override
    public void renewSubscription(Long subscriptionId) {
        Subscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new IllegalArgumentException("Abonnement non trouvé"));
        LocalDate newEndDate = subscription.getEndDate().plusMonths(1);
        subscription.setEndDate(newEndDate);
        subscription.setStatus(SubscriptionStatus.ACTIVE);
        subscriptionRepository.save(subscription);
    }

    @Override
    public void updateSubscriptionStatus(String sessionId, String status) {
        Subscription subscription = subscriptionRepository.findBySessionId(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session de paiement non trouvée: " + sessionId));
        Payment payment = paymentRepository.findByTransactionId(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Paiement non trouvé pour la session: " + sessionId));

        if ("SUCCESS".equalsIgnoreCase(status)) {
            subscription.setPaymentStatus("COMPLETED");
            subscription.setStatus(SubscriptionStatus.ACTIVE);
            payment.setPaymentStatus("COMPLETED");
        } else {
            subscription.setPaymentStatus("FAILED");
            subscription.setStatus(SubscriptionStatus.CANCELLED);
            payment.setPaymentStatus("FAILED");
        }
        subscriptionRepository.save(subscription);
        paymentRepository.save(payment);
    }

    public void storePaymentVerificationCode(String sessionId, String code) {
        paymentVerificationCodes.put(sessionId, code);
    }

    public String getPaymentVerificationCode(String sessionId) {
        return paymentVerificationCodes.get(sessionId);
    }

    public void storeSubscriptionConfirmationCode(String sessionId, String code) {
        subscriptionConfirmationCodes.put(sessionId, code);
    }

    public String getSubscriptionConfirmationCode(String sessionId) {
        return subscriptionConfirmationCodes.get(sessionId);
    }
}