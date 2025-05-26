import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslateService } from '../../services/translate.service';
import { ParkingService } from 'src/app/services/parking.service';


@Component({
  selector: 'app-how-it-works',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './how-it-works.component.html',
  styleUrls: ['./how-it-works.component.css']
})
export class HowItWorksComponent implements OnInit {
  currentLanguage = 'FR';
  isLoading = true;
  parkingConfig: any = {};
  
  constructor(
    private translateService: TranslateService,
    private parkingService: ParkingService
  ) { }

  ngOnInit(): void {
    // Subscribe to language changes
    this.translateService.getLanguage().subscribe(lang => {
      this.currentLanguage = lang;
    });
    
    // Get parking configuration
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

  /**
   * Translate a key using the translation service
   */
  translate(key: string): string {
    return this.translateService.translate(key);
  }
}
