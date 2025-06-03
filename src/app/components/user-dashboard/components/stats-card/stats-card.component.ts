import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { StatsService } from 'src/app/services/stats.service';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

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

@Component({
  selector: 'app-stats-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './stats-card.component.html',
  styleUrls: ['./stats-card.component.css']
})
export class StatsCardsComponent implements OnInit, OnDestroy {
  stats: Stats = {
    availableSpots: 0,
    availableSpotsTrend: '0+',
    activeReservations: 0,
    nextReservation: 'No upcoming reservations',
    monthlySavings: '$0',
    savingsStatus: '0%',
    reservationsThisMonth: 0,
    totalReservations: 'Reservations This Month'
  };
  isLoading = false;
  error: string | null = null;
  private pollingInterval: any;

  constructor(
    private statsService: StatsService,
    private authService: AuthService
  ) {}

  ngOnInit() {
    this.loadStats();
    this.pollingInterval = setInterval(() => this.loadStats(), 30000); // Poll every 30 seconds
  }

  ngOnDestroy() {
    clearInterval(this.pollingInterval);
  }

  loadStats() {
    const user = this.authService.getCurrentUser();
    if (user && user.id) {
      this.isLoading = true;
      this.statsService.getUserStats(user.id.toString()).subscribe({
        next: (data: Stats) => {
          this.stats = data;
          this.isLoading = false;
          this.error = null;
        },
        error: (err) => {
          this.error = 'Failed to load stats. Please try again.';
          this.isLoading = false;
          console.error('Error fetching stats:', err);
        }
      });
    }
  }
}