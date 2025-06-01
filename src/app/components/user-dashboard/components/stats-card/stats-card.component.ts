import { Component, OnInit } from '@angular/core';
import { StatsService } from 'src/app/services/stats.service';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

interface Stats {
  availableSpots: number;
  availableSpotsTrend: string;
  activeReservations: number;
  nextReservation: string;
  monthlySavings: string;
  savingsTrend: string;
  favoriteLocations: number;
  topLocation: string;
}

@Component({
  selector: 'app-stats-card',
  standalone: true,
  imports: [],
  templateUrl: './stats-card.component.html',
  styleUrl: './stats-card.component.css'
})
export class StatsCardsComponent implements OnInit {
  stats: Stats = {
    availableSpots: 0,
    availableSpotsTrend: '',
    activeReservations: 0,
    nextReservation: '',
    monthlySavings: '',
    savingsTrend: '',
    favoriteLocations: 0,
    topLocation: ''
  };

  constructor(
    private statsService: StatsService,
    private authService: AuthService
  ) {}

  ngOnInit() {
    const user = this.authService.getCurrentUser();
    if (user && user.id) {
      // Convert user.id (number) to string
      this.statsService.getUserStats(user.id.toString()).subscribe((data: Stats) => {
        this.stats = data;
      });
    }
  }
}