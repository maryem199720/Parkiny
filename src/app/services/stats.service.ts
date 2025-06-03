import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

interface Stats {
  availableSpots: number;
  availableSpotsTrend: string;
  activeReservations: number;
  nextReservation: string;
  monthlySavings: string;
  savingsStatus: string;
  reservationsThisMonth: number;
  totalReservations: string;
}

@Injectable({
  providedIn: 'root'
})
export class StatsService {
  private apiUrl = 'http://localhost:8082/parking/api/stats';

  constructor(private http: HttpClient) {}

  getUserStats(userId: string): Observable<Stats> {
    const token = localStorage.getItem('token');
    const headers = new HttpHeaders({
      'Authorization': `Bearer ${token}`
    });
    return this.http.get<Stats>(`${this.apiUrl}/${userId}`, { headers });
  }
}