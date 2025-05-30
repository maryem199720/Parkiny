import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Router, RouterLink } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { StorageService } from 'src/app/auth/services/storage/storage.service';
import { SubscriptionService } from 'src/app/services/subscription.service';

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

interface ActiveSubscription {
  id: number;
  userId: number;
  subscriptionType: string;
  billingCycle: string;
  status: string;
  remainingPlaces: number;
}

@Component({
  selector: 'app-subscription',
  templateUrl: './subscription.component.html',
  styleUrls: ['./subscription.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatTooltipModule,
    RouterLink,
  ],
})
export class SubscriptionComponent implements OnInit {
  currentStep = 1;
  subscriptionForm: FormGroup;
  plans = new BehaviorSubject<SubscriptionPlan[]>([]);
  selectedPlan = new BehaviorSubject<number | null>(null);
  billingType = new BehaviorSubject<'monthly' | 'annual'>('monthly');
  paymentMethod = new BehaviorSubject<'card' | 'd17'>('card');
  vehicles = new BehaviorSubject<Vehicle[]>([]);
  isLoading = false;
  sessionId: string | null = null;
  subscriptionConfirmationCode: string | null = null;
  subscriptionConfirmed = false;
  hasActiveSubscription = false; // New flag to track if user has an active subscription
  activeSubscription: ActiveSubscription | null = null; // Store active subscription details
  private lastButtonPressTime: number | null = null;

