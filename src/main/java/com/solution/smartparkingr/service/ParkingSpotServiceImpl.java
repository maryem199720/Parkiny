package com.solution.smartparkingr.service;

import com.solution.smartparkingr.model.ParkingSpot;
import com.solution.smartparkingr.model.Reservation;
import com.solution.smartparkingr.model.ReservationStatus;
import com.solution.smartparkingr.model.Subscription;
import com.solution.smartparkingr.model.SubscriptionStatus;
import com.solution.smartparkingr.model.Vehicle;
import com.solution.smartparkingr.repository.ParkingSpotRepository;
import com.solution.smartparkingr.repository.ReservationRepository;
import com.solution.smartparkingr.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ParkingSpotServiceImpl implements ParkingSpotService {

    private static final Logger logger = LoggerFactory.getLogger(ParkingSpotServiceImpl.class);

    private final ParkingSpotRepository parkingSpotRepository;
    private final ReservationRepository reservationRepository;
    private final SubscriptionRepository subscriptionRepository;

    @Override
    public ParkingSpot assignSpotToVehicle(Vehicle vehicle) {
        logger.debug("Assigning spot to vehicle with ID: {}", vehicle.getId());
        ParkingSpot spot = parkingSpotRepository.findFirstByAvailableTrue()
                .orElseThrow(() -> new RuntimeException("No available parking spot"));
        spot.setAvailable(false);
        spot.setVehicle(vehicle);
        return parkingSpotRepository.save(spot);
    }

    @Override
    public void releaseSpot(Long spotId) {
        logger.debug("Releasing spot with ID: {}", spotId);
        ParkingSpot spot = parkingSpotRepository.findById(spotId)
                .orElseThrow(() -> new RuntimeException("Parking spot not found"));
        spot.setAvailable(true);
        spot.setVehicle(null);
        parkingSpotRepository.save(spot);
    }

    @Override
    public List<ParkingSpot> getAllSpots() {
        logger.debug("Fetching all parking spots");
        return parkingSpotRepository.findAll();
    }

    @Override
    public List<ParkingSpot> getAvailableSpots() {
        logger.debug("Fetching available parking spots");
        releaseExpiredReservationsAndSubscriptions();
        return parkingSpotRepository.findAll()
                .stream()
                .filter(ParkingSpot::isAvailable)
                .toList();
    }

    @Override
    @Scheduled(fixedRate = 60000) // Run every minute
    @Transactional
    public void releaseExpiredReservationsAndSubscriptions() {
        logger.debug("Releasing expired reservations and subscriptions");
        // Handle expired reservations
        LocalDateTime now = LocalDateTime.now();
        List<Reservation> expiredReservations = reservationRepository.findByEndTimeBeforeAndStatus(
                now, ReservationStatus.CONFIRMED);
        for (Reservation reservation : expiredReservations) {
            ParkingSpot spot = reservation.getParkingSpot();
            if (spot != null && !spot.isAvailable()) {
                spot.setAvailable(true);
                spot.setVehicle(null);
                parkingSpotRepository.save(spot);
                logger.debug("Released spot ID: {} for expired reservation", spot.getId());
            }
            reservation.setStatus(ReservationStatus.EXPIRED);
            reservationRepository.save(reservation);
        }

        // Handle expired subscriptions
        LocalDate today = now.toLocalDate();
        List<Subscription> expiredSubscriptions = subscriptionRepository.findByEndDateBeforeAndStatus(
                today, SubscriptionStatus.ACTIVE);
        for (Subscription subscription : expiredSubscriptions) {
            subscription.setStatus(SubscriptionStatus.EXPIRED);
            subscriptionRepository.save(subscription);
            logger.debug("Expired subscription ID: {} at end date", subscription.getId());
        }
    }
}