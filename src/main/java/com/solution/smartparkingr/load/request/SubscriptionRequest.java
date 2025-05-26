package com.solution.smartparkingr.load.request;

import com.solution.smartparkingr.model.PaymentMethod;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class SubscriptionRequest {

    @NotBlank(message = "User ID is required")
    private String userId;

    @NotBlank(message = "Subscription type is required")
    private String subscriptionType;

    @NotBlank(message = "Billing cycle is required")
    private String billingCycle;

    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private Double amount;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    @NotBlank(message = "Payment reference is required")
    private String paymentReference;

    @NotBlank(message = "Card number is required")
    private String cardNumber;

    @NotBlank(message = "Expiry date is required")
    private String expiryDate;

    @NotBlank(message = "CVV is required")
    private String cvv;

    @NotBlank(message = "Card name is required")
    private String cardName;

    @NotBlank(message = "Email is required")
    private String email;
}