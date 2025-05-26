package com.solution.smartparkingr.load.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.Set;

public class SignupRequest {

    @NotBlank
    @Size(max = 50)
    private String firstName;  // User's first name

    @NotBlank
    @Size(max = 50)
    private String lastName;  // User's last name

    @NotBlank
    @Size(max = 50)
    @Email
    private String email;  // User's email address

    @NotBlank
    @Size(max = 15)
    @Pattern(regexp = "^(\\+\\d{1,3}[- ]?)?\\d{8,15}$", message = "Invalid phone number format")
    private String phone;  // User's phone number

    @NotBlank
    @Size(min = 6, max = 120)
    private String password;  // User's password

    private Set<String> role;  // Roles the user will have

    public SignupRequest() {
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Set<String> getRole() {
        return role;
    }

    public void setRole(Set<String> role) {
        this.role = role;
    }
}
