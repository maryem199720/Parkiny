package com.solution.smartparkingr.service;

import java.io.IOException;
import java.util.Map;

public interface EmailService {

    /**
     * Sends a payment verification email with a code to the specified email address.
     *
     * @param toEmail The recipient's email address
     * @param code    The verification code to include in the email
     * @throws IOException If there is an error sending the email
     */
    void sendPaymentVerificationEmail(String toEmail, String code) throws IOException;

    /**
     * Sends a reservation confirmation email to the specified email address.
     *
     * @param toEmail       The recipient's email address
     * @param reservationId The ID of the reservation to include in the email
     * @param details       A map containing detailed reservation information
     * @throws IOException If there is an error sending the email
     */
    void sendReservationConfirmationEmail(String toEmail, String reservationId, Map<String, Object> details) throws IOException;

    /**
     * Sends a password reset verification email with a code to the specified email address.
     *
     * @param toEmail The recipient's email address
     * @param code    The verification code to include in the email
     * @throws IOException If there is an error sending the email
     */
    void sendPasswordResetEmail(String toEmail, String code) throws IOException;

    void sendPaymentConfirmationEmail(String toEmail, String subscriptionId, Map<String, Object> details) throws IOException;

    void sendSubscriptionConfirmationEmail(String toEmail, String subscriptionId, Map<String, Object> details) throws IOException;

}