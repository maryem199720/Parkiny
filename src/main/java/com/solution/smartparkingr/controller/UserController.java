package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.load.request.ChangePasswordRequest;
import com.solution.smartparkingr.load.request.PasswordResetRequest;
import com.solution.smartparkingr.load.request.UserProfileUpdateRequest;
import com.solution.smartparkingr.load.response.UserProfileResponse;
import com.solution.smartparkingr.model.User;
import com.solution.smartparkingr.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> getUserProfile() {
        User user = userService.getCurrentUserForProfile();

        List<UserProfileResponse.VehicleInfo> vehicleInfos = user.getVehicles() != null
                ? user.getVehicles().stream()
                .map(vehicle -> new UserProfileResponse.VehicleInfo(
                        vehicle.getId(),
                        vehicle.getMatricule(),
                        vehicle.getVehicleType(),
                        vehicle.getBrand(),
                        vehicle.getModel(),
                        vehicle.getColor(),
                        vehicle.getMatriculeImageUrl()
                ))
                .collect(Collectors.toList())
                : List.of();

        List<UserProfileResponse.ReservationInfo> reservationInfos = user.getReservations() != null
                ? user.getReservations().stream()
                .map(res -> new UserProfileResponse.ReservationInfo(
                        res.getParkingSpot().getId(),
                        res.getVehicle() != null ? res.getVehicle().getId() : null,
                        res.getStartTime(),
                        res.getEndTime(),
                        res.getStatus().name(),
                        res.getTotalCost(),
                        res.getCreatedAt()
                ))
                .collect(Collectors.toList())
                : List.of();

        UserProfileResponse response = new UserProfileResponse(
                user.getId(),
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                user.getPhone(),
                vehicleInfos,
                null,
                reservationInfos
        );

        return ResponseEntity.ok(response);
    }

    @PutMapping("/profile")
    public ResponseEntity<UserProfileResponse> updateUserProfile(@Valid @RequestBody UserProfileUpdateRequest updateRequest) {
        User user = userService.updateUserProfile(updateRequest);

        List<UserProfileResponse.VehicleInfo> vehicleInfos = user.getVehicles() != null
                ? user.getVehicles().stream()
                .map(vehicle -> new UserProfileResponse.VehicleInfo(
                        vehicle.getId(),
                        vehicle.getMatricule(),
                        vehicle.getVehicleType(),
                        vehicle.getBrand(),
                        vehicle.getModel(),
                        vehicle.getColor(),
                        vehicle.getMatriculeImageUrl()
                ))
                .collect(Collectors.toList())
                : List.of();

        List<UserProfileResponse.ReservationInfo> reservationInfos = user.getReservations() != null
                ? user.getReservations().stream()
                .map(res -> new UserProfileResponse.ReservationInfo(
                        res.getParkingSpot().getId(),
                        res.getVehicle() != null ? res.getVehicle().getId() : null,
                        res.getStartTime(),
                        res.getEndTime(),
                        res.getStatus().name(),
                        res.getTotalCost(),
                        res.getCreatedAt()
                ))
                .collect(Collectors.toList())
                : List.of();

        UserProfileResponse response = new UserProfileResponse(
                user.getId(),
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                user.getPhone(),
                vehicleInfos,
                null,
                reservationInfos
        );

        return ResponseEntity.ok(response);
    }

    @PostMapping("/request-password-reset")
    public ResponseEntity<String> requestPasswordReset(@Valid @RequestBody PasswordResetRequest request) {
        userService.requestPasswordReset(request.getMethod(), request.getEmail(), request.getPhone());
        return ResponseEntity.ok("Verification code sent successfully");
    }

    @PostMapping("/change-password")
    public ResponseEntity<String> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(request.getCurrentPassword(), request.getNewPassword(), request.getVerificationCode());
        return ResponseEntity.ok("Password updated successfully");
    }

    @PostMapping("/cancel-reservation/{id}")
    public ResponseEntity<String> cancelReservation(@PathVariable Long id) {
        userService.cancelReservation(id);
        return ResponseEntity.ok("Reservation cancelled successfully");
    }

    @PutMapping("/update-reservation/{id}")
    public ResponseEntity<String> updateReservation(@PathVariable Long id,
                                                    @RequestParam LocalDateTime newStartTime,
                                                    @RequestParam LocalDateTime newEndTime) {
        userService.updateReservation(id, newStartTime, newEndTime);
        return ResponseEntity.ok("Reservation updated successfully");
    }

    @PostMapping("/cancel-subscription/{id}")
    public ResponseEntity<String> cancelSubscription(@PathVariable Long id) {
        userService.cancelSubscription(id);
        return ResponseEntity.ok("Subscription cancelled successfully");
    }

    @PutMapping("/update-vehicle/{id}")
    public ResponseEntity<String> updateVehicleInfo(@PathVariable Long id,
                                                    @RequestParam(required = false) String matricule,
                                                    @RequestParam(required = false) String vehicleType,
                                                    @RequestParam(required = false) String brand,
                                                    @RequestParam(required = false) String model,
                                                    @RequestParam(required = false) String color,
                                                    @RequestParam(required = false) String matriculeImageUrl) {
        userService.updateVehicleInfo(id, matricule, vehicleType, brand, model, color, matriculeImageUrl);
        return ResponseEntity.ok("Vehicle information updated successfully");
    }
}