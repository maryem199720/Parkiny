package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.Notification;
import com.solution.smartparkingr.model.Reservation;
import com.solution.smartparkingr.model.Subscription;
import com.solution.smartparkingr.repository.NotificationRepository;
import com.solution.smartparkingr.repository.ReservationRepository;
import com.solution.smartparkingr.repository.SubscriptionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {

    @Autowired
    private ReservationRepository reservationRepository;

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Scheduled(fixedRate = 60000) // Run every minute
    public void checkUpcomingEvents() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime fifteenMinFromNow = now.plusMinutes(15);
        LocalDateTime fiveMinFromNow = now.plusMinutes(5);
        LocalDateTime threeDaysFromNow = now.plusDays(3);

        // Reservations about to start
        List<Reservation> upcomingReservations = reservationRepository.findUpcomingReservations(now, fifteenMinFromNow);
        for (Reservation res : upcomingReservations) {
            String message = String.format("Your reservation (ID: %d) starts at %s.", res.getId(), res.getStartTime());
            sendNotification(res.getUser().getId(), Notification.NotificationType.RESERVATION_START, message, null);
        }

        // Reservations about to end
        List<Reservation> endingReservations = reservationRepository.findEndingReservations(now, fiveMinFromNow);
        for (Reservation res : endingReservations) {
            String message = String.format("Your reservation (ID: %d) has ended at %s.", res.getId(), res.getEndTime());
            sendNotification(res.getUser().getId(), Notification.NotificationType.RESERVATION_END, message, null);
        }

        // Subscriptions about to expire
        List<Subscription> expiringSubscriptions = subscriptionRepository.findExpiringSubscriptions(now, threeDaysFromNow);
        for (Subscription sub : expiringSubscriptions) {
            String message = String.format(
                    "Your %s subscription (ID: %d) expires on %s. Renew now?",
                    sub.getSubscriptionType(), sub.getId(), sub.getEndDate()
            );
            Map<String, Object> action = new HashMap<>();
            action.put("action", "RENEW");
            action.put("subscriptionId", sub.getId());
            sendNotification(sub.getUser().getId(), Notification.NotificationType.SUBSCRIPTION_RENEWAL, message, action);
        }
    }

    public void sendNotification(Long userId, Notification.NotificationType type, String message, Map<String, Object> action) {
        // Save to database
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setType(type);
        notification.setMessage(message);
        notification.setRead(false);
        notificationRepository.save(notification);

        // Prepare WebSocket payload
        Map<String, Object> notificationData = new HashMap<>();
        notificationData.put("id", notification.getId());
        notificationData.put("type", type.toString());
        notificationData.put("message", message);
        notificationData.put("createdAt", notification.getCreatedAt().toString());
        notificationData.put("isRead", false);
        if (action != null) {
            notificationData.put("action", action);
        }

        // Send to user-specific WebSocket destination
        messagingTemplate.convertAndSendToUser(
                userId.toString(),
                "/topic/notifications",
                notificationData
        );
    }
}