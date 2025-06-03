import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatButtonModule } from '@angular/material/button';
import { MatSnackBarModule, MatSnackBar } from '@angular/material/snack-bar';
import { FormsModule } from '@angular/forms';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatInputModule } from '@angular/material/input';
import { MatNativeDateModule } from '@angular/material/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AuthService, User } from 'src/app/auth/services/auth/auth.service';
import { SubscriptionService, Subscription } from 'src/app/services/subscription.service';
import { HttpErrorResponse } from '@angular/common/http';

@Component({
  selector: 'app-profile-subscription',
  standalone: true,
  imports: [
    CommonModule,
    MatFormFieldModule,
    MatButtonModule,
    MatSnackBarModule,
    FormsModule,
    MatDatepickerModule,
    MatInputModule,
    MatNativeDateModule,
    MatIconModule,
    MatProgressSpinnerModule,
  ],
  providers: [DatePipe],
  templateUrl: './profile-subscription.component.html',
  styleUrls: ['./profile-subscription.component.css'],
})
export class ProfileSubscriptionComponent implements OnInit {
  private authService = inject(AuthService);
  private subscriptionService = inject(SubscriptionService);
  private snackBar = inject(MatSnackBar);

  subscription = signal<Subscription | null>(null);
  subscriptionHistory = signal<Subscription[]>([]);
  isLoading = signal(true);
  errorMessage = signal<string | null>(null);
  selectedDate: Date | null = null;
  selectedMonth: number | undefined = undefined;
  selectedYear: number | undefined = undefined;

  ngOnInit(): void {
    this.authService.getUser().subscribe({
      next: (user: User | null) => {
        const userId = user?.id;
        console.log('User from AuthService:', user);
        if (!userId) {
          this.errorMessage.set('Utilisateur non connecté.');
          this.authService.logout();
          this.isLoading.set(false);
          return;
        }
        this.loadSubscription(userId);
      },
      error: (err: HttpErrorResponse) => {
        this.errorMessage.set('Erreur lors de la récupération de l\'utilisateur.');
        this.authService.logout();
        this.isLoading.set(false);
        console.error('AuthService error:', err);
      },
    });
  }

  loadSubscription(userId: number): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.subscriptionService.getActiveSubscription(userId).subscribe({
      next: (sub) => {
        this.subscription.set(sub);
        this.loadSubscriptionHistory(userId);
        console.log('Active subscription:', sub);
      },
      error: (err: HttpErrorResponse) => {
        if (err.status === 404) {
          this.subscription.set(null);
        } else {
          this.errorMessage.set(`Erreur de récupération de l'abonnement: ${err.message}`);
        }
        this.isLoading.set(false);
        if (err.status === 401) {
          this.authService.logout();
        }
        console.error('Subscription error:', err);
      },
    });
  }

  loadSubscriptionHistory(userId: number): void {
    this.subscriptionService.getSubscriptionHistory(userId, this.selectedMonth, this.selectedYear).subscribe({
      next: (history: Subscription[]) => {
        this.subscriptionHistory.set(history);
        this.isLoading.set(false);
        if (history.length === 0) {
          this.snackBar.open('Aucun historique pour les filtres sélectionnés.', 'OK', { duration: 5000 });
        }
        console.log('Subscription history:', history);
      },
      error: (err: HttpErrorResponse) => {
        this.errorMessage.set(`Erreur de récupération de l'historique: ${err.message}`);
        this.isLoading.set(false);
        console.error('History error:', err);
      },
    });
  }

  onMonthSelected(event: Date): void {
    this.selectedDate = new Date(event.getFullYear(), event.getMonth(), 1);
    this.applyFilters();
  }

  applyFilters(): void {
    this.authService.getUser().subscribe({
      next: (user: User | null) => {
        const userId = user?.id;
        if (userId) {
          if (this.selectedDate) {
            this.selectedMonth = this.selectedDate.getMonth() + 1;
            this.selectedYear = this.selectedDate.getFullYear();
          } else {
            this.selectedMonth = undefined;
            this.selectedYear = undefined;
          }
          console.log('Applying filters:', { userId, month: this.selectedMonth, year: this.selectedYear });
          this.loadSubscriptionHistory(userId);
        }
      },
      error: (err: HttpErrorResponse) => {
        this.snackBar.open('Erreur lors de la récupération de l\'utilisateur.', 'OK', { duration: 5000 });
        console.error('AuthService error in applyFilters:', err);
      },
    });
  }

  resetFilters(): void {
    this.selectedDate = null;
    this.selectedMonth = undefined;
    this.selectedYear = undefined;
    this.applyFilters();
  }

  deleteSubscription(subscriptionId: number): void {
    if (confirm('Êtes-vous sûr de vouloir supprimer cet abonnement de l\'historique ?')) {
      this.subscriptionService.deleteSubscription(subscriptionId).subscribe({
        next: () => {
          this.snackBar.open('Abonnement supprimé avec succès.', 'OK', { duration: 5000 });
          this.subscriptionHistory.update((history: Subscription[]) =>
            history.filter((sub: Subscription) => sub.id !== subscriptionId)
          );
          if (this.subscription()?.id === subscriptionId) {
            this.subscription.set(null);
          }
        },
        error: (err: HttpErrorResponse) => {
          this.snackBar.open(`Erreur lors de la suppression: ${err.message}`, 'OK', { duration: 5000 });
          console.error('Delete error:', err);
        },
      });
    }
  }
}