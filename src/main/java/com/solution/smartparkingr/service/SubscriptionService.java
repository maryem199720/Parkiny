package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.Subscription;

import java.util.Optional;

public interface SubscriptionService {

    Subscription save(Subscription subscription);

    String createSubscription(Long userId, String subscriptionType, String billingCycle);

    Optional<Subscription> getActiveSubscription(Long userId);

    Optional<Subscription> getActiveSubscriptionBySessionId(String sessionId);

    void cancelSubscription(Long subscriptionId);

    void renewSubscription(Long subscriptionId);

    void updateSubscriptionStatus(String sessionId, String status);

    // Added methods for email verification
    void storePaymentVerificationCode(String sessionId, String code);

    String getPaymentVerificationCode(String sessionId);

    void storeSubscriptionConfirmationCode(String sessionId, String code);

    String getSubscriptionConfirmationCode(String sessionId);
}