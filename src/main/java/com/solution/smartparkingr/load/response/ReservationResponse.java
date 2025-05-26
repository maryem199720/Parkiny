package com.solution.smartparkingr.load.response;

import java.time.LocalDateTime;

public class ReservationResponse {
    private Long id;
    private String parkingLot;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String status;

    public ReservationResponse(Long id, String parkingLot, LocalDateTime startTime, LocalDateTime endTime, String status) {
        this.id = id;
        this.parkingLot = parkingLot;
        this.startTime = startTime;
        this.endTime = endTime;
        this.status = status;
    }

    // Getters et Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getParkingLot() { return parkingLot; }
    public void setParkingLot(String parkingLot) { this.parkingLot = parkingLot; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public LocalDateTime getEndTime() { return endTime; }
    public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
