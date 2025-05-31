package com.solution.smartparkingr.load.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.solution.smartparkingr.model.PaymentMethod;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReservationRequest {

    @NotNull(message = "User ID is required")
    private Long userId;

    @NotNull(message = "Parking Place ID is required")
    private Long parkingPlaceId;

    @NotBlank(message = "Matricule is required")
    @Pattern(regexp = "[A-Z0-9]{3,10}", message = "Invalid matricule format")
    private String matricule;

    @NotNull(message = "Start time is required")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime startTime;

    @NotNull(message = "End time is required")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime endTime;

    @NotBlank(message = "Vehicle type is required")
    private String vehicleType;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    private String specialRequest;

    @NotBlank(message = "Email is required")
    @Pattern(regexp = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", message = "Invalid email format")
    private String email;

    private Long subscriptionId; // Optional, null for non-subscribed users
}