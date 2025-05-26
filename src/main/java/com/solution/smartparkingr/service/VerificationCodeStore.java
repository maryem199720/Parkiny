package com.solution.smartparkingr.service;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class VerificationCodeStore {

    private final Map<String, String> codeStore = new ConcurrentHashMap<>();

    public void storeCode(String email, String code) {
        codeStore.put(email, code);
    }

    public String getCode(String email) {
        return codeStore.get(email);
    }

    public void removeCode(String email) {
        codeStore.remove(email);
    }
}