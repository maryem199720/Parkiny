package com.solution.smartparkingr.load.response;

public class VehicleResponse {

    private Long id;
    private String matricule;
    private String vehicleType;
    private String brand;
    private String model;
    private String color;
    private String matriculeImageUrl;
    private Long userId;

    // Constructors
    public VehicleResponse() {}

    public VehicleResponse(Long id, String matricule, String vehicleType, String brand, String model, String color, String matriculeImageUrl, Long userId) {
        this.id = id;
        this.matricule = matricule;
        this.vehicleType = vehicleType;
        this.brand = brand;
        this.model = model;
        this.color = color;
        this.matriculeImageUrl = matriculeImageUrl;
        this.userId = userId;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getMatricule() {
        return matricule;
    }

    public void setMatricule(String matricule) {
        this.matricule = matricule;
    }

    public String getVehicleType() {
        return vehicleType;
    }

    public void setVehicleType(String vehicleType) {
        this.vehicleType = vehicleType;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public String getMatriculeImageUrl() {
        return matriculeImageUrl;
    }

    public void setMatriculeImageUrl(String matriculeImageUrl) {
        this.matriculeImageUrl = matriculeImageUrl;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }
}