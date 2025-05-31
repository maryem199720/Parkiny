import { Component } from '@angular/core';
import { WelcomeBannerComponent } from "../welcome-banner/welcome-banner.component";
import { StatsCardsComponent } from "../stats-card/stats-card.component";

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [WelcomeBannerComponent, StatsCardsComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent {

}
