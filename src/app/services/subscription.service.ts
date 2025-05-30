import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { StorageService } from '../auth/services/storage/storage.service';

interface Vehicle {
  id: number;
  brand: string;
  model: string;
  matricule: string;
}

interface UserProfile {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  vehicles: Vehicle[];
}

interface SubscriptionPlan {
  id: number;
  type: string;
  monthlyPrice: number;
  parkingDurationLimit: number;
  advanceReservationDays: number;
  hasPremiumSpots: boolean;
  hasValetService: boolean;
  supportLevel: string | null;
  remainingPlacesPerMonth: number | null;
  isPopular: boolean;
}

interface Subscription {
  id: number;
  userId: number;
  subscriptionType: string;
  billingCycle: string;
  status: string;
  remainingPlaces: number;
}

interface SubscriptionResponse {
  message: string;
  session_id?: string;
  paymentVerificationCode?: string;
}

@Injectable({
  providedIn: 'root'
})
export class SubscriptionService {
  private apiUrl = 'http://localhost:8082/parking/api';

  constructor(
    private http: HttpClient,
    private storageService: StorageService
  ) {}

  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('token');
    let headers = new HttpHeaders({
      'Content-Type': 'application/json'
    });
    if (token) {
      headers = headers.set('Authorization', `Bearer ${token}`);
    }
    return headers;
  }

  getActiveSubscription(userId: number): Observable<Subscription> {
    return this.http.get<Subscription>(`${this.apiUrl}/subscriptions/active`, {
      headers: this.getAuthHeaders(),
      params: { userId: userId.toString() }
    }).pipe(
      catchError(err => {
        console.error('Error fetching active subscription:', err);
        return throwError(() => err);
      })
    );
  }

  getSubscriptionPlans(): Observable<SubscriptionPlan[]> {
    return this.http.get<SubscriptionPlan[]>(`${this.apiUrl}/subscription-plans`, {
      headers: this.getAuthHeaders()
    }).pipe(
      catchError(err => {
        console.error('Error fetching subscription plans:', err);
        return throwError(() => new Error('Failed to fetch subscription plans'));
      })
    );
  }

  subscribe(
    subscriptionType: string,
    billingCycle: string,
    amount: number,
    paymentMethod: 'card' | 'd17',
    email: string,
    cardDetails?: { cardNumber: string; expiryDate: string; cvv: string; cardName: string }
  ): Observable<SubscriptionResponse> {
    const userId = this.storageService.getUserId();
    if (!userId) {
      console.error('No userId found');
      return throwError(() => new Error('User ID is missing'));
    }
    const request = {
      userId: userId.toString(),
      subscriptionType,
      billingCycle,
      amount,
      paymentMethod: paymentMethod === 'card' ? 'CARTE_BANCAIRE' : 'POSTE',
      paymentReference: `REF_${Date.now()}`,
      email,
      ...(paymentMethod === 'card' && cardDetails ? {
        cardNumber: cardDetails.cardNumber,
        expiryDate: cardDetails.expiryDate,
        cvv: cardDetails.cvv,
        cardName: cardDetails.cardName
      } : {})
    };
    console.log('Subscription request:', request);
    return this.http.post<SubscriptionResponse>(`${this.apiUrl}/subscribe`, request, {
      headers: this.getAuthHeaders()
    }).pipe(
      catchError(err => {
        console.error('Error subscribing:', err);
        return throwError(() => err);
      })
    );
  }

  confirmSubscription(sessionId: string, subscriptionConfirmationCode: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/confirmSubscription`, null, {
      headers: this.getAuthHeaders(),
      params: { sessionId, subscriptionConfirmationCode }
    }).pipe(
      catchError(err => {
        console.error('Error confirming subscription:', err);
        return throwError(() => err);
      })
    );
  }

  getUserProfile(): Observable<UserProfile> {
    return this.http.get<UserProfile>(`${this.apiUrl}/user/profile`, {
      headers: this.getAuthHeaders()
    }).pipe(
      catchError(err => {
        console.error('Error fetching user profile:', err);
        return throwError(() => new Error('Failed to fetch user profile'));
      })
    );
  }
}