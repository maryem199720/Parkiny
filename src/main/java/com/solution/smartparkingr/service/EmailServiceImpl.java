package com.solution.smartparkingr.service;

import com.sendgrid.*;
import com.sendgrid.helpers.mail.Mail;
import com.sendgrid.helpers.mail.objects.Content;
import com.sendgrid.helpers.mail.objects.Email;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.Map;

@Service
public class EmailServiceImpl implements EmailService {

    @Value("${sendgrid.api.key}")
    private String apiKey;

    @Value("${email.from:your-email@example.com}")
    private String fromEmail;

    @Value("${qr.code.view.url:http://localhost:8082/parking/api/qr/}")
    private String qrCodeViewUrl;

    @Override
    public void sendPaymentVerificationEmail(String toEmail, String code) throws IOException {
        Email from = new Email(fromEmail);
        String subject = "Vérification de votre paiement";
        Email to = new Email(toEmail);
        String emailContent = "<h2>Vérification de paiement</h2>" +
                "<p>Un paiement est en attente pour votre réservation. Votre code de vérification est : <strong>" + code + "</strong></p>" +
                "<p>Veuillez entrer ce code dans l'application pour confirmer votre paiement.</p>";
        Content content = new Content("text/html", emailContent);
        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(apiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            if (response.getStatusCode() != 202) {
                throw new IOException("Failed to send payment verification email: " + response.getBody());
            }
            System.out.println("Payment verification email sent successfully to " + toEmail);
        } catch (IOException ex) {
            throw new IOException("Error sending payment verification email to " + toEmail + ": " + ex.getMessage(), ex);
        }
    }

    @Override
    public void sendReservationConfirmationEmail(String toEmail, String reservationId, Map<String, Object> details) throws IOException {
        Email from = new Email(fromEmail);
        String subject = "Confirmation de votre réservation de parking";
        Email to = new Email(toEmail);

        // Generate QR Code with proper exception handling
        String qrCodeData = details.getOrDefault("qrCodeData", reservationId).toString();
        String qrCodeBase64;
        try {
            qrCodeBase64 = generateQRCodeBase64(qrCodeData, 200, 200);
        } catch (WriterException | IOException e) {
            throw new IOException("Failed to generate QR code: " + e.getMessage(), e);
        }

        // Build email content using StringBuilder
        StringBuilder emailContent = new StringBuilder();
        emailContent.append("<h2>Réservation confirmée</h2>")
                .append("<p>Votre réservation (ID: ").append(reservationId).append(") a été confirmée.</p>")
                .append("<h3>Détails de la réservation :</h3>")
                .append("<ul>")
                .append("<li><strong>ID de réservation :</strong> ").append(details.getOrDefault("reservationId", reservationId)).append("</li>")
                .append("<li><strong>Début :</strong> ").append(details.getOrDefault("startTime", "N/A")).append("</li>")
                .append("<li><strong>Fin :</strong> ").append(details.getOrDefault("endTime", "N/A")).append("</li>")
                .append("<li><strong>Place :</strong> ").append(details.getOrDefault("placeName", "N/A")).append("</li>")
                .append("<li><strong>Montant total :</strong> ").append(details.getOrDefault("totalAmount", "0.00")).append(" TND</li>")
                .append("</ul>");

        // Include verification code based on reservation type
        if (details.containsKey("paymentVerificationCode")) {
            emailContent.append("<p><strong>Code de vérification de paiement :</strong> ")
                    .append(details.get("paymentVerificationCode")).append("</p>")
                    .append("<p>Veuillez entrer ce code dans l'application pour confirmer votre paiement.</p>");
        } else if (details.containsKey("reservationConfirmationCode")) {
            emailContent.append("<p><strong>Code de confirmation de réservation :</strong> ")
                    .append(details.get("reservationConfirmationCode")).append("</p>")
                    .append("<p>Veuillez entrer ce code dans l'application pour confirmer votre réservation.</p>");
        }

        emailContent.append("<p><strong>QR Code :</strong></p>")
                .append("<img src='data:image/png;base64,").append(qrCodeBase64).append("' alt='QR Code' />")
                .append("<p>Présentez ce QR code à l'arrivée au parking.</p>");

        Content content = new Content("text/html", emailContent.toString());
        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(apiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            if (response.getStatusCode() != 202) {
                throw new IOException("Failed to send reservation confirmation email: " + response.getBody());
            }
            System.out.println("Reservation confirmation email sent successfully to " + toEmail);
        } catch (IOException ex) {
            throw new IOException("Error sending reservation confirmation email to " + toEmail + ": " + ex.getMessage(), ex);
        }
    }

