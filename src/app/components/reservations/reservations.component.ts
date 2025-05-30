import { Component, OnInit, ChangeDetectorRef, ViewChild, ElementRef } from '@angular/core';
import { FormBuilder, FormGroup, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { CommonModule, DatePipe } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { ReactiveFormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { StorageService } from 'src/app/auth/services/storage/storage.service';
import { SubscriptionService } from 'src/app/services/subscription.service';
import { NgxMaskDirective, NgxMaskPipe, provideNgxMask } from 'ngx-mask';
import { QrCodeService } from 'src/app/services/qr-code.service';

// Interfaces
export interface ParkingSpot {
  id: string;
  status: 'available' | 'reserved';
}

export interface ReservationResponse {
  reservationId: string;
  paymentVerificationCode?: string;
  reservationConfirmationCode?: string;
  message?: string;
}

export interface PaymentResponse {
  reservationId: string;
  paymentVerificationCode?: string;
  message?: string;
}

export interface ReservationDetails {
  date: string;
  startTime: string;
  endTime: string;
  vehicleMatricule: string;
}

export interface Subscription {
  id: number;
  userId: number;
  subscriptionType: string;
  billingCycle: string;
  status: string;
  remainingPlaces: number;
  endDate?: string;
}

export interface Vehicle {
  id: string;
  matricule: string;
  vehicleType: string;
  name: string;
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
    MatSnackBarModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    NgxMaskDirective,
    NgxMaskPipe
  ],
  providers: [DatePipe, provideNgxMask()],
  templateUrl: './reservations.component.html',
  styleUrls: ['./reservations.component.css']
})
export class ReservationsComponent implements OnInit {
  currentStep = 1;
  reservationForm: FormGroup;
  paymentForm: FormGroup;
  availableSpots: ParkingSpot[] = [];
  selectedSpot: ParkingSpot | null = null;
  selectedPlace: any = null;
  userVehicles: Vehicle[] = [];
  selectedVehicleIndex: number | null = null;
  hasActiveSubscription = false;
  subscriptionId: number | null = null;
  subscriptionEndDate: string | null = null;
  remainingPlaces = 0;
  totalAmount = 0;
  isLoading = false;
  errorMessage = '';
  reservationId: string | null = null;
  paymentVerificationCode: string | null = null;
  reservationConfirmationCode: string | null = null;
  isReservationConfirmed = false;
  loggedInUserId: number | null = null;
  reservationDetails: ReservationDetails | null = null;
  emailConfirmation = false;
  apiUrl: string = 'http://localhost:8082/parking/api';
  qrCodeString: string | null = null;
  @ViewChild('qrCanvas', { static: false }) qrCanvas!: ElementRef<HTMLCanvasElement>;

  constructor(
    private http: HttpClient,
    private router: Router,
    private snackBar: MatSnackBar,
    private fb: FormBuilder,
    private storageService: StorageService,
    private subscriptionService: SubscriptionService,
    private datePipe: DatePipe,
    private cdr: ChangeDetectorRef,
    private qrCodeService: QrCodeService
  ) {
    const now = new Date();
    const startTime = new Date(now.getTime() + 60 * 60 * 1000);
    const endTime = new Date(startTime.getTime() + 60 * 60 * 1000);
    const formattedDate = this.datePipe.transform(now, 'dd/MM/yyyy') || '';
    const formattedStartTime = this.datePipe.transform(startTime, 'HH:mm') || '';
    const formattedEndTime = this.datePipe.transform(endTime, 'HH:mm') || '';
    const defaultEmail = this.storageService.getUser()?.email || '';

    this.reservationForm = this.fb.group({
      date: [formattedDate, [Validators.required, this.dateFormatValidator, this.dateRangeValidator]],
      startTime: [formattedStartTime, [Validators.required, this.startTimeValidator]],
      endTime: [formattedEndTime, [Validators.required, this.endTimeValidator]],
      email: [defaultEmail, [Validators.required, Validators.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/)]],
      paymentVerificationCode: [''],
      reservationConfirmationCode: ['']
    }, { validators: this.timeRangeValidator });

