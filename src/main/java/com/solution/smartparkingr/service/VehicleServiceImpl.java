package com.solution.smartparkingr.service;

import com.solution.smartparkingr.load.request.VehicleRequest;
import com.solution.smartparkingr.load.response.VehicleResponse;
import com.solution.smartparkingr.model.User;
import com.solution.smartparkingr.model.Vehicle;
import com.solution.smartparkingr.repository.UserRepository;
import com.solution.smartparkingr.repository.VehicleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class VehicleServiceImpl implements VehicleService {

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private UserRepository userRepository;

    @Override
    public List<VehicleResponse> getAllVehicles() {
        return vehicleRepository.findAll().stream()
                .map(vehicle -> new VehicleResponse(
                        vehicle.getId(),
                        vehicle.getMatricule(),
                        vehicle.getVehicleType(),
                        vehicle.getBrand(),
                        vehicle.getModel(),
                        vehicle.getColor(),
                        vehicle.getMatriculeImageUrl(),
                        vehicle.getUser() != null ? vehicle.getUser().getId() : null
                ))
                .collect(Collectors.toList());
    }

    @Override
    public List<VehicleResponse> getVehiclesByUser(Long userId) {
        List<Vehicle> vehicles = vehicleRepository.findByUserId(userId);
        return vehicles.stream()
                .map(vehicle -> new VehicleResponse(
                        vehicle.getId(),
                        vehicle.getMatricule(),
                        vehicle.getVehicleType(),
                        vehicle.getBrand(),
                        vehicle.getModel(),
                        vehicle.getColor(),
                        vehicle.getMatriculeImageUrl(),
                        vehicle.getUser() != null ? vehicle.getUser().getId() : null // Add userId
                ))
                .collect(Collectors.toList());
    }

    @Override
    public VehicleResponse createVehicle(VehicleRequest vehicleRequest) {
        // Fetch the user
        User user = userRepository.findById(vehicleRequest.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé avec l'ID: " + vehicleRequest.getUserId()));

        // Map VehicleRequest to Vehicle entity
        Vehicle vehicle = new Vehicle();
        vehicle.setMatricule(vehicleRequest.getMatricule());
        vehicle.setVehicleType(vehicleRequest.getVehicleType());
        vehicle.setBrand(vehicleRequest.getBrand());
        vehicle.setModel(vehicleRequest.getModel());
        vehicle.setColor(vehicleRequest.getColor());
        vehicle.setMatriculeImageUrl(vehicleRequest.getMatriculeImageUrl());
        vehicle.setUser(user);

        // Check if the vehicle already exists by matricule
        Vehicle existingVehicle = vehicleRepository.findByMatricule(vehicle.getMatricule()).orElse(null);
        Vehicle savedVehicle;
        if (existingVehicle != null) {
            // Update existing vehicle
            existingVehicle.setUser(user);
            savedVehicle = vehicleRepository.save(existingVehicle);
        } else {
            // Create new vehicle
            savedVehicle = vehicleRepository.save(vehicle);
        }

        // Map to VehicleResponse
        return new VehicleResponse(
                savedVehicle.getId(),
                savedVehicle.getMatricule(),
                savedVehicle.getVehicleType(),
                savedVehicle.getBrand(),
                savedVehicle.getModel(),
                savedVehicle.getColor(),
                savedVehicle.getMatriculeImageUrl(),
                savedVehicle.getUser().getId()
        );
    }

    @Override
    public Vehicle findByMatricule(String matricule) {
        Optional<Vehicle> vehicle = vehicleRepository.findByMatricule(matricule);
        return vehicle.orElse(null);
    }

    @Override
    public Vehicle createIfNotExists(Vehicle vehicle) {
        return vehicleRepository.findByMatricule(vehicle.getMatricule())
                .orElseGet(() -> vehicleRepository.save(vehicle));
    }

    @Override
    public Vehicle save(Vehicle vehicle) {
        return vehicleRepository.save(vehicle);
    }

    @Override
    public void deleteVehicle(Long id) {
        vehicleRepository.deleteById(id);
    }

    @Override
    public Vehicle updateVehicle(Long id, Vehicle vehicleDetails) {
        Optional<Vehicle> vehicleOptional = vehicleRepository.findById(id);
        if (vehicleOptional.isPresent()) {
            Vehicle vehicle = vehicleOptional.get();
            vehicle.setMatricule(vehicleDetails.getMatricule());
            vehicle.setVehicleType(vehicleDetails.getVehicleType());
            vehicle.setBrand(vehicleDetails.getBrand());
            vehicle.setModel(vehicleDetails.getModel());
            vehicle.setColor(vehicleDetails.getColor());
            vehicle.setMatriculeImageUrl(vehicleDetails.getMatriculeImageUrl());
            vehicle.setUser(vehicleDetails.getUser());
            return vehicleRepository.save(vehicle);
        }
        return null;
    }
}