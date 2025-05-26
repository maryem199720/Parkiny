package com.solution.smartparkingr.model;

import jakarta.persistence.*;

@Entity
@Table(name = "subscription_plans")
public class SubscriptionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "type")
    private String type; // e.g., "Basique", "Premium", "Entreprise"

    @Column(name = "monthly_price")
    private Double monthlyPrice;

    @Column(name = "parking_duration_limit")
    private Integer parkingDurationLimit; // Hours per day, null for unlimited

    @Column(name = "advance_reservation_days")
    private Integer advanceReservationDays;

    @Column(name = "has_premium_spots")
    private Boolean hasPremiumSpots;

    @Column(name = "has_valet_service")
    private Boolean hasValetService;

    @Column(name = "support_level")
    private String supportLevel; // STANDARD, PRIORITY, DEDICATED

    @Column(name = "remaining_places_per_month")
    private Integer remainingPlacesPerMonth;

    @Column(name = "is_popular")
    private Boolean isPopular;

    // Constructors, Getters, Setters
    public SubscriptionPlan() {}

    public SubscriptionPlan(String type, Double monthlyPrice, Integer parkingDurationLimit, Integer advanceReservationDays,
                            Boolean hasPremiumSpots, Boolean hasValetService, String supportLevel, Integer remainingPlacesPerMonth, Boolean isPopular) {
        this.type = type;
        this.monthlyPrice = monthlyPrice;
        this.parkingDurationLimit = parkingDurationLimit;
        this.advanceReservationDays = advanceReservationDays;
        this.hasPremiumSpots = hasPremiumSpots;
        this.hasValetService = hasValetService;
        this.supportLevel = supportLevel;
        this.remainingPlacesPerMonth = remainingPlacesPerMonth;
        this.isPopular = isPopular;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Double getMonthlyPrice() {
        return monthlyPrice;
    }

    public void setMonthlyPrice(Double monthlyPrice) {
        this.monthlyPrice = monthlyPrice;
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

    public Integer getRemainingPlacesPerMonth() {
        return remainingPlacesPerMonth;
    }

    public void setRemainingPlacesPerMonth(Integer remainingPlacesPerMonth) {
        this.remainingPlacesPerMonth = remainingPlacesPerMonth;
    }

    public Boolean getIsPopular() {
        return isPopular;
    }

    public void setIsPopular(Boolean isPopular) {
        this.isPopular = isPopular;
    }
}