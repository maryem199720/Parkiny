import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Component({
  selector: 'app-profile-subscription',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './profile-subscription.component.html',
  styles: []
})
export class ProfileSubscriptionComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);

  subscription = signal<any>({ type: 'none', subscriptionEndDate: 'Non défini' });
  subscriptionHistory = signal<any[]>([]);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  ngOnInit() {
    this.loadSubscription();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  loadSubscription(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.subscription.set(data.subscription || { type: 'none', subscriptionEndDate: 'Non défini' });
          this.subscriptionHistory.set(data.subscriptions || []);
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur de récupération des abonnements: ${err.message}`);
          this.isLoading.set(false);
          if (err.status === 401) {
            this.authService.logout();
          }
        },
      });
  }
}