    @Override
    public void sendPasswordResetEmail(String toEmail, String code) throws IOException {
        Email from = new Email(fromEmail);
        String subject = "Vérification de réinitialisation de mot de passe";
        Email to = new Email(toEmail);
        String emailContent = "<h2>Réinitialisation de mot de passe</h2>" +
                "<p>Vous avez demandé une réinitialisation de mot de passe. Votre code de vérification est : <strong>" + code + "</strong></p>" +
                "<p>Veuillez entrer ce code dans l'application pour continuer.</p>";
        Content content = new Content("text/html", emailContent);
        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(apiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            if (response.getStatusCode() != 202) {
                throw new IOException("Failed to send password reset email: " + response.getBody());
            }
            System.out.println("Password reset email sent successfully to " + toEmail);
        } catch (IOException ex) {
            throw new IOException("Error sending password reset email to " + toEmail + ": " + ex.getMessage(), ex);
        }
    }

    @Override
    public void sendPaymentConfirmationEmail(String toEmail, String subscriptionId, Map<String, Object> details) throws IOException {
        Email from = new Email(fromEmail);
        String subject = "Confirmation de paiement d'abonnement";
        Email to = new Email(toEmail);
        String emailContent = "<h2>Confirmation de paiement</h2>" +
                "<p>Votre paiement pour l'abonnement (ID: " + subscriptionId + ") a été confirmé.</p>" +
                "<h3>Détails de l'abonnement :</h3>" +
                "<ul>" +
                "<li><strong>ID d'abonnement :</strong> " + subscriptionId + "</li>" +
                "<li><strong>Type :</strong> " + details.get("subscriptionType") + "</li>" +
                "<li><strong>Cycle :</strong> " + details.get("billingCycle") + "</li>" +
                "<li><strong>Montant :</strong> " + details.get("amount") + " TND</li>" +
                "</ul>" +
                "<p>Votre code de confirmation d'abonnement est : <strong>" + details.get("subscriptionConfirmationCode") + "</strong></p>" +
                "<p>Veuillez entrer ce code dans l'application pour finaliser votre abonnement.</p>";
        Content content = new Content("text/html", emailContent);
        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(apiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            if (response.getStatusCode() != 202) {
                throw new IOException("Failed to send payment confirmation email: " + response.getBody());
            }
            System.out.println("Payment confirmation email sent successfully to " + toEmail);
        } catch (IOException ex) {
            throw new IOException("Error sending payment confirmation email to " + toEmail + ": " + ex.getMessage(), ex);
        }
    }

    @Override
    public void sendSubscriptionConfirmationEmail(String toEmail, String subscriptionId, Map<String, Object> details) throws IOException {
        Email from = new Email(fromEmail);
        String subject = "Confirmation finale de votre abonnement";
        Email to = new Email(toEmail);

        // No QR code generation needed
        StringBuilder emailContent = new StringBuilder();
        emailContent.append("<h2>Abonnement confirmé</h2>")
                .append("<p>Votre abonnement (ID: ").append(subscriptionId).append(") a été activé avec succès.</p>")
                .append("<h3>Détails de l'abonnement :</h3>")
                .append("<ul>")
                .append("<li><strong>ID d'abonnement :</strong> ").append(subscriptionId).append("</li>")
                .append("<li><strong>Type :</strong> ").append(details.getOrDefault("subscriptionType", "N/A")).append("</li>")
                .append("<li><strong>Cycle :</strong> ").append(details.getOrDefault("billingCycle", "N/A")).append("</li>")
                .append("<li><strong>Montant :</strong> ").append(details.getOrDefault("amount", "0.00")).append(" TND</li>")
                .append("<li><strong>Date de début :</strong> ").append(details.getOrDefault("startDate", "N/A")).append("</li>")
                .append("<li><strong>Date de fin :</strong> ").append(details.getOrDefault("endDate", "N/A")).append("</li>")
                .append("</ul>")
                .append("<p>Vous pouvez désormais accéder aux services d'abonnement via l'application avec vos identifiants.</p>");

        Content content = new Content("text/html", emailContent.toString());
        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(apiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            if (response.getStatusCode() != 202) {
                throw new IOException("Failed to send subscription confirmation email: " + response.getBody());
            }
            System.out.println("Subscription confirmation email sent successfully to " + toEmail);
        } catch (IOException ex) {
            throw new IOException("Error sending subscription confirmation email to " + toEmail + ": " + ex.getMessage(), ex);
        }
    }

    private String generateQRCodeBase64(String data, int width, int height) throws WriterException, IOException {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(data, BarcodeFormat.QR_CODE, width, height);
        ByteArrayOutputStream pngOutputStream = new ByteArrayOutputStream();
        MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
        byte[] pngData = pngOutputStream.toByteArray();
        return Base64.getEncoder().encodeToString(pngData);
    }
}