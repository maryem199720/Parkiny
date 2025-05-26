import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CommonModule, formatDate } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { ReactiveFormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Router } from '@angular/router';
import { StorageService } from 'src/app/auth/services/storage/storage.service';
import { SubscriptionService } from 'src/app/services/subscription.service';

export interface ParkingSpot {
  id: string;
  status: 'available' | 'reserved';
}

export interface ReservationResponse {
  reservationId: string;
  paymentVerificationCode?: string;
  reservationConfirmationCode?: string;
}

export interface ReservationDetails {
  date: Date;
  startTime: string;
  endTime: string;
  vehicleMatricule: string;
}

@Component({
  selector: 'app-reservations',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatTooltipModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatSnackBarModule,
    MatProgressSpinnerModule,
    MatSelectModule
  ],
  templateUrl: './reservations.component.html',
  styleUrls: ['./reservations.component.css']
})
export class ReservationComponent implements OnInit {
  currentStep = 1;
  reservationForm: FormGroup;
  availableSpots: ParkingSpot[] = [];
  selectedSpot: ParkingSpot | null = null;
  selectedPlace: any = null;
  userVehicles: any[] = [];
  selectedVehicleIndex: number | null = null;
  hasActiveSubscription = false;
  totalAmount = 0;
  isLoading = false;
  errorMessage: string | null = null;
  reservationId: string | null = null;
  paymentVerificationCode: string | null = null;
  reservationConfirmationCode: string | null = null;
  isReservationConfirmed = false;
  loggedInUserId: number | null = null;
  reservationDetails: ReservationDetails | null = null;

  constructor(
    private http: HttpClient,
    private router: Router,
    private snackBar: MatSnackBar,
    private fb: FormBuilder,
    private storageService: StorageService,
    private subscriptionService: SubscriptionService
  ) {
    this.reservationForm = this.fb.group({
      date: [new Date(), Validators.required],
      startTime: ['10:00', Validators.required],
      endTime: ['12:00', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      paymentVerificationCode: [''],
      reservationConfirmationCode: ['']
    });
  }

  ngOnInit(): void {
    if (!this.storageService.isLoggedIn()) {
      this.snackBar.open('Veuillez vous connecter pour continuer.', 'Fermer', { duration: 5000 });
      this.router.navigate(['/auth']);
      return;
    }

    this.loggedInUserId = this.storageService.getUserId() || 1;
    this.checkSubscriptionStatus();
    this.fetchUserVehicles();
    this.checkSpotAvailability();
  }

  getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('token');
    return new HttpHeaders({
      'Authorization': `Bearer ${token || ''}`,
      'Content-Type': 'application/json'
    });
  }

  checkSubscriptionStatus(): void {
    this.subscriptionService.getActiveSubscription(this.loggedInUserId || 1).subscribe({
      next: (subscription) => {
        this.hasActiveSubscription = subscription.status === 'ACTIVE';
      },
      error: (err) => {
        console.error('Subscription error:', err);
        this.hasActiveSubscription = false;
        this.snackBar.open('Aucun abonnement actif détecté.', 'Fermer', { duration: 5000 });
      }
    });
  }

