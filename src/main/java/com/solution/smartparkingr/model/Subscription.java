package com.solution.smartparkingr.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "subscriptions")
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "subscription_type")
    private String subscriptionType; // e.g., "Basic", "Standard", "Premium", "Elite"

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate; // Renamed from validUntil for clarity

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private SubscriptionStatus status; // Changed to enum

    @Column(name = "price")
    private Double price; // Renamed from amount to align with frontend

    @Column(name = "billing_cycle")
    private String billingCycle; // "MONTHLY" or "ANNUAL"

    @Column(name = "parking_duration_limit")
    private Integer parkingDurationLimit; // In hours per day, null for unlimited

    @Column(name = "advance_reservation_days")
    private Integer advanceReservationDays; // Days in advance for reservations

    @Column(name = "has_premium_spots")
    private Boolean hasPremiumSpots; // Access to premium spots

    @Column(name = "has_valet_service")
    private Boolean hasValetService; // Access to valet service

    @Column(name = "support_level")
    private String supportLevel; // "STANDARD", "PRIORITY", "DEDICATED"

    @Column(name = "remaining_places")
    private Integer remainingPlaces; // Number of remaining included reservations

    @Column(name = "payment_status")
    private String paymentStatus; // "PENDING", "COMPLETED"

    @Column(name = "session_id")
    private String sessionId; // For payment processing

    @Column(name = "auto_renewal")
    private Boolean autoRenewal; // Whether to auto-renew

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    // Constructors
    public Subscription() {}

    public Subscription(String subscriptionType, LocalDate startDate, LocalDate endDate, SubscriptionStatus status, Double price,
                        String billingCycle, Integer parkingDurationLimit, Integer advanceReservationDays,
                        Boolean hasPremiumSpots, Boolean hasValetService, String supportLevel, Integer remainingPlaces,
                        String paymentStatus, String sessionId, Boolean autoRenewal, User user) {
        this.subscriptionType = subscriptionType;
        this.startDate = startDate;
        this.endDate = endDate;
        this.status = status;
        this.price = price;
        this.billingCycle = billingCycle;
        this.parkingDurationLimit = parkingDurationLimit;
        this.advanceReservationDays = advanceReservationDays;
        this.hasPremiumSpots = hasPremiumSpots;
        this.hasValetService = hasValetService;
        this.supportLevel = supportLevel;
        this.remainingPlaces = remainingPlaces;
        this.paymentStatus = paymentStatus;
        this.sessionId = sessionId;
        this.autoRenewal = autoRenewal;
        this.user = user;
    }

    // Getters and Setters (unchanged except for status)
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getSubscriptionType() {
        return subscriptionType;
    }

    public void setSubscriptionType(String subscriptionType) {
        this.subscriptionType = subscriptionType;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public SubscriptionStatus getStatus() {
        return status;
    }

    public void setStatus(SubscriptionStatus status) {
        this.status = status;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public String getBillingCycle() {
        return billingCycle;
    }

    public void setBillingCycle(String billingCycle) {
        this.billingCycle = billingCycle;
    }

    public Integer getParkingDurationLimit() {
        return parkingDurationLimit;
    }

    public void setParkingDurationLimit(Integer parkingDurationLimit) {
        this.parkingDurationLimit = parkingDurationLimit;
    }

    public Integer getAdvanceReservationDays() {
        return advanceReservationDays;
    }

    public void setAdvanceReservationDays(Integer advanceReservationDays) {
        this.advanceReservationDays = advanceReservationDays;
    }

    public Boolean getHasPremiumSpots() {
        return hasPremiumSpots;
    }

    public void setHasPremiumSpots(Boolean hasPremiumSpots) {
        this.hasPremiumSpots = hasPremiumSpots;
    }

    public Boolean getHasValetService() {
        return hasValetService;
    }

    public void setHasValetService(Boolean hasValetService) {
        this.hasValetService = hasValetService;
    }

    public String getSupportLevel() {
        return supportLevel;
    }

    public void setSupportLevel(String supportLevel) {
        this.supportLevel = supportLevel;
    }

    public Integer getRemainingPlaces() {
        return remainingPlaces;
    }

    public void setRemainingPlaces(Integer remainingPlaces) {
        this.remainingPlaces = remainingPlaces;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public Boolean getAutoRenewal() {
        return autoRenewal;
    }

    public void setAutoRenewal(Boolean autoRenewal) {
        this.autoRenewal = autoRenewal;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }
}