  constructor(
    private fb: FormBuilder,
    private subscriptionService: SubscriptionService,
    private storageService: StorageService,
    private snackBar: MatSnackBar,
    private router: Router
  ) {
    this.subscriptionForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      cardName: [''],
      cardNumber: [''],
      cardExpiry: [''],
      cardCvv: [''],
      subscriptionConfirmationCode: ['']
    });
    this.updatePaymentValidators();
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

    // Check for active subscription
    this.subscriptionService.getActiveSubscription(userId).subscribe({
      next: (subscription) => {
        this.hasActiveSubscription = true;
        this.activeSubscription = subscription;
      },
      error: (err) => {
        if (err.status === 404) {
          // No active subscription found, which is fine
          this.hasActiveSubscription = false;
        } else {
          this.snackBar.open('Erreur lors de la vérification de votre abonnement actif.', 'Fermer', { duration: 5000 });
          console.error('Error checking active subscription:', err);
        }
      },
      complete: () => {
        // Load plans regardless of subscription status
        this.loadPlans();
      }
    });

    this.subscriptionService.getUserProfile().subscribe({
      next: (user) => {
        this.subscriptionForm.patchValue({
          email: user.email || ''
        });
        this.vehicles.next(user.vehicles || []);
        if (user.vehicles && user.vehicles.length > 0) {
          this.subscriptionForm.get('vehicleId')?.setValue(user.vehicles[0].id);
        } else {
          this.snackBar.open('Aucun véhicule trouvé. Veuillez en ajouter un dans votre profil.', 'Fermer', { duration: 5000 });
        }
      },
      error: (err) => {
        this.snackBar.open('Impossible de charger le profil. Veuillez entrer les informations manuellement.', 'Fermer', { duration: 5000 });
      }
    });
  }

  loadPlans(): void {
    this.subscriptionService.getSubscriptionPlans().subscribe({
      next: (plans) => {
        const processedPlans = plans.map(plan => ({
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
            ...(plan.hasValetService ? ['Service de voiturier inclus'] : [])
          ],
          excludedFeatures: [
            ...(plan.hasPremiumSpots ? [] : ['Places premium']),
            ...(plan.hasValetService ? [] : ['Service de voiturier'])
          ],
          isPopular: plan.isPopular
        }));
        this.plans.next(processedPlans);
        this.selectedPlan.next(processedPlans.find(p => p.type === 'Premium')?.id || processedPlans[0]?.id || null);
        this.isLoading = false;
      },
      error: (err) => {
        this.isLoading = false;
        this.snackBar.open('Erreur lors du chargement des forfaits.', 'Fermer', { duration: 5000 });
        console.error('Plan fetch error:', err);
      }
    });
  }

  updatePaymentValidators(method: 'card' | 'd17' = this.paymentMethod.value): void {
    const cardControls = ['cardName', 'cardNumber', 'cardExpiry', 'cardCvv'];
    cardControls.forEach(control => {
      const validators = method === 'card' ? [Validators.required] : [];
      if (control === 'cardNumber') validators.push(Validators.pattern(/^\d{16}$/));
      if (control === 'cardExpiry') validators.push(Validators.pattern(/^(0[1-9]|1[0-2])\/\d{2}$/));
      if (control === 'cardCvv') validators.push(Validators.pattern(/^\d{3}$/));
      this.subscriptionForm.get(control)?.setValidators(validators);
      this.subscriptionForm.get(control)?.updateValueAndValidity({ emitEvent: false });
      if (method === 'd17') {
        this.subscriptionForm.get(control)?.setValue('');
      }
    });
    this.subscriptionForm.get('subscriptionConfirmationCode')?.setValidators([]);
    this.subscriptionForm.updateValueAndValidity();
  }

  toggleBillingType(): void {
    this.billingType.next(this.billingType.value === 'monthly' ? 'annual' : 'monthly');
  }

  selectPlan(planId: number): void {
    this.selectedPlan.next(planId);
  }

  selectPaymentMethod(method: 'card' | 'd17'): void {
    this.paymentMethod.next(method);
  }

  calculatePrice(monthlyPrice: number): number {
    return this.billingType.value === 'annual' ? Math.round(monthlyPrice * 12 * 0.8) : monthlyPrice;
  }

  getSelectedPlanPrice(): number {
    const plan = this.plans.value.find(p => p.id === this.selectedPlan.value);
    return plan ? this.calculatePrice(plan.monthlyPrice) : 0;
  }

  canPressButton(): boolean {
    const now = Date.now();
    if (!this.lastButtonPressTime || (now - this.lastButtonPressTime) > 2000) {
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
        if (this.vehicles.value.length === 0) {
          this.router.navigate(['/profile']);
        }
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
    }
  }

  reset(): void {
    this.currentStep = 1;
    this.selectedPlan.next(this.plans.value.find(p => p.type === 'Premium')?.id || this.plans.value[0]?.id || null);
    this.billingType.next('monthly');
    this.paymentMethod.next('card');
    this.subscriptionForm.reset({ email: this.subscriptionForm.get('email')?.value });
    this.sessionId = null;
    this.subscriptionConfirmationCode = null;
    this.subscriptionConfirmed = false;
    this.isLoading = false;
  }

  initiateSubscription(): void {
    if (this.subscriptionForm.invalid) {
      this.subscriptionForm.markAllAsTouched();
      this.snackBar.open('Veuillez compléter tous les champs obligatoires.', 'Fermer', { duration: 5000 });
      return;
    }

    this.isLoading = true;
    const plan = this.plans.value.find(p => p.id === this.selectedPlan.value);
    if (!plan) {
      this.snackBar.open('Veuillez sélectionner un forfait.', 'Fermer', { duration: 5000 });
      this.isLoading = false;
      return;
    }

    const billingCycle = this.billingType.value;
    const subscriptionType = plan.type;
    const amount = this.calculatePrice(plan.monthlyPrice);
    const paymentMethod = this.paymentMethod.value;
    const email = this.subscriptionForm.get('email')?.value;

    const cardDetails = paymentMethod === 'card' ? {
      cardNumber: this.subscriptionForm.get('cardNumber')?.value,
      expiryDate: this.subscriptionForm.get('cardExpiry')?.value,
      cvv: this.subscriptionForm.get('cardCvv')?.value,
      cardName: this.subscriptionForm.get('cardName')?.value
    } : undefined;

    this.subscriptionService.subscribe(subscriptionType, billingCycle, amount, paymentMethod, email, cardDetails).subscribe({
      next: (response) => {
        this.isLoading = false;
        this.sessionId = response.session_id || null;
        this.subscriptionConfirmationCode = response.paymentVerificationCode || null;
        console.log('Session ID:', this.sessionId, 'Confirmation Code:', this.subscriptionConfirmationCode);
        this.currentStep = 3;
        this.subscriptionForm.get('subscriptionConfirmationCode')?.setValidators([Validators.required]);
        this.subscriptionForm.get('subscriptionConfirmationCode')?.updateValueAndValidity();
        this.snackBar.open('Paiement initié. Veuillez vérifier votre email pour le code de confirmation.', 'OK', { duration: 5000 });
        if (this.subscriptionConfirmationCode) {
          this.snackBar.open(`Code de confirmation (test) : ${this.subscriptionConfirmationCode}`, 'OK', { duration: 10000 });
        }
      },
      error: (err) => {
        this.isLoading = false;
        console.error('Full error:', err);
        const errorMessage = err.error?.message || err.message || 'Erreur inconnue';
        const message = err.status === 401 ? 'Session expirée. Veuillez vous reconnecter.' : `Erreur lors de la souscription : ${errorMessage}`;
        this.snackBar.open(message, 'Fermer', { duration: 5000 });
        if (err.status === 401) {
          this.storageService.logout();
          this.router.navigate(['/login']);
        }
      }
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
    this.subscriptionService.confirmSubscription(this.sessionId, subscriptionConfirmationCode).subscribe({
      next: () => {
        this.isLoading = false;
        this.subscriptionConfirmed = true;
        this.snackBar.open('Abonnement confirmé avec succès !', 'OK', { duration: 5000 });
      },
      error: (err) => {
        this.isLoading = false;
        const errorMessage = err.error?.message || err.message || 'Erreur inconnue';
        this.snackBar.open(`Erreur lors de la confirmation de l’abonnement : ${errorMessage}`, 'Fermer', { duration: 5000 });
      }
    });
  }
}