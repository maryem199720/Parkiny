import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Component({
  selector: 'app-reservation-history',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './reservation-history.component.html',
  styles: []
})
export class ReservationHistoryComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);

  activeReservations = signal<any[]>([]);
  expiredReservations = signal<any[]>([]);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  ngOnInit() {
    this.loadReservations();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  loadReservations(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.processReservations(data.reservationHistory || []);
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur de récupération de l'historique: ${err.message}`);
          this.isLoading.set(false);
          if (err.status === 401) {
            this.authService.logout();
          }
        },
      });
  }

  private processReservations(reservations: any[]): void {
    const now = new Date();
    const active = [];
    const expired = [];
    for (const res of reservations) {
      const endTime = new Date(res.endTime);
      const reservation = {
        parkingSpotId: res.parkingSpotId.toString(),
        startTime: new Date(res.startTime),
        endTime,
        status: res.status,
        totalCost: res.totalCost?.toString() ?? 'N/A',
      };
      if (endTime > now && res.status === 'PENDING') {
        active.push(reservation);
      } else {
        expired.push(reservation);
      }
    }
    this.activeReservations.set(active);
    this.expiredReservations.set(expired);
  }
}