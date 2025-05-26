package com.solution.smartparkingr.security.services;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.solution.smartparkingr.model.Role;
import com.solution.smartparkingr.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

public class UserDetailsImpl implements UserDetails {

    private static final Logger logger = LoggerFactory.getLogger(UserDetailsImpl.class);

    private long id;
    private String username;  // Use this field for email (username = email)
    private String email;     // Store email separately (optional, for clarity)
    private String firstName; // Added first name
    private String lastName;  // Added last name
    private String phone;     // Added phone number

    @JsonIgnore
    private String password;

    private Collection<? extends GrantedAuthority> authorities;

    // Constructor
    public UserDetailsImpl(long id, String username, String email, String password,
                           String firstName, String lastName, String phone,
                           Collection<? extends GrantedAuthority> authorities) {
        this.id = id;
        this.username = username;  // Store email here as the username
        this.email = email;        // Store email separately
        this.password = password;
        this.firstName = firstName;  // Set first name
        this.lastName = lastName;    // Set last name
        this.phone = phone;          // Set phone
        this.authorities = authorities;
    }

    // Static build method to construct UserDetailsImpl from User
    public static UserDetailsImpl build(User user) {
        logger.debug("Building UserDetails for user with email: {}", user.getEmail());
        List<GrantedAuthority> authorities = user.getRoles().stream()
                .map(role -> {
                    logger.debug("Mapping role: {}", role.getName());
                    return new SimpleGrantedAuthority(role.getName().name());
                })
                .collect(Collectors.toList());
        logger.debug("Authorities mapped: {}", authorities);

        return new UserDetailsImpl(
                user.getId(),
                user.getEmail(),  // Use email as the username
                user.getEmail(),  // Store email separately
                user.getPassword(),
                user.getFirstName(),
                user.getLastName(),
                user.getPhone(),
                authorities
        );
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username; // Return email here as 'username'
    }

    public String getEmail() {
        return email;  // Getter for email
    }

    public String getFirstName() {
        return firstName; // Getter for firstName
    }

    public String getLastName() {
        return lastName;  // Getter for lastName
    }

    public String getPhone() {
        return phone;     // Getter for phone
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    public long getId() {
        return id;
    }
}