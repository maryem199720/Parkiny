package com.solution.smartparkingr.load.response;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public class UserProfileResponse {

    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private List<VehicleInfo> vehicles;
    private SubscriptionInfo subscription;
    private List<ReservationInfo> reservationHistory;

    // Nested DTO for vehicle information
    public static class VehicleInfo {
        private Long id;
        private String matricule;
        private String vehicleType;
        private String brand;
        private String model;
        private String color;
        private String matriculeImageUrl;

        public VehicleInfo(Long id, String matricule, String vehicleType, String brand, String model, String color, String matriculeImageUrl) {
            this.id = id;
            this.matricule = matricule;
            this.vehicleType = vehicleType;
            this.brand = brand;
            this.model = model;
            this.color = color;
            this.matriculeImageUrl = matriculeImageUrl;
        }

        public Long getId() {
            return id;
        }

        public String getMatricule() {
            return matricule;
        }

        public String getVehicleType() {
            return vehicleType;
        }

        public String getBrand() {
            return brand;
        }

        public String getModel() {
            return model;
        }

        public String getColor() {
            return color;
        }

        public String getMatriculeImageUrl() {
            return matriculeImageUrl;
        }
    }

    // Nested DTO for subscription information (simplified for badge)
    public static class SubscriptionInfo {
        private boolean hasSubscription;
        private LocalDate subscriptionEndDate;

        public SubscriptionInfo(boolean hasSubscription, LocalDate subscriptionEndDate) {
            this.hasSubscription = hasSubscription;
            this.subscriptionEndDate = subscriptionEndDate;
        }

        public boolean isHasSubscription() {
            return hasSubscription;
        }

        public LocalDate getSubscriptionEndDate() {
            return subscriptionEndDate;
        }
    }

    // Nested DTO for reservation information
    public static class ReservationInfo {
        private Long parkingSpotId;
        private Long vehicleId;
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private String status;
        private Double totalCost;
        private LocalDateTime createdAt;

        public ReservationInfo(Long parkingSpotId, Long vehicleId, LocalDateTime startTime, LocalDateTime endTime, String status, Double totalCost, LocalDateTime createdAt) {
            this.parkingSpotId = parkingSpotId;
            this.vehicleId = vehicleId;
            this.startTime = startTime;
            this.endTime = endTime;
            this.status = status;
            this.totalCost = totalCost;
            this.createdAt = createdAt;
        }

        public Long getParkingSpotId() {
            return parkingSpotId;
        }

        public Long getVehicleId() {
            return vehicleId;
        }

        public LocalDateTime getStartTime() {
            return startTime;
        }

        public LocalDateTime getEndTime() {
            return endTime;
        }

        public String getStatus() {
            return status;
        }

        public Double getTotalCost() {
            return totalCost;
        }

        public LocalDateTime getCreatedAt() {
            return createdAt;
        }
    }

    // Constructor
    public UserProfileResponse(Long id, String firstName, String lastName, String email, String phone,
                               List<VehicleInfo> vehicles, SubscriptionInfo subscription, List<ReservationInfo> reservationHistory) {
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phone = phone;
        this.vehicles = vehicles;
        this.subscription = subscription;
        this.reservationHistory = reservationHistory;
    }

    // Getters
    public Long getId() {
        return id;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public List<VehicleInfo> getVehicles() {
        return vehicles;
    }

    public SubscriptionInfo getSubscription() {
        return subscription;
    }

    public List<ReservationInfo> getReservationHistory() {
        return reservationHistory;
    }
}