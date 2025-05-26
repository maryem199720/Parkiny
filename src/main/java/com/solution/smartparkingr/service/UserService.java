package com.solution.smartparkingr.service;

import com.solution.smartparkingr.load.request.UserProfileUpdateRequest;
import com.solution.smartparkingr.model.User;

import java.time.LocalDateTime;

public interface UserService {

    User findById(Long userId);
    User findByEmail(String email);

    User getCurrentUserForProfile();

    User save(User user);
    void delete(Long userId);
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);
    User getCurrentUser();
    User updateUserProfile(UserProfileUpdateRequest updateRequest);
    void changePassword(String currentPassword, String newPassword, String verificationCode);
    void requestPasswordReset(String method, String email, String phone);
    void cancelReservation(Long reservationId);
    void updateReservation(Long reservationId, LocalDateTime newStartTime, LocalDateTime newEndTime);
    void cancelSubscription(Long subscriptionId);
    void updateVehicleInfo(Long vehicleId, String matricule, String vehicleType, String brand, String model, String color, String matriculeImageUrl);
}