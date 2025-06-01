import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Component({
  selector: 'app-profile-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './profile-header.component.html',
  styles: []
})
export class ProfileHeaderComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private router = inject(Router);

  user = signal({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    subscription: { subscriptionEndDate: 'Non défini', type: 'none' as 'none' | 'premium' }
  });
  isLoading = signal(true);
  errorMessage = signal<string | null>(null);

  ngOnInit() {
    this.loadUserProfile();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  loadUserProfile(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.user.set({
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            email: data.email || '',
            phone: data.phone || '',
            subscription: data.subscription || { subscriptionEndDate: 'Non défini', type: 'none' },
          });
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur de récupération du profil: ${err.message}`);
          this.isLoading.set(false);
          if (err.status === 401) {
            this.authService.logout();
            this.router.navigate(['/login']);
          }
        },
      });
  }
}