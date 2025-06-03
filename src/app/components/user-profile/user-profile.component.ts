import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService, User } from 'src/app/auth/services/auth/auth.service';
import { SubscriptionService, Subscription } from 'src/app/services/subscription.service';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './user-profile.component.html',
  styles: []
})
export class UserProfileComponent implements OnInit {
  private authService = inject(AuthService);
  private subscriptionService = inject(SubscriptionService);
  user = signal<User | null>(null);
  subscription = signal<Subscription | null>(null);
  isLoading = signal(true);
  errorMessage = signal<string | null>(null);

  ngOnInit(): void {
    this.authService.getUser().subscribe({
      next: (user: User | null) => {
        this.user.set(user);
        if (user?.id) {
          this.loadSubscription(user.id);
        }
        this.isLoading.set(false);
      },
      error: (err) => {
        this.errorMessage.set(`Erreur de récupération du profil: ${err.message}`);
        this.isLoading.set(false);
      }
    });
  }

  loadSubscription(userId: number): void {
    this.subscriptionService.getActiveSubscription(userId).subscribe({
      next: (sub) => this.subscription.set(sub),
      error: (err) => console.error('Error fetching subscription:', err)
    });
  }
}