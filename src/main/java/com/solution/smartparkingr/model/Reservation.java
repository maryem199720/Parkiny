package com.solution.smartparkingr.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
@Data
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id")
    @OnDelete(action = OnDeleteAction.SET_NULL)
    private Vehicle vehicle;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "parking_spot_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private ParkingSpot parkingSpot;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subscription_id")
    @OnDelete(action = OnDeleteAction.SET_NULL)
    private Subscription subscription; // Added subscription field

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReservationStatus status;

    @Column(name = "total_cost")
    private Double totalCost;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "email")
    private String email;

    // Default constructor
    public Reservation() {}

    // Constructor for creating a reservation
    public Reservation(User user, Vehicle vehicle, ParkingSpot parkingSpot, Subscription subscription,
                       LocalDateTime startTime, LocalDateTime endTime, ReservationStatus status,
                       Double totalCost, LocalDateTime createdAt, String email) {
        this.user = user;
        this.vehicle = vehicle;
        this.parkingSpot = parkingSpot;
        this.subscription = subscription;
        this.startTime = startTime;
        this.endTime = endTime;
        this.status = status;
        this.totalCost = totalCost;
        this.createdAt = createdAt;
        this.email = email;
    }
}