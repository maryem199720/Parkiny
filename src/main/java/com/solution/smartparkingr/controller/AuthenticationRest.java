package com.solution.smartparkingr.controller;

import com.solution.smartparkingr.model.ERole;
import com.solution.smartparkingr.model.Role;
import com.solution.smartparkingr.model.User;
import com.solution.smartparkingr.repository.RoleRepository;
import com.solution.smartparkingr.repository.UserRepository;
import com.solution.smartparkingr.security.jwt.JwtUtils;
import com.solution.smartparkingr.security.services.UserDetailsImpl;
import com.solution.smartparkingr.load.request.LoginRequest;
import com.solution.smartparkingr.load.request.SignupRequest;
import com.solution.smartparkingr.load.response.JwtResponse;
import com.solution.smartparkingr.load.response.MessageResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins   = "*")

public class AuthenticationRest {

    @Autowired
    JwtUtils jwtUtils;

    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    UserRepository userRepository;

    @Autowired
    RoleRepository roleRepository;

    @Autowired
    PasswordEncoder encoder;

    // Signup endpoint for creating a new user
    @PostMapping("/signup")
    public ResponseEntity<?> signup(@Valid @RequestBody SignupRequest request) {

        // Check if email is already used
        if (userRepository.existsByEmail(request.getEmail())) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse("Error: Email is already in use!"));
        }

        // Check if phone is already used (Optional: can be added if needed)
        if (userRepository.existsByPhone(request.getPhone())) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse("Error: Phone number is already in use!"));
        }

        // Encrypt the password
        User user = new User(
                request.getFirstName(),  // Use firstName from request
                request.getLastName(),   // Use lastName from request
                request.getEmail(),      // Use email from request
                request.getPhone(),      // Use phone from request
                encoder.encode(request.getPassword())  // Encrypt password
        );

        // Handle roles (default to USER role if none provided)
        Set<String> strRoles = request.getRole();
        Set<Role> roles = new HashSet<>();

        if (strRoles == null) {
            // Default to USER role
            Role userRole = roleRepository.findByName(ERole.ROLE_USER)
                    .orElseThrow(() -> new RuntimeException("Error: Role is not found"));
            roles.add(userRole);
        } else {
            // Add roles based on the input
            strRoles.forEach(role -> {
                switch (role) {
                    case "admin":
                        Role adminRole = roleRepository.findByName(ERole.ROLE_ADMIN)
                                .orElseThrow(() -> new RuntimeException("Error: Role is not found"));
                        roles.add(adminRole);
                        break;
                    case "user":
                        Role userRole = roleRepository.findByName(ERole.ROLE_USER)
                                .orElseThrow(() -> new RuntimeException("Error: Role is not found"));
                        roles.add(userRole);
                        break;
                    default:
                        Role defaultRole = roleRepository.findByName(ERole.ROLE_USER)
                                .orElseThrow(() -> new RuntimeException("Error: Role is not found"));
                        roles.add(defaultRole);
                }
            });
        }

        user.setRoles(roles);
        userRepository.save(user);  // Save user to the database

        return ResponseEntity.ok(new MessageResponse("User registered successfully!"));
    }

    // Signin endpoint for user authentication
    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);  // Set authentication context

        // Generate JWT token
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();  // Get user details

        // Get roles of the user
        List<String> roles = userDetails.getAuthorities().stream()
                .map(item -> item.getAuthority())
                .collect(Collectors.toList());

        // Return JWT response
        return ResponseEntity.ok(new JwtResponse(
                jwt,
                userDetails.getId(),
                userDetails.getFirstName(),
                userDetails.getLastName(),
                userDetails.getEmail(),
                userDetails.getPhone(),  // Assuming you have phone in UserDetailsImpl
                roles));
    }

}