    this.paymentForm = this.fb.group({
      cardName: ['', Validators.required],
      cardNumber: ['', [Validators.required, Validators.pattern(/^\d{16}$/)]],
      cardExpiry: ['', [Validators.required, this.cardExpiryValidator]],
      cardCvv: ['', [Validators.required, Validators.pattern(/^\d{3}$/)]]
    });
  }

  get selectedVehicleMatricule(): string {
    return this.selectedVehicleIndex !== null && this.userVehicles[this.selectedVehicleIndex]
      ? this.userVehicles[this.selectedVehicleIndex].matricule
      : 'N/A';
  }

  ngOnInit(): void {
    if (!this.isAuthenticated()) {
      this.snackBar.open('Veuillez vous connecter pour continuer.', 'OK', { duration: 5000 });
      this.router.navigate(['/auth']);
      return;
    }

    const userId = this.storageService.getUserId();
    if (!userId || isNaN(Number(userId))) {
      this.snackBar.open('ID utilisateur invalide. Veuillez vous reconnecter.', 'OK', { duration: 5000 });
      this.storageService.logout();
      this.router.navigate(['/auth']);
      return;
    }
    this.loggedInUserId = Number(userId);

    this.checkSubscriptionStatus();
    this.fetchUserVehicles();
    this.checkSpotAvailability();
    this.reservationForm.markAllAsTouched();
  }

  isAuthenticated(): boolean {
    return this.storageService.isLoggedIn();
  }

  checkSubscriptionStatus(): void {
    if (!this.loggedInUserId) {
      console.error('No logged-in user ID');
      this.hasActiveSubscription = false;
      this.subscriptionId = null;
      this.subscriptionEndDate = null;
      this.remainingPlaces = 0;
      this.snackBar.open('Utilisateur non connecté.', 'OK', { duration: 5000 });
      this.cdr.detectChanges();
      return;
    }

    this.subscriptionService.getActiveSubscription(this.loggedInUserId).subscribe({
      next: (subscription: Subscription) => {
        if (subscription && subscription.status === 'ACTIVE' && subscription.remainingPlaces > 0) {
          this.hasActiveSubscription = true;
          this.subscriptionId = subscription.id;
          this.subscriptionEndDate = subscription.endDate || null;
          this.remainingPlaces = subscription.remainingPlaces;
        } else {
          this.hasActiveSubscription = false;
          this.subscriptionId = null;
          this.subscriptionEndDate = null;
          this.remainingPlaces = 0;
          this.snackBar.open('Aucun abonnement actif trouvé.', 'OK', { duration: 5000 });
        }
        console.log('Subscription status:', {
          hasActiveSubscription: this.hasActiveSubscription,
          subscriptionId: this.subscriptionId,
          remainingPlaces: this.remainingPlaces
        });
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Subscription check error:', JSON.stringify(err, null, 2));
        this.hasActiveSubscription = false;
        this.subscriptionId = null;
        this.subscriptionEndDate = null;
        this.remainingPlaces = 0;
        this.snackBar.open('Erreur lors de la vérification de l\'abonnement.', 'OK', { duration: 5000 });
        this.cdr.detectChanges();
      }
    });
  }

  // Validators
  dateFormatValidator = (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) return null;
    const regex = /^(\d{2})\/(\d{2})\/(\d{4})$/;
    if (!regex.test(control.value)) {
      return { invalidFormat: true };
    }
    const [day, month, year] = control.value.split('/').map(Number);
    const date = new Date(year, month - 1, day);
    if (date.getFullYear() !== year || date.getMonth() + 1 !== month || date.getDate() !== day) {
      return { invalidDate: true };
    }
    return null;
  };

  dateRangeValidator = (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) return null;
    const [day, month, year] = control.value.split('/').map(Number);
    const inputDate = new Date(year, month - 1, day);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (inputDate < today) {
      return { outOfRange: true };
    }
    return null;
  };

  startTimeValidator = (control: AbstractControl): ValidationErrors | null => {
    if (!control.value || !control.parent) return null;
    const dateControl = control.parent.get('date');
    if (!dateControl?.value) return null;

    const [day, month, year] = dateControl.value.split('/').map(Number);
    const inputDate = new Date(year, month - 1, day);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (inputDate.getTime() === today.getTime()) {
      const [hours, minutes] = control.value.split(':').map(Number);
      const inputTime = new Date();
      inputTime.setHours(hours, minutes, 0, 0);
      const now = new Date();
      now.setMinutes(now.getMinutes() + 60);
      if (inputTime < now) {
        return { invalidTime: true };
      }
    }
    return null;
  };

  endTimeValidator = (control: AbstractControl): ValidationErrors | null => {
    if (!control.value || !control.parent) return null;
    const startTime = control.parent.get('startTime')?.value;
    if (!startTime) return null;

    const [startHours, startMinutes] = startTime.split(':').map(Number);
    const [endHours, endMinutes] = control.value.split(':').map(Number);

    const start = new Date(0, 0, 0, startHours, startMinutes);
    const end = new Date(0, 0, 0, endHours, endMinutes);

    if (end <= start) {
      return { invalidEndTime: true };
    }
    return null;
  };

  timeRangeValidator = (form: FormGroup): ValidationErrors | null => {
    const startTime = form.get('startTime')?.value;
    const endTime = form.get('endTime')?.value;
    if (!startTime || !endTime) return null;

    const [startHours, startMinutes] = startTime.split(':').map(Number);
    const [endHours, endMinutes] = endTime.split(':').map(Number);

    const start = new Date(0, 0, 0, startHours, startMinutes);
    const end = new Date(0, 0, 0, endHours, endMinutes);

    if (end <= start) {
      return { invalidTimeRange: true };
    }
    return null;
  };

  cardExpiryValidator = (control: AbstractControl): ValidationErrors | null => {
    const value = (control.value || '').trim().replace(/\s+/g, '');
    if (!value) return { required: true };
    const regex = /^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$/;
    if (!regex.test(value)) {
      return { invalidFormat: 'Format invalide, utiliser MM/AA ou MM/AAAA (ex: 07/29 ou 07/2029)' };
    }
    const [month, yearStr] = value.split('/').map(Number);
    let fullYear = yearStr;
    if (yearStr < 100) {
      fullYear = 2000 + yearStr;
    }
    const currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0);
    const currentMonth = currentDate.getMonth() + 1;
    const currentYear = currentDate.getFullYear();
    if (fullYear < currentYear || (fullYear === currentYear && month < currentMonth)) {
      return { expired: 'Carte expirée' };
    }
    return null;
  };

  normalizeExpiry(event: Event): void {
    const input = event.target as HTMLInputElement;
    let value = input.value.trim().replace(/[^0-9\/]/g, '');
    if (value.length > 7) {
      value = value.slice(0, 7);
    }
    if (value.length === 2 && !value.includes('/')) {
      value += '/';
    }
    input.value = value;
    this.paymentForm.get('cardExpiry')?.setValue(value, { emitEvent: false });
    this.paymentForm.get('cardExpiry')?.updateValueAndValidity();
  }

  getAuthHeaders(): HttpHeaders {
    const token = this.storageService.getToken();
    return new HttpHeaders({
      'Authorization': `Bearer ${token || ''}`,
      'Content-Type': 'application/json'
    });
  }

  fetchUserVehicles(): void {
    this.http.get<any>(`${this.apiUrl}/user/profile`, {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        this.userVehicles = (response.vehicles || []).map((v: any) => ({
          id: v.id || 'UNKNOWN',
          matricule: (v.matricule || 'UNKNOWN').toUpperCase(),
          vehicleType: v.vehicleType?.toUpperCase() || 'CAR', // Normalize to uppercase
          name: `${v.brand || ''} ${v.model || ''}`.trim() || 'Vehicle'
        }));
        if (this.userVehicles.length > 0) {
          this.selectedVehicleIndex = 0;
        } else {
          this.selectedVehicleIndex = null;
          this.snackBar.open('Aucun véhicule enregistré. Veuillez en ajouter un.', 'OK', { duration: 5000 });
          this.router.navigate(['/vehicles/add']);
        }
        console.log('User vehicles:', this.userVehicles);
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Vehicle fetch error:', JSON.stringify(err, null, 2));
        this.errorMessage = 'Erreur lors de la récupération des véhicules.';
        this.userVehicles = [];
        this.selectedVehicleIndex = null;
        this.snackBar.open('Aucun véhicule enregistré. Veuillez en ajouter un.', 'OK', { duration: 5000 });
        this.router.navigate(['/vehicles/add']);
        this.cdr.detectChanges();
      }
    });
  }

  checkSpotAvailability(): void {
    const startTime = this.reservationForm.get('startTime')?.value;
    const endTime = this.reservationForm.get('endTime')?.value;
    const date = this.reservationForm.get('date')?.value;

    if (!startTime || !endTime || !date) {
      this.availableSpots = [];
      this.snackBar.open('Veuillez entrer une date et des heures valides.', 'OK', { duration: 5000 });
      return;
    }

    const formattedStartTime = `${this.formatDateForBackend(date)}T${startTime.padStart(5, '0')}:00`;
    const formattedEndTime = `${this.formatDateForBackend(date)}T${endTime.padStart(5, '0')}:00`;

    this.isLoading = true;
    this.http.get<any[]>(`${this.apiUrl}/parking-spots/available`, {
      headers: this.getAuthHeaders(),
      params: {
        startTime: formattedStartTime,
        endTime: formattedEndTime
      }
    }).subscribe({
      next: (response) => {
        this.availableSpots = response.map(spot => ({
          id: spot.id.toString(),
          status: spot.available ? 'available' : 'reserved'
        }));
        if (!this.availableSpots.find(spot => spot.id === this.selectedSpot?.id)) {
          this.selectedSpot = null;
          this.selectedPlace = null;
        }
        this.isLoading = false;
        console.log('Available spots:', this.availableSpots);
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Spot availability error:', JSON.stringify(err, null, 2));
        this.availableSpots = [];
        this.selectedSpot = null;
        this.selectedPlace = null;
        this.isLoading = false;
        this.errorMessage = 'Erreur lors de la vérification des places disponibles.';
        this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
        this.cdr.detectChanges();
      }
    });
  }

  selectSpot(spot: ParkingSpot): void {
    if (spot.status === 'available') {
      this.selectedSpot = spot;
      this.selectedPlace = {
        id: spot.id,
        name: spot.id,
        type: spot.id.includes('A') ? 'premium' : 'standard',
        price: spot.id.includes('A') ? 8.0 : 5.0,
        features: spot.id.includes('A') ? ['Couvert', 'Large'] : ['Couvert']
      };
      this.calculateTotalAmount();
      console.log('Selected spot:', this.selectedSpot);
      this.cdr.detectChanges();
    } else {
      this.snackBar.open('Cette place est déjà réservée.', 'OK', { duration: 5000 });
    }
  }

  calculateTotalAmount(): void {
    if (!this.selectedPlace || !this.reservationForm.get('startTime')?.value || !this.reservationForm.get('endTime')?.value) {
      this.totalAmount = 0;
      return;
    }

    const startTime = this.reservationForm.get('startTime')?.value;
    const endTime = this.reservationForm.get('endTime')?.value;
    const [startHours, startMinutes] = startTime.split(':').map(Number);
    const [endHours, endMinutes] = endTime.split(':').map(Number);

    const durationHours = (endHours + endMinutes / 60) - (startHours + startMinutes / 60);
    const basePrice = this.selectedPlace.price || 5.0;
    let cost = durationHours * basePrice;

    if (this.hasActiveSubscription) {
      cost = 0; // Free for subscribed users
    } else if (durationHours > 5) {
      cost *= 0.9; // 10% discount for > 5 hours
    }

    this.totalAmount = cost > 0 ? Number(cost.toFixed(2)) : 0;
    this.cdr.detectChanges();
  }

 submitReservation(): void {
    this.isLoading = true;
    this.errorMessage = '';

    if (!this.reservationForm.valid) {
      this.errorMessage = 'Veuillez corriger les erreurs dans le formulaire.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    if (!this.selectedSpot || !this.selectedSpot.id) {
      this.errorMessage = 'Veuillez sélectionner une place de parking.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    if (this.selectedVehicleIndex === null) {
      this.errorMessage = 'Veuillez sélectionner un véhicule.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    const dateValue: string = this.reservationForm.get('date')?.value ?? '';
    const startTime: string = this.reservationForm.get('startTime')?.value ?? '';
    const endTime: string = this.reservationForm.get('endTime')?.value ?? '';
    const vehicleMatricule = this.userVehicles[this.selectedVehicleIndex].matricule;
    const email = this.reservationForm.get('email')?.value;

    if (!/^[A-Z0-9]{3,10}$/.test(vehicleMatricule)) {
      this.errorMessage = 'Matricule invalide. Utilisez 3 à 10 caractères alphanumériques en majuscules.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    if (this.hasActiveSubscription && this.remainingPlaces <= 0) {
      this.errorMessage = 'Aucune place restante dans votre abonnement.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    // Parse parkingPlaceId safely
    const idStr = this.selectedSpot.id.includes('-') ? this.selectedSpot.id.split('-').pop() : this.selectedSpot.id;
    const parkingPlaceId = parseInt(idStr || '0', 10);
    if (isNaN(parkingPlaceId) || parkingPlaceId <= 0) {
      this.errorMessage = `ID de place de parking invalide: ${this.selectedSpot.id}`;
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    // Ensure time format is HH:mm:ss
    const formattedStartTime = `${this.formatDateForBackend(dateValue)}T${startTime.padStart(5, '0')}:00`;
    const formattedEndTime = `${this.formatDateForBackend(dateValue)}T${endTime.padStart(5, '0')}:00`;

    const reservationData = {
      userId: this.loggedInUserId!,
      parkingPlaceId: parkingPlaceId,
      matricule: vehicleMatricule,
      startTime: formattedStartTime,
      endTime: formattedEndTime,
      vehicleType: this.userVehicles[this.selectedVehicleIndex].vehicleType.toUpperCase() || 'CAR',
      paymentMethod: this.hasActiveSubscription ? 'SUBSCRIPTION' : 'CARTE_BANCAIRE',
      email: email,
      subscriptionId: this.hasActiveSubscription ? this.subscriptionId : null,
      specialRequest: null
    };

    console.log('Reservation request payload:', JSON.stringify(reservationData, null, 2));

    this.http.post<ReservationResponse>(`${this.apiUrl}/createReservation`, reservationData, {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        this.reservationId = response.reservationId || null;
        this.reservationConfirmationCode = response.reservationConfirmationCode || null;
        this.paymentVerificationCode = response.paymentVerificationCode || null; // Handle payment verification code
        this.reservationDetails = {
          date: dateValue,
          startTime: startTime,
          endTime: endTime,
          vehicleMatricule: vehicleMatricule
        };
        this.emailConfirmation = true;
        if (this.hasActiveSubscription && this.reservationConfirmationCode) {
          this.reservationForm.get('reservationConfirmationCode')?.setValidators([Validators.required]);
          this.reservationForm.get('reservationConfirmationCode')?.updateValueAndValidity();
          this.snackBar.open('Réservation créée. Vérifiez votre email pour le code de confirmation.', 'OK', { duration: 5000 });
          this.currentStep = 3;
        } else if (this.paymentVerificationCode) {
          this.reservationForm.get('paymentVerificationCode')?.setValidators([Validators.required]);
          this.reservationForm.get('paymentVerificationCode')?.updateValueAndValidity();
          this.snackBar.open('Réservation créée. Vérifiez votre email pour le code de vérification de paiement.', 'OK', { duration: 5000 });
          this.currentStep = 3;
        } else {
          this.snackBar.open('Réservation créée. Veuillez entrer les détails de paiement.', 'OK', { duration: 5000 });
          this.currentStep = 3;
        }
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Reservation error response:', JSON.stringify(err, null, 2));
        this.errorMessage = err.error?.message || 'Erreur lors de la création de la réservation.';
        this.emailConfirmation = false;
        this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
}

  submitPayment(): void {
    if (!this.paymentForm.valid) {
      this.errorMessage = 'Veuillez compléter les informations de paiement.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    if (!this.reservationId) {
      this.errorMessage = 'Aucune réservation en cours.';
      this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    const reservationIdNum = parseInt(this.reservationId.split('-').pop() || '0', 10);
    const paymentData = {
      reservationId: reservationIdNum,
      amount: this.totalAmount,
      paymentMethod: 'CREDIT_CARD',
      paymentReference: this.paymentForm.get('cardNumber')?.value?.substring(12) || 'XXXX',
      cardDetails: {
        cardName: this.paymentForm.get('cardName')?.value,
        cardNumber: this.paymentForm.get('cardNumber')?.value,
        cardExpiry: this.paymentForm.get('cardExpiry')?.value,
        cardCvv: this.paymentForm.get('cardCvv')?.value
      }
    };

    this.isLoading = true;
    this.http.post<PaymentResponse>(`${this.apiUrl}/payment/processPayment`, paymentData, {
      headers: this.getAuthHeaders()
    }).subscribe({
      next: (response) => {
        this.paymentVerificationCode = response.paymentVerificationCode || null;
        this.reservationForm.get('paymentVerificationCode')?.setValidators([Validators.required]);
        this.reservationForm.get('paymentVerificationCode')?.updateValueAndValidity();
        this.snackBar.open('Paiement soumis. Vérifiez votre email pour le code de vérification.', 'OK', { duration: 5000 });
        this.currentStep = 4;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Payment error:', JSON.stringify(err, null, 2));
        this.errorMessage = err.error?.message || 'Erreur lors du traitement du paiement.';
        this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  confirmPayment(): void {
    this.isLoading = true;
    this.errorMessage = '';

    const reservationId = this.reservationId || '0';
    const paymentVerificationCode = this.reservationForm.get('paymentVerificationCode')?.value || '';

    if (!paymentVerificationCode) {
      this.snackBar.open('Le code de vérification est requis.', 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    this.http.post(`${this.apiUrl}/confirmPayment`, null, {
      headers: this.getAuthHeaders(),
      params: {
        reservationId: reservationId,
        paymentVerificationCode: paymentVerificationCode
      }
    }).subscribe({
      next: (response: any) => {
        this.reservationId = response.reservationId || this.reservationId;
        this.isReservationConfirmed = true;
        this.qrCodeString = this.reservationId;
        setTimeout(() => this.generateQrCode(), 100);
        this.currentStep = 4;
        this.snackBar.open('Réservation confirmée avec succès.', 'OK', { duration: 5000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Payment confirmation error:', JSON.stringify(err, null, 2));
        this.errorMessage = err.error?.message || 'Erreur lors de la confirmation du paiement.';
        this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  verifyReservation(): void {
    this.isLoading = true;
    this.errorMessage = '';

    const reservationId = this.reservationId || '0';
    const confirmationCode = this.reservationForm.get('reservationConfirmationCode')?.value || '';

    if (!confirmationCode) {
      this.snackBar.open('Le code de confirmation est requis.', 'OK', { duration: 6000 });
      this.isLoading = false;
      this.cdr.detectChanges();
      return;
    }

    this.http.post(`${this.apiUrl}/confirmReservation`, null, {
      headers: this.getAuthHeaders(),
      params: {
        reservationId: reservationId,
        reservationConfirmationCode: confirmationCode
      }
    }).subscribe({
      next: () => {
        this.isReservationConfirmed = true;
        this.qrCodeString = this.reservationId;
        setTimeout(() => this.generateQrCode(), 100);
        this.currentStep = 4;
        this.snackBar.open('Réservation confirmée.', 'OK', { duration: 5000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Reservation confirmation error:', JSON.stringify(err, null, 2));
        this.errorMessage = err.error?.message || 'Erreur lors de la confirmation de la réservation.';
        this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  resendConfirmationEmail(): void {
    if (!this.reservationId) {
      this.snackBar.open('Aucune réservation en cours.', 'OK', { duration: 5000 });
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    this.http.post(`${this.apiUrl}/resendConfirmation`, null, {
      headers: this.getAuthHeaders(),
      params: {
        reservationId: this.reservationId
      }
    }).subscribe({
      next: () => {
        this.snackBar.open('Email de confirmation renvoyé.', 'OK', { duration: 5000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err: HttpErrorResponse) => {
        console.error('Resend confirmation error:', JSON.stringify(err, null, 2));
        this.errorMessage = err.error?.message || 'Erreur lors du renvoi de l\'email.';
        this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  confirmReservation(): void {
    this.verifyReservation();
  }

  reset(): void {
    this.currentStep = 1;
    this.reservationForm.reset({
      date: this.datePipe.transform(new Date(), 'dd/MM/yyyy') || '',
      startTime: this.datePipe.transform(new Date(new Date().getTime() + 60 * 60 * 1000), 'HH:mm') || '',
      endTime: this.datePipe.transform(new Date(new Date().getTime() + 2 * 60 * 60 * 1000), 'HH:mm') || '',
      email: this.storageService.getUser()?.email || '',
      paymentVerificationCode: '',
      reservationConfirmationCode: ''
    });
    this.paymentForm.reset();
    this.selectedSpot = null;
    this.selectedPlace = null;
    this.selectedVehicleIndex = this.userVehicles.length > 0 ? 0 : null;
    this.totalAmount = 0;
    this.errorMessage = '';
    this.reservationId = null;
    this.paymentVerificationCode = null;
    this.reservationConfirmationCode = null;
    this.isReservationConfirmed = false;
    this.reservationDetails = null;
    this.emailConfirmation = false;
    this.qrCodeString = null;
    this.checkSpotAvailability();
    this.cdr.detectChanges();
  }

  generateQrCode(): void {
    if (this.qrCodeString && this.qrCanvas?.nativeElement) {
      this.qrCodeService.generateQrCode(this.qrCanvas.nativeElement, this.qrCodeString)
        .then(() => {
          this.cdr.detectChanges();
        })
        .catch(err => {
          console.error('QR code generation error:', err);
          this.errorMessage = 'Erreur lors de la génération du QR code.';
          this.snackBar.open(this.errorMessage, 'OK', { duration: 6000 });
          this.cdr.detectChanges();
        });
    }
  }

  nextStep(): void {
    if (this.currentStep === 1 && !this.selectedSpot) {
      this.snackBar.open('Veuillez sélectionner une place de parking.', 'OK', { duration: 5000 });
      return;
    }
    if (this.currentStep === 2 && (!this.reservationForm.valid || this.selectedVehicleIndex === null)) {
      this.snackBar.open('Veuillez compléter toutes les informations requises.', 'OK', { duration: 5000 });
      return;
    }
    if (this.currentStep === 2) {
      this.submitReservation();
      return;
    }
    if (this.currentStep === 3) {
      if (this.hasActiveSubscription) {
        this.verifyReservation();
      } else {
        this.submitPayment();
      }
      return;
    }
    this.currentStep++;
    this.cdr.detectChanges();
  }

  prevStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
      this.errorMessage = '';
      this.cdr.detectChanges();
    }
  }

  formatDateForBackend(dateString: string): string {
    const [day, month, year] = dateString.split('/').map(Number);
    return `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
  }

  onDateTimeChange(): void {
    this.checkSpotAvailability();
    this.calculateTotalAmount();
  }

  selectVehicle(index: number): void {
    this.selectedVehicleIndex = index;
    console.log('Selected vehicle:', this.userVehicles[index]);
    this.cdr.detectChanges();
  }

  navigateToAddVehicle(): void {
    this.router.navigate(['/vehicles/add']);
  }
}