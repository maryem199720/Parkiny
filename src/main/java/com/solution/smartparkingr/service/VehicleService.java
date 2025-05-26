package com.solution.smartparkingr.service;

import com.solution.smartparkingr.load.request.VehicleRequest;
import com.solution.smartparkingr.load.response.VehicleResponse;
import com.solution.smartparkingr.model.Vehicle;

import java.util.List;

public interface VehicleService {

    List<VehicleResponse> getAllVehicles();

    VehicleResponse createVehicle(VehicleRequest vehicleRequest);

    Vehicle findByMatricule(String matricule);

    Vehicle createIfNotExists(Vehicle vehicle);

    Vehicle save(Vehicle vehicle);

    void deleteVehicle(Long id);

    Vehicle updateVehicle(Long id, Vehicle vehicleDetails);

    List<VehicleResponse> getVehiclesByUser(Long userId);
}