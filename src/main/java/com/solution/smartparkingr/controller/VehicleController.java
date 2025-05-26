package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.load.request.VehicleRequest;
import com.solution.smartparkingr.load.response.VehicleResponse;
import com.solution.smartparkingr.service.VehicleService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class VehicleController {

    @Autowired
    private VehicleService vehicleService;

    @GetMapping("/vehicles")
    public List<VehicleResponse> getVehiclesByUser(@RequestParam Long userId) {
        return vehicleService.getVehiclesByUser(userId); // Update service method accordingly
    }
    // Add a new vehicle
    @PostMapping("/vehicle")
    public ResponseEntity<?> createVehicle(@Valid @RequestBody VehicleRequest vehicleRequest) {
        try {
            VehicleResponse createdVehicle = vehicleService.createVehicle(vehicleRequest);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdVehicle);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", e.getMessage()
            ));
        }
    }
}