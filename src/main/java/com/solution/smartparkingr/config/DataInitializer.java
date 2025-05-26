package com.solution.smartparkingr.config;

import com.solution.smartparkingr.model.ParkingSpot;
import com.solution.smartparkingr.model.Role;
import com.solution.smartparkingr.model.SubscriptionPlan;
import com.solution.smartparkingr.model.User;
import com.solution.smartparkingr.model.ERole;
import com.solution.smartparkingr.repository.ParkingSpotRepository;
import com.solution.smartparkingr.repository.RoleRepository;
import com.solution.smartparkingr.repository.SubscriptionPlanRepository;
import com.solution.smartparkingr.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.HashSet;
import java.util.Set;

@Configuration
public class DataInitializer {

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private RoleRepository roleRepository;

    @Bean
    public CommandLineRunner initData(ParkingSpotRepository parkingSpotRepository, SubscriptionPlanRepository subscriptionPlanRepository, UserRepository userRepository) {
        return args -> {
            // Initialize roles
            if (roleRepository.findByName(ERole.ROLE_ADMIN).isEmpty()) {
                Role adminRole = new Role(ERole.ROLE_ADMIN);
                roleRepository.save(adminRole);
                System.out.println("✅ ROLE_ADMIN initialized!");
            }
            if (roleRepository.findByName(ERole.ROLE_USER).isEmpty()) {
                Role userRole = new Role(ERole.ROLE_USER);
                roleRepository.save(userRole);
                System.out.println("✅ ROLE_USER initialized!");
            }

            // Initialize parking spots
            if (!parkingSpotRepository.existsByName("P1")) {
                for (int i = 1; i <= 50; i++) {
                    ParkingSpot spot = new ParkingSpot();
                    spot.setName("P" + i);
                    spot.setType("standard");
                    spot.setPrice(5.0);
                    spot.setAvailable(true);
                    parkingSpotRepository.save(spot);
                }
                System.out.println("✅ 50 parking spots initialized!");
            } else {
                System.out.println("🚗 Parking spots already exist!");
            }

            // Initialize subscription plans
            if (subscriptionPlanRepository.count() == 0) {
                subscriptionPlanRepository.save(new SubscriptionPlan("Basique", 89.0, 5, 1, false, false, "STANDARD", 100, false));
                subscriptionPlanRepository.save(new SubscriptionPlan("Premium", 149.0, null, 3, true, false, "PRIORITY", 50, true));
                subscriptionPlanRepository.save(new SubscriptionPlan("Entreprise", 269.0, null, 7, true, true, "DEDICATED", 20, false));
                System.out.println("✅ Subscription plans initialized!");
            } else {
                System.out.println("📋 Subscription plans already exist!");
            }

            // Initialize admin user if no admin with email exists
            Role adminRole = roleRepository.findByName(ERole.ROLE_ADMIN)
                    .orElseThrow(() -> new RuntimeException("ROLE_ADMIN not found in database"));
            if (!userRepository.existsByEmail("admin@example.com")) {
                User admin = new User(
                        "Admin",
                        "Admin",
                        "admin@example.com",
                        "+1234567890",
                        passwordEncoder.encode("admin123")
                );
                Set<Role> adminRoles = new HashSet<>();
                adminRoles.add(adminRole);
                admin.setRoles(adminRoles);
                userRepository.save(admin);
                System.out.println("✅ Admin user initialized with email: admin@example.com, password: admin123");
            } else {
                System.out.println("👤 Admin user already exists!");
            }
        };
    }
}