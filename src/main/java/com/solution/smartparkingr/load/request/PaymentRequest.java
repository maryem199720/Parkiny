package com.solution.smartparkingr.load.request;

import com.solution.smartparkingr.model.PaymentMethod;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class PaymentRequest {

    @NotNull(message = "Reservation ID is required")
    private Long reservationId;

    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private Double amount;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    @NotBlank(message = "Payment reference is required")
    private String paymentReference;

    private CardDetails cardDetails;

    @Data
    public static class CardDetails {
        private String cardName;
        private String cardNumber;
        private String cardExpiry;
        private String cardCvv;
    }
}