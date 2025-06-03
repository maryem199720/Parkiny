// subscription.service.ts
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { StorageService } from 'src/app/auth/services/storage/storage.service';

export interface Subscription {
  id: number;
  userId: number;
  subscriptionType: string;
  billingCycle: 'monthly' | 'annual';
  status: string;
  remainingPlaces: number;
  startDate?: string;
  endDate?: string;
}

export interface SubscriptionHistory {
  id: number;
  subscriptionId: number;
  action: string;
  date: string;
  details: string;
}

@Injectable({
  providedIn: 'root',
})
export class SubscriptionService {
  private apiUrl = 'http://localhost:8082/parking/api';

  constructor(private http: HttpClient, private storageService: StorageService) {}

  private getAuthHeaders(): HttpHeaders {
    const token = this.storageService.getToken();
    return new HttpHeaders({
      Authorization: `Bearer ${token || ''}`,
      'Content-Type': 'application/json',
    });
  }

  getSubscriptionPlans(): Observable<any> {
    return this.http.get(`${this.apiUrl}/subscription-plans`, {
      headers: this.getAuthHeaders(),
    });
  }

  getActiveSubscription(userId: number): Observable<Subscription> {
    return this.http.get<Subscription>(`${this.apiUrl}/subscriptions/active?userId=${userId}`, {
      headers: this.getAuthHeaders(),
    });
  }

  getUserProfile(): Observable<any> {
    return this.http.get(`${this.apiUrl}/user/profile`, {
      headers: this.getAuthHeaders(),
    });
  }

  subscribe(
    subscriptionType: string,
    billingCycle: string,
    amount: number,
    paymentMethod: 'CARTE_BANCAIRE', // Restrict to CARTE_BANCAIRE only
    email: string,
    cardDetails: any
  ): Observable<any> {
    const userId = this.storageService.getUserId();
    const payload = {
      userId,
      subscriptionType,
      billingCycle,
      amount,
      paymentMethod,
      paymentReference: cardDetails.cardNumber?.substring(12, 16) || 'XXXX',
      email,
      cardNumber: cardDetails.cardNumber,
      expiryDate: cardDetails.expiryDate,
      cvv: cardDetails.cvv,
      cardName: cardDetails.cardName,
    };
    return this.http.post(`${this.apiUrl}/subscribe`, payload, {
      headers: this.getAuthHeaders(),
    });
  }

  confirmSubscription(sessionId: string, confirmationCode: string): Observable<any> {
  const params = { sessionId, subscriptionConfirmationCode: confirmationCode }; // Match backend param name
  return this.http.post(`${this.apiUrl}/confirmSubscription`, null, { 
    params,
    headers: this.getAuthHeaders() // Add authentication headers
  });
}

  getSubscriptionHistory(userId: number, month?: number, year?: number): Observable<Subscription[]> {
    let url = `${this.apiUrl}/subscriptions/history?userId=${userId}`;
    if (month && year) {
      url += `&month=${month}&year=${year}`;
    }
    return this.http.get<Subscription[]>(url, { headers: this.getAuthHeaders() });
  }

  deleteSubscription(subscriptionId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/subscriptions/${subscriptionId}`, {
      headers: this.getAuthHeaders(),
    });
  }
}