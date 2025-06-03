// subscription.component.ts
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, AbstractControl, ValidationErrors, ReactiveFormsModule } from '@angular/forms';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Router, RouterLink } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { CommonModule, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { StorageService } from 'src/app/auth/services/storage/storage.service';
import { SubscriptionService, Subscription } from 'src/app/services/subscription.service';
import { NgxMaskDirective, NgxMaskPipe, provideNgxMask } from 'ngx-mask';

interface SubscriptionPlan {
  id: number;
  name: string;
  type: string;
  monthlyPrice: number;
  features: string[];
  excludedFeatures: string[];
  isPopular: boolean;
}

interface Vehicle {
  id: number;
  brand: string;
  model: string;
  matricule: string;
}

@Component({
  selector: 'app-subscription',
  templateUrl: './subscription.component.html',
  styleUrls: ['./subscription.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatTooltipModule,
    RouterLink,
    NgxMaskDirective,
    NgxMaskPipe,
    ReactiveFormsModule,
  ],
  providers: [DatePipe, provideNgxMask()],
})
export class SubscriptionComponent implements OnInit {
  currentStep = 1;
  subscriptionForm: FormGroup;
  plans = new BehaviorSubject<SubscriptionPlan[]>([]);
  selectedPlan = new BehaviorSubject<number | null>(null);
  billingType = new BehaviorSubject<'monthly' | 'annual'>('monthly');
  vehicles = new BehaviorSubject<Vehicle[]>([]);
  isLoading = false;
  profileLoaded = false;
  sessionId: string | null = null;
  subscriptionConfirmationCode: string | null = null;
  subscriptionConfirmed = false;
  hasActiveSubscription = false;
  activeSubscription: Subscription | null = null;
  private lastButtonPressTime: number | null = null;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private subscriptionService: SubscriptionService,
    private storageService: StorageService,
    private snackBar: MatSnackBar,
    private router: Router,
    private datePipe: DatePipe
  ) {
    this.subscriptionForm = this.fb.group({
      email: ['', [Validators.required, Validators.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/)]],
      cardName: ['', Validators.required],
      cardNumber: ['', [Validators.required, Validators.pattern(/^\d{16}$/)]],
      cardExpiry: ['', [Validators.required, this.cardExpiryValidator]],
      cardCvv: ['', [Validators.required, Validators.pattern(/^\d{3}$/)]],
      subscriptionConfirmationCode: [''],
    });
  }

  cardExpiryValidator = (control: AbstractControl): ValidationErrors | null => {
    const value = (control.value || '').trim().replace(/\s+/g, '');
    if (!value) return { required: true };
    const regex = /^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$/;
    if (!regex.test(value)) {
      return { invalidFormat: 'Format invalide, utiliser MM/AA ou MM/AAAA (ex: 07/29 ou 07/2029)' };
    }
    const [month, yearStr] = value.split('/').map(Number);
    let fullYear = yearStr;
    if (yearStr < 100) fullYear = 2000 + yearStr;
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
  let value = input.value; // Start with the raw input value (e.g., "08/____" or "08/2029")
  
  // Remove non-numeric characters except the slash
  let numericValue = value.replace(/[^0-9\/]/g, '');
  
  if (numericValue.length > 0) {
    // Extract digits only to manipulate
    const digits = numericValue.replace(/[^0-9]/g, '');
    
    // Format as MM/YYYY
    let formattedValue = '';
    if (digits.length <= 2) {
      formattedValue = digits; // e.g., "08"
    } else {
      const month = digits.slice(0, 2);
      const year = digits.slice(2, 6); // Allow up to 4 digits for year
      formattedValue = month + (year.length > 0 ? '/' + year : '/');
      // Cap month at 12
      if (parseInt(month) > 12) {
        formattedValue = '12' + (year.length > 0 ? '/' + year : '/');
      }
    }
    
    // Update the input value
    value = formattedValue;
  }
  
  input.value = value;
  this.subscriptionForm.get('cardExpiry')?.setValue(value, { emitEvent: false });
  this.subscriptionForm.get('cardExpiry')?.updateValueAndValidity();
}

  ngOnInit(): void {
    if (!this.storageService.isLoggedIn()) {
      this.snackBar.open('Veuillez vous connecter pour continuer.', 'Fermer', { duration: 5000 });
      this.router.navigate(['/login']);
      return;
    }
    const userId = this.storageService.getUserId();
    if (!userId) {
      this.snackBar.open('Utilisateur non trouvé. Veuillez vous reconnecter.', 'Fermer', { duration: 5000 });
      this.router.navigate(['/login']);
      return;
    }

    this.isLoading = true;
    this.loadPlans();

    this.subscriptionService.getActiveSubscription(userId).subscribe({
      next: (subscription) => {
        this.hasActiveSubscription = !!subscription && subscription.status === 'ACTIVE';
        this.activeSubscription = subscription;
        this.isLoading = false;
      },
      error: (err) => {
        if (err.status !== 404) {
          console.error('Error checking active subscription:', err);
          this.snackBar.open('Erreur inattendue lors de la vérification de l’abonnement actif.', 'Fermer', { duration: 5000 });
          this.errorMessage = 'Erreur inattendue lors de la vérification de l’abonnement actif.';
        }
        this.hasActiveSubscription = false;
        this.isLoading = false;
      },
    });

    this.subscriptionService.getUserProfile().subscribe({
      next: (user) => {
        this.subscriptionForm.patchValue({ email: user.email || '' });
        const userVehicles = user.vehicles || [];
        this.vehicles.next(userVehicles);
        if (userVehicles.length === 0) {
          this.errorMessage = 'Veuillez ajouter un véhicule dans votre profil avant de continuer. <a href="/profile" class="text-primary-purple underline">Aller au profil</a>.';
        }
        this.profileLoaded = true;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Profile fetch error:', err);
        this.snackBar.open('Impossible de charger le profil. Veuillez entrer les informations manuellement.', 'Fermer', { duration: 5000 });
        this.vehicles.next([]);
        this.profileLoaded = true;
        this.isLoading = false;
      },
    });
  }

  loadPlans(): void {
    this.isLoading = true;
    this.subscriptionService.getSubscriptionPlans().subscribe({
      next: (plans: any[]) => {
        const processedPlans: SubscriptionPlan[] = plans.map((plan: any) => ({
          id: plan.id,
          name: plan.type,
          type: plan.type,
          monthlyPrice: plan.monthlyPrice,
          features: [
            'Accès à tous les parkings',
            plan.parkingDurationLimit > 0
              ? `${plan.parkingDurationLimit} heures de stationnement par jour`
              : 'Stationnement illimité',
            `Réservation ${plan.advanceReservationDays} jour${plan.advanceReservationDays !== 1 ? 's' : ''} à l'avance`,
            ...(plan.hasPremiumSpots ? ['Accès aux places premium'] : []),
            ...(plan.hasValetService ? ['Service de voiturier inclus'] : []),
          ],
          excludedFeatures: [
            ...(plan.hasPremiumSpots ? [] : ['Places premium']),
            ...(plan.hasValetService ? [] : ['Service de voiturier']),
          ],
          isPopular: plan.isPopular,
        }));
        this.plans.next(processedPlans);
        this.selectedPlan.next(processedPlans.find((p: SubscriptionPlan) => p.type === 'Premium')?.id || processedPlans[0]?.id || null);
        this.isLoading = false;
      },
      error: (err) => {
        this.isLoading = false;
        console.error('Plan fetch error:', err);
        this.snackBar.open('Erreur lors du chargement des forfaits. Veuillez réessayer plus tard.', 'Fermer', { duration: 5000 });
        const defaultPlans: SubscriptionPlan[] = [
          { id: 1, name: 'Basic', type: 'Basic', monthlyPrice: 10, features: ['Accès à tous les parkings', 'Stationnement illimité', 'Réservation 1 jour à l’avance'], excludedFeatures: ['Places premium', 'Service de voiturier'], isPopular: false },
          { id: 2, name: 'Premium', type: 'Premium', monthlyPrice: 20, features: ['Accès à tous les parkings', 'Stationnement illimité', 'Réservation 7 jours à l’avance', 'Accès aux places premium'], excludedFeatures: ['Service de voiturier'], isPopular: true },
          { id: 3, name: 'Elite', type: 'Elite', monthlyPrice: 30, features: ['Accès à tous les parkings', 'Stationnement illimité', 'Réservation 14 jours à l’avance', 'Accès aux places premium', 'Service de voiturier inclus'], excludedFeatures: [], isPopular: false },
        ];
        this.plans.next(defaultPlans);
        this.selectedPlan.next(defaultPlans.find((p) => p.type === 'Premium')?.id || defaultPlans[0]?.id || null);
      },
    });
  }

  toggleBillingType(): void {
    this.billingType.next(this.billingType.value === 'monthly' ? 'annual' : 'monthly');
  }

  selectPlan(planId: number): void {
  if (this.hasActiveSubscription) {
    this.snackBar.open('Vous ne pouvez pas souscrire à un nouvel abonnement tant que votre abonnement actif est en cours.', 'Fermer', { duration: 5000 });
    return;
  }
  this.selectedPlan.next(planId);
}

  calculatePrice(monthlyPrice: number): number {
    return this.billingType.value === 'annual' ? Math.round(monthlyPrice * 12 * 0.8) : monthlyPrice;
  }

  getSelectedPlanPrice(): number {
    const plan = this.plans.value.find((p) => p.id === this.selectedPlan.value);
    return plan ? this.calculatePrice(plan.monthlyPrice) : 0;
  }

  canPressButton(): boolean {
    const now = Date.now();
    if (!this.lastButtonPressTime || now - this.lastButtonPressTime > 2000) {
      this.lastButtonPressTime = now;
      return true;
    }
    return false;
  }

  nextStep(): void {
    if (!this.canPressButton()) return;

    if (this.currentStep === 1) {
      if (this.vehicles.value.length === 0 || !this.selectedPlan.value) {
        this.snackBar.open(
          `Veuillez ${this.vehicles.value.length === 0 ? 'ajouter un véhicule' : ''}${this.vehicles.value.length === 0 && !this.selectedPlan.value ? ' et ' : ''}${!this.selectedPlan.value ? 'sélectionner un forfait' : ''}.`,
          'Fermer',
          { duration: 5000 }
        );
        if (this.vehicles.value.length === 0) this.router.navigate(['/profile']);
        return;
      }
      if (this.hasActiveSubscription) {
        this.snackBar.open('Vous avez un abonnement actif. Veuillez l’annuler ou le gérer avant de souscrire un nouveau.', 'Fermer', { duration: 5000 });
        this.router.navigate(['/app/user/subscriptions/manage']); // Redirect to a manage subscriptions page
        return;
      }
      this.currentStep = 2;
    } else if (this.currentStep === 2) {
      this.initiateSubscription();
    } else if (this.currentStep === 3) {
      this.confirmSubscription();
    }
  }

  prevStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
      this.isLoading = false;
      this.errorMessage = '';
    }
  }

  reset(): void {
    this.currentStep = 1;
    this.selectedPlan.next(this.plans.value.find((p) => p.type === 'Premium')?.id || this.plans.value[0]?.id || null);
    this.billingType.next('monthly');
    this.subscriptionForm.reset({ email: this.subscriptionForm.get('email')?.value });
    this.sessionId = null;
    this.subscriptionConfirmationCode = null;
    this.isLoading = false;
    this.errorMessage = '';
  }

  initiateSubscription(): void {
  if (this.subscriptionForm.invalid) {
    this.subscriptionForm.markAllAsTouched();
    this.snackBar.open('Veuillez compléter tous les champs obligatoires.', 'Fermer', { duration: 5000 });
    return;
  }

  this.isLoading = true;
  const plan = this.plans.value.find((p) => p.id === this.selectedPlan.value);
  if (!plan) {
    this.snackBar.open('Veuillez sélectionner un forfait.', 'Fermer', { duration: 5000 });
    this.isLoading = false;
    return;
  }

  const billingCycle = this.billingType.value;
  const subscriptionType = plan.type;
  const amount = this.calculatePrice(plan.monthlyPrice);
  const email = this.subscriptionForm.get('email')?.value;
  const cardDetails = {
    cardNumber: this.subscriptionForm.get('cardNumber')?.value,
    expiryDate: this.subscriptionForm.get('cardExpiry')?.value,
    cvv: this.subscriptionForm.get('cardCvv')?.value,
    cardName: this.subscriptionForm.get('cardName')?.value,
  };

  const payload = {
    userId: this.storageService.getUserId().toString(),
    subscriptionType,
    billingCycle,
    amount,
    paymentMethod: 'CARTE_BANCAIRE',
    email,
    cardNumber: cardDetails.cardNumber,
    expiryDate: cardDetails.expiryDate,
    cvv: cardDetails.cvv,
    cardName: cardDetails.cardName,
    paymentReference: cardDetails.cardNumber?.substring(12, 16) || 'XXXX',
  };

  console.log('Subscription payload:', payload); // Debug the payload

  this.subscriptionService.subscribe(subscriptionType, billingCycle, amount, 'CARTE_BANCAIRE', email, cardDetails).subscribe({
    next: (response) => {
      this.isLoading = false;
      this.sessionId = response.session_id || null;
      this.subscriptionConfirmationCode = response.paymentVerificationCode || null;
      this.currentStep = 3;
      this.subscriptionForm.get('subscriptionConfirmationCode')?.setValidators([Validators.required]);
      this.subscriptionForm.get('subscriptionConfirmationCode')?.updateValueAndValidity();
      this.snackBar.open('Paiement initié. Veuillez vérifier votre email pour le code de confirmation.', 'OK', { duration: 5000 });
      if (this.subscriptionConfirmationCode) {
        this.snackBar.open(`Code de confirmation (test): ${this.subscriptionConfirmationCode}`, 'OK', { duration: 10000 });
      }
    },
    error: (err) => {
      this.isLoading = false;
      console.error('Full error:', err);
      const errorMessage = err.error?.message || err.message || 'Erreur inconnue';
      const message = err.status === 401 ? 'Session expirée. Veuillez vous reconnecter.' : `Erreur lors de la souscription: ${errorMessage}`;
      this.snackBar.open(message, 'Fermer', { duration: 5000 });
      this.errorMessage = message;
      if (err.status === 401) {
        this.storageService.logout();
        this.router.navigate(['/login']);
      }
    },
  });
}

 confirmSubscription(): void {
  if (this.subscriptionForm.get('subscriptionConfirmationCode')?.invalid) {
    this.subscriptionForm.get('subscriptionConfirmationCode')?.markAsTouched();
    this.snackBar.open('Veuillez entrer le code de confirmation.', 'Fermer', { duration: 5000 });
    return;
  }

  if (!this.sessionId) {
    this.snackBar.open('ID de session manquant. Veuillez recommencer.', 'Fermer', { duration: 5000 });
    return;
  }

  this.isLoading = true;
  const subscriptionConfirmationCode = this.subscriptionForm.get('subscriptionConfirmationCode')?.value;
  const userId = this.storageService.getUserId();

  this.subscriptionService.confirmSubscription(this.sessionId, subscriptionConfirmationCode).subscribe({
    next: () => {
      this.isLoading = false;
      this.subscriptionConfirmed = true;
      // Fetch the updated active subscription
      this.subscriptionService.getActiveSubscription(userId).subscribe({
        next: (subscription) => {
          this.activeSubscription = subscription;
          this.snackBar.open('Abonnement confirmé avec succès!', 'OK', { duration: 5000 });
        },
        error: (err) => {
          console.error('Error fetching updated subscription:', err);
          this.snackBar.open('Abonnement confirmé, mais échec de la récupération des détails.', 'Fermer', { duration: 5000 });
          this.activeSubscription = null; // Fallback if fetch fails
        },
      });
    },
    error: (err) => {
      this.isLoading = false;
      const errorMessage = err.error?.message || err.message || 'Erreur inconnue';
      this.snackBar.open(`Erreur lors de la confirmation de l'abonnement: ${errorMessage}`, 'Fermer', { duration: 5000 });
      this.errorMessage = `Erreur: ${errorMessage}`;
    },
  });
}
}