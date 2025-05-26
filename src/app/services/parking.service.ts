import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from 'src/environments/environment';


@Injectable({
  providedIn: 'root'
})
export class ParkingService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) { }

  /**
   * Get real-time parking status
   * @returns Observable with parking status data
   */
  getParkingStatus(): Observable<any> {
    return this.http.get(`${this.apiUrl}/parking/status`).pipe(
      catchError(error => {
        console.error('Error fetching parking status:', error);
        // Fallback to mock data if API fails
        return of(this.getMockParkingStatus());
      })
    );
  }

  /**
   * Get parking configuration including hours, location, etc.
   * @returns Observable with parking configuration
   */
  getParkingConfig(): Observable<any> {
    return this.http.get(`${this.apiUrl}/parking/config`).pipe(
      catchError(error => {
        console.error('Error fetching parking config:', error);
        // Fallback to mock data if API fails
        return of(this.getMockParkingConfig());
      })
    );
  }

  /**
   * Check if a specific parking spot is available
   * @param spotId Parking spot ID
   * @returns Observable with availability status
   */
  checkSpotAvailability(spotId: string): Observable<boolean> {
    return this.http.get<any>(`${this.apiUrl}/parking/spots/${spotId}`).pipe(
      map(response => response.available),
      catchError(error => {
        console.error(`Error checking spot ${spotId} availability:`, error);
        return of(false);
      })
    );
  }

  /**
   * Reserve a parking spot
   * @param spotId Parking spot ID
   * @param userId User ID
   * @param startTime Start time of reservation
   * @param endTime End time of reservation
   * @returns Observable with reservation result
   */
  reserveSpot(spotId: string, userId: string, startTime: Date, endTime: Date): Observable<any> {
    const reservationData = {
      spotId,
      userId,
      startTime,
      endTime
    };
    
    return this.http.post(`${this.apiUrl}/parking/reserve`, reservationData).pipe(
      catchError(error => {
        console.error('Error reserving spot:', error);
        return of({ success: false, error: 'Failed to reserve spot' });
      })
    );
  }

  /**
   * Get user's active reservations
   * @param userId User ID
   * @returns Observable with user's reservations
   */
  getUserReservations(userId: string): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/parking/reservations/user/${userId}`).pipe(
      catchError(error => {
        console.error('Error fetching user reservations:', error);
        return of([]);
      })
    );
  }

  /**
   * Cancel a reservation
   * @param reservationId Reservation ID
   * @returns Observable with cancellation result
   */
  cancelReservation(reservationId: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/parking/reservations/${reservationId}`).pipe(
      catchError(error => {
        console.error('Error cancelling reservation:', error);
        return of({ success: false, error: 'Failed to cancel reservation' });
      })
    );
  }

  /**
   * Mock parking status data for fallback
   * @returns Mock parking status object
   */
  private getMockParkingStatus(): any {
    return {
      lastUpdated: new Date(),
      zones: [
        {
          id: 'standard',
          name: 'Parking Standard',
          total: 50,
          available: 15,
          status: 'available', // available, limited, full
          percentOccupied: 70
        },
        {
          id: 'vip',
          name: 'Zone VIP',
          total: 20,
          available: 5,
          status: 'limited',
          percentOccupied: 75
        },
        {
          id: 'reserved',
          name: 'Zone Réservée',
          total: 10,
          available: 0,
          status: 'full',
          percentOccupied: 100
        }
      ],
      totalSpots: 80,
      availableSpots: 20,
      occupancyRate: 75
    };
  }

  /**
   * Mock parking configuration for fallback
   * @returns Mock parking configuration object
   */
  private getMockParkingConfig(): any {
    return {
      name: 'TuniPark',
      location: {
        address: 'Tunis, Tunisie',
        latitude: 36.8075969687945,
        longitude: 10.073328443701746,
        googleMapsUrl: 'https://www.google.com/maps?q=36.8075969687945,10.073328443701746&z=15&output=embed'
      },
      operatingHours: {
        is24x7: true,
        weekdays: {
          open: '00:00',
          close: '24:00'
        },
        weekend: {
          open: '00:00',
          close: '24:00'
        },
        holidays: {
          open: '00:00',
          close: '24:00'
        }
      },
      features: [
        'Surveillance 24/7',
        'Reconnaissance automatique des plaques',
        'Éclairage nocturne',
        'Accès sécurisé'
      ],
      contactInfo: {
        phone: '+216 XX XXX XXX',
        email: 'contact@parkiny.tn',
        website: 'https://parkiny.tn'
      }
    };
  }
}
