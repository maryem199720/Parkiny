package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.ParkingSpot;
import java.util.List;

public interface ParkingSpotService {
    ParkingSpot assignSpotToVehicle(com.solution.smartparkingr.model.Vehicle vehicle);
    void releaseSpot(Long spotId);
    List<ParkingSpot> getAllSpots();
    List<ParkingSpot> getAvailableSpots();
    void releaseExpiredReservationsAndSubscriptions(); // Updated method name
}