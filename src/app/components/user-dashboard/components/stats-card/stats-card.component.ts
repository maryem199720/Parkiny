import { Component } from '@angular/core';

@Component({
  selector: 'app-stats-card',
  standalone: true,
  imports: [],
  templateUrl: './stats-card.component.html',
  styleUrl: './stats-card.component.css'
})
export class StatsCardsComponent {
  stats = {
    availableSpots: 18,
    availableSpotsTrend: '3 more than yesterday',
    activeReservations: 3,
    nextReservation: 'Today at 2:30 PM',
    monthlySavings: '$42.75',
    savingsTrend: '18% from last month',
    favoriteLocations: 5,
    topLocation: 'Downtown Garage'
  };
}