  fetchUserVehicles(): void {
    this.http.get<any>('http://localhost:8082/parking/api/user/profile', {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        this.userVehicles = (response.vehicles || []).map((v: any) => ({
          id: v.id || 'UNKNOWN',
          matricule: v.matricule || 'UNKNOWN',
          vehicleType: v.vehicleType || 'car',
          name: `${v.brand || ''} ${v.model || ''}`.trim() || 'Véhicule'
        }));
        if (this.userVehicles.length > 0) {
          this.selectedVehicleIndex = 0;
        }
      },
      error: (err) => {
        this.errorMessage = 'Erreur lors de la récupération des véhicules.';
        console.error('Fetch vehicles error:', err);
      }
    });
  }

  checkSpotAvailability(): void {
    this.isLoading = true;
    this.errorMessage = null;

    const dateValue = this.reservationForm.get('date')?.value || new Date();
    const startTime = this.reservationForm.get('startTime')?.value || '10:00';
    const endTime = this.reservationForm.get('endTime')?.value || '12:00';

    const formattedDate = formatDate(dateValue, 'yyyy-MM-dd', 'en');
    const formattedStartTime = `${formattedDate}T${startTime}:00`;
    const formattedEndTime = `${formattedDate}T${endTime}:00`;

    const queryParams = `startTime=${encodeURIComponent(formattedStartTime)}&endTime=${encodeURIComponent(formattedEndTime)}`;

    console.log('Fetching spots with query:', queryParams);

    this.http.get<any[]>(`http://localhost:8082/parking/api/parking-spots/available?${queryParams}`, {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        console.log('Spots response:', response);
        this.availableSpots = response.map(spot => ({
          id: spot.id.toString(),
          status: spot.available ? 'available' : 'reserved'
        }));
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Spots fetch error:', err);
        this.errorMessage = 'Erreur lors de la récupération des places de parking.';
        this.isLoading = false;
        if (err.status === 401) {
          this.storageService.logout();
          this.router.navigate(['/auth']);
        }
      }
    });
  }

  selectSpot(spot: ParkingSpot): void {
    if (spot.status !== 'available') return;
    this.selectedSpot = spot;
    this.selectedPlace = {
      id: spot.id,
      name: spot.id,
      type: spot.id.includes('A') ? 'premium' : 'standard',
      price: spot.id.includes('A') ? 8.0 : 5.0,
      features: spot.id.includes('A') ? ['Couverte', 'Sécurisée', 'Grand gabarit'] : ['Couverte']
    };
    this.calculateTotalCost();
  }

  selectVehicle(index: number): void {
    this.selectedVehicleIndex = index;
  }

  calculateTotalCost(): void {
    if (!this.selectedPlace || !this.reservationForm.get('startTime')?.value || !this.reservationForm.get('endTime')?.value) {
      this.totalAmount = 0;
      return;
    }

    const startTime = this.reservationForm.get('startTime')?.value.split(':').map(Number);
    const endTime = this.reservationForm.get('endTime')?.value.split(':').map(Number);
    const duration = (endTime[0] * 60 + endTime[1] - (startTime[0] * 60 + startTime[1])) / 60;
    let cost = duration * this.selectedPlace.price;
    if (this.hasActiveSubscription) cost *= 0.5;
    this.totalAmount = cost > 0 ? cost : 0;
  }

  nextStep(): void {
    if (this.currentStep === 1) {
      if (!this.selectedSpot) {
        this.snackBar.open('Veuillez sélectionner une place.', 'Fermer', { duration: 5000 });
        return;
      }
      this.currentStep++;
    } else if (this.currentStep === 2) {
      if (this.reservationForm.invalid || this.selectedVehicleIndex === null) {
        this.reservationForm.markAllAsTouched();
        this.snackBar.open('Veuillez compléter tous les champs obligatoires.', 'Fermer', { duration: 5000 });
        return;
      }
      this.submitReservation();
    } else if (this.currentStep === 3) {
      if (!this.hasActiveSubscription && !this.reservationForm.get('paymentVerificationCode')?.value) {
        this.snackBar.open('Veuillez entrer le code de vérification.', 'Fermer', { duration: 5000 });
        return;
      }
      if (this.hasActiveSubscription && !this.reservationForm.get('reservationConfirmationCode')?.value) {
        this.snackBar.open('Veuillez entrer le code de confirmation.', 'Fermer', { duration: 5000 });
        return;
      }
      this.confirmReservation();
    }
  }

  prevStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  reset(): void {
    this.currentStep = 1;
    this.selectedSpot = null;
    this.selectedPlace = null;
    this.totalAmount = 0;
    this.reservationId = null;
    this.paymentVerificationCode = null;
    this.reservationConfirmationCode = null;
    this.isReservationConfirmed = false;
    this.errorMessage = null;
    this.reservationDetails = null;
    this.reservationForm.reset({
      date: new Date(),
      startTime: '10:00',
      endTime: '12:00',
      email: '',
      paymentVerificationCode: '',
      reservationConfirmationCode: ''
    });
    this.selectedVehicleIndex = this.userVehicles.length > 0 ? 0 : null;
    this.checkSpotAvailability();
  }

  submitReservation(): void {
    this.isLoading = true;
    this.errorMessage = null;

    const formDate = formatDate(this.reservationForm.get('date')?.value, 'yyyy-MM-dd', 'en');
    const startTime = this.reservationForm.get('startTime')?.value;
    const endTime = this.reservationForm.get('endTime')?.value;

    const reservationData = {
      userId: this.loggedInUserId || 1,
      parkingPlaceId: parseInt(this.selectedSpot!.id.split('-').pop() || '0', 10),
      matricule: this.userVehicles[this.selectedVehicleIndex!].matricule,
      startTime: `${formDate}T${startTime}:00`,
      endTime: `${formDate}T${endTime}:00`,
      vehicleType: this.userVehicles[this.selectedVehicleIndex!].vehicleType,
      paymentMethod: 'CARTE_BANCAIRE',
      email: this.reservationForm.get('email')?.value
    };

    // Set reservation details only if the form and vehicle are valid
    if (this.reservationForm.valid && this.selectedVehicleIndex !== null) {
      this.reservationDetails = {
        date: this.reservationForm.get('date')!.value,
        startTime: startTime,
        endTime: endTime,
        vehicleMatricule: this.userVehicles[this.selectedVehicleIndex].matricule
      };
    }

    this.http.post<ReservationResponse>('http://localhost:8082/parking/api/createReservation', reservationData, {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        console.log('Reservation response:', response);
        this.reservationId = response.reservationId;
        this.paymentVerificationCode = response.paymentVerificationCode || null;
        this.reservationConfirmationCode = response.reservationConfirmationCode || null;
        this.currentStep = 3;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Reservation error:', err);
        this.errorMessage = 'Erreur lors de la réservation: ' + (err.error?.message || err.message);
        this.isLoading = false;
      }
    });
  }

  confirmReservation(): void {
    this.isLoading = true;
    this.errorMessage = null;

    const reservationIdNum = parseInt(this.reservationId!.split('-').pop() || '0', 10);
    const queryParams = this.hasActiveSubscription
      ? `reservationId=${reservationIdNum}&reservationConfirmationCode=${this.reservationForm.get('reservationConfirmationCode')?.value}`
      : `reservationId=${reservationIdNum}&paymentVerificationCode=${this.reservationForm.get('paymentVerificationCode')?.value}`;

    const endpoint = this.hasActiveSubscription ? 'confirmReservation' : 'confirmPayment';

    this.http.post(`http://localhost:8082/parking/api/${endpoint}?${queryParams}`, {}, {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        console.log('Confirmation response:', response);
        this.isReservationConfirmed = true;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Confirmation error:', err);
        this.errorMessage = 'Erreur lors de la confirmation: ' + (err.error?.message || err.message);
        this.isLoading = false;
      }
    });
  }

  getToday(): Date {
    return new Date();
  }
}