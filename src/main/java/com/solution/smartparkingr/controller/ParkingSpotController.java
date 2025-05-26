package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.model.ParkingSpot;
import com.solution.smartparkingr.service.ParkingSpotService;
import com.solution.smartparkingr.service.ReservationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/parking-spots")
@RequiredArgsConstructor
public class ParkingSpotController {

    private final ParkingSpotService service;
    private final ReservationService reservationService;

    @GetMapping
    public ResponseEntity<List<ParkingSpot>> getAll() {
        return ResponseEntity.ok(service.getAllSpots());
    }

    @GetMapping("/spots")
    public ResponseEntity<List<ParkingSpot>> getAvailableSpots() {
        return ResponseEntity.ok(service.getAvailableSpots());
    }

    @GetMapping("/available")
    public ResponseEntity<List<ParkingSpot>> getAvailable(
            @RequestParam(required = false) String date,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        List<ParkingSpot> spots = service.getAvailableSpots();
        if (date != null && startTime != null && endTime != null) {
            LocalDateTime start = LocalDateTime.parse(date + "T" + startTime + ":00");
            LocalDateTime end = LocalDateTime.parse(date + "T" + endTime + ":00");
            spots = spots.stream()
                    .filter(spot -> !reservationService.isSpotReserved(spot.getId(), start, end))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(spots);
    }

    @PostMapping("/release/{id}")
    public ResponseEntity<String> releaseSpot(@PathVariable Long id) {
        service.releaseSpot(id);
        return ResponseEntity.ok("Parking spot released successfully");
    }
}