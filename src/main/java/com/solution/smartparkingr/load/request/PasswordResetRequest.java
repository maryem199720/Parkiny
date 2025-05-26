package com.solution.smartparkingr.load.request;

import jakarta.validation.constraints.NotBlank;

public class PasswordResetRequest {

    @NotBlank(message = "Method is required")
    private String method; // "email" or "sms"

    @NotBlank(message = "Email is required if method is email")
    private String email;

    @NotBlank(message = "Phone is required if method is sms")
    private String phone;

    // Getters and Setters
    public String getMethod() {
        return method;
    }

    public void setMethod(String method) {
        this.method = method;
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
}