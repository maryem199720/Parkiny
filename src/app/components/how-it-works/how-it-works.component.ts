import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router'; // Add for routerLink
import { ParkingService } from 'src/app/services/parking.service';

@Component({
  selector: 'app-how-it-works',
  standalone: true,
  imports: [CommonModule, RouterModule], // Add RouterModule for routerLink
  templateUrl: './how-it-works.component.html',
  styleUrls: ['./how-it-works.component.css']
})
export class HowItWorksComponent implements OnInit {
  isLoading = true;
  parkingConfig: any = {};

  constructor(private parkingService: ParkingService) {}

  ngOnInit(): void {
    console.log('HowItWorksComponent initialized'); // Debug log
    this.loadParkingConfig();
  }

  /**
   * Load parking configuration
   */
  loadParkingConfig(): void {
    this.isLoading = true;
    this.parkingService.getParkingConfig().subscribe({
      next: (config) => {
        this.parkingConfig = config;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading parking config:', error);
        this.isLoading = false;
      }
    });
  }
}