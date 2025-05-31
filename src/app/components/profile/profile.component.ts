/* profile.component.ts */
import { Component, signal, inject, TemplateRef, ViewChild, Signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MatDialog, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

interface EditProfileDialogContext {
  dialogRef: MatDialogRef<unknown>;
  data: {
    editForm: { firstName: string; lastName: string; email: string; phone: string };
    saveProfileChanges: () => void;
    errorMessage: Signal<string | null>;
    isLoading: Signal<boolean>;
  };
}

interface PasswordChangeDialogContext {
  dialogRef: MatDialogRef<unknown>;
  data: {
    user: { email: string; phone: string };
    requestPasswordReset: () => void;
    changePassword: () => void;
    isVerificationCodeSent: Signal<boolean>;
    passwordForm: { currentPassword: string; newPassword: string; verificationCode: string };
    errorMessage: Signal<string | null>;
    isLoading: Signal<boolean>;
  };
}

interface AddVehicleDialogContext {
  dialogRef: MatDialogRef<unknown>;
  data: {
    vehicleForm: {
      matricule: string;
      brand: string;
      model: string;
      color: string;
      matriculeImage: File | null;
      isMatriculeProcessed: boolean;
      imagePreview: string | null;
    };
    triggerFileInput: () => void;
    onFileSelected: (event: Event) => void;
    processMatriculeImage: () => Promise<void>;
    submitVehicle: () => void;
    onBrandChange: (event: Event) => void;
    onModelChange: (event: Event) => void;
    onColorChange: (event: Event) => void;
    brands: string[];
    models: string[];
    colors: string[];
    errorMessage: Signal<string | null>;
    isLoading: Signal<boolean>;
  };
}

interface ManualInputDialogContext {
  dialogRef: MatDialogRef<unknown>;
  data: {
    label: string;
    inputValue: string;
    callback: (value: string) => void;
    errorMessage: Signal<string | null>;
  };
}

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    MatDialogModule,
    MatSnackBarModule,
  ],
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.scss'],
})
export class ProfileComponent {
  @ViewChild('editProfileDialog') editProfileDialog!: TemplateRef<EditProfileDialogContext>;
  @ViewChild('passwordChangeDialog') passwordChangeDialog!: TemplateRef<PasswordChangeDialogContext>;
  @ViewChild('addVehicleDialog') addVehicleDialog!: TemplateRef<AddVehicleDialogContext>;
  @ViewChild('manualInputDialog') manualInputDialog!: TemplateRef<ManualInputDialogContext>;

  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private router = inject(Router);
  private dialog = inject(MatDialog);
  private snackBar = inject(MatSnackBar);

  // UI states
  user = signal({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    vehicles: [] as any[],
    subscription: { subscriptionEndDate: '', type: 'none' },
    createdAt: '',
    reservationHistory: [] as any[],
  });
  isLoading = signal(true);
  errorMessage = signal<string | null>(null);
  isReservationsExpanded = signal(false);
  isVehiclesExpanded = signal(false);
  isSubscriptionExpanded = signal(false);
  isVerificationCodeSent = signal(false);
  showSidebar = signal(false);

  // Form data
  editForm = { firstName: '', lastName: '', email: '', phone: '' };
  passwordForm = { currentPassword: '', newPassword: '', verificationCode: '' };
  vehicleForm = {
    matricule: '',
    brand: '',
    model: '',
    color: '',
    matriculeImage: null as File | null,
    isMatriculeProcessed: false,
    imagePreview: null as string | null,
  };
  manualInput = { value: '', label: '' };

  // Vehicle options
  brands = ['Toyota', 'Honda', 'Ford', 'Volkswagen', 'Other'];
  models = ['Civic', 'Corolla', 'Focus', 'Golf', 'Other'];
  colors = ['Rouge', 'Bleu', 'Noir', 'Blanc', 'Other'];

  // Reservation lists
  activeReservations = signal<any[]>([]);
  expiredReservations = signal<any[]>([]);

  constructor() {
    this.loadUserProfile();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  loadUserProfile(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.user.set({
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            email: data.email || '',
            phone: data.phone || '',
            vehicles: data.vehicles || [],
            subscription: data.subscription || { subscriptionEndDate: 'Non défini', type: 'none' },
            createdAt: data.createdAt || '',
            reservationHistory: data.reservationHistory || [],
          });
          this.editForm = {
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            email: data.email || '',
            phone: data.phone || '',
          };
          this.processReservations(data.reservationHistory || []);
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur de récupération du profil: ${err.message}`);
          this.isLoading.set(false);
          if (err.status === 401) {
            this.authService.logout();
            this.router.navigate(['/login']);
          }
        },
      });
  }

  private processReservations(reservations: any[]): void {
    const now = new Date();
    const active = [];
    const expired = [];
    for (const res of reservations) {
      const endTime = new Date(res.endTime);
      const reservation = {
        parkingSpotId: res.parkingSpotId.toString(),
        startTime: new Date(res.startTime),
        endTime,
        status: res.status,
        totalCost: res.totalCost?.toString() ?? 'N/A',
      };
      if (endTime > now && res.status === 'PENDING') {
        active.push(reservation);
      } else {
        expired.push(reservation);
      }
    }
    this.activeReservations.set(active);
    this.expiredReservations.set(expired);
  }

  saveProfileChanges(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .put('http://localhost:8082/parking/api/user/profile', this.editForm, { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.user.set({
            ...this.user(),
            firstName: data.firstName,
            lastName: data.lastName,
            email: data.email,
            phone: data.phone,
            vehicles: data.vehicles || [],
            subscription: data.subscription || { subscriptionEndDate: 'Non défini', type: 'none' },
            reservationHistory: data.reservationHistory || [],
          });
          this.processReservations(data.reservationHistory || []);
          this.isLoading.set(false);
          this.snackBar.open('Profil mis à jour avec succès', 'Fermer', { duration: 3000 });
          this.dialog.closeAll();
        },
        error: (err) => {
          this.errorMessage.set(`Erreur lors de la mise à jour: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  requestPasswordReset(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .post(
        'http://localhost:8082/parking/api/user/request-password-reset',
        { method: 'email', email: this.user().email, phone: this.user().phone },
        { headers: this.getHeaders() }
      )
      .subscribe({
        next: () => {
          this.isVerificationCodeSent.set(true);
          this.isLoading.set(false);
          this.snackBar.open('Code de vérification envoyé par email', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur lors de la demande: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  changePassword(): void {
    if (this.passwordForm.verificationCode.length !== 6 || !/^\d{6}$/.test(this.passwordForm.verificationCode)) {
      this.errorMessage.set('Le code de vérification doit être un nombre de 6 chiffres');
      return;
    }
    if (!this.passwordForm.currentPassword) {
      this.errorMessage.set('Le mot de passe actuel est requis');
      return;
    }
    if (this.passwordForm.newPassword.length < 8) {
      this.errorMessage.set('Le nouveau mot de passe doit contenir au moins 8 caractères');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .post(
        'http://localhost:8082/parking/api/user/change-password',
        {
          currentPassword: this.passwordForm.currentPassword,
          newPassword: this.passwordForm.newPassword,
          verificationCode: this.passwordForm.verificationCode,
        },
        { headers: this.getHeaders() }
      )
      .subscribe({
        next: () => {
          this.isVerificationCodeSent.set(false);
          this.passwordForm = { currentPassword: '', newPassword: '', verificationCode: '' };
          this.isLoading.set(false);
          this.snackBar.open('Mot de passe mis à jour avec succès', 'Fermer', { duration: 3000 });
          this.dialog.closeAll();
        },
        error: (err) => {
          this.errorMessage.set(`Erreur lors de la mise à jour: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  triggerFileInput(): void {
    const fileInput = document.querySelector('#fileInput') as HTMLInputElement;
    if (fileInput) fileInput.click();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      this.vehicleForm.matriculeImage = input.files[0];
      const reader = new FileReader();
      reader.onload = () => (this.vehicleForm.imagePreview = reader.result as string);
      reader.readAsDataURL(input.files[0]);
    }
  }

  async processMatriculeImage(): Promise<void> {
    if (!this.vehicleForm.matriculeImage) return;
    this.isLoading.set(true);
    this.errorMessage.set(null);
    const formData = new FormData();
    formData.append('image', this.vehicleForm.matriculeImage, 'car.jpg');
    try {
      const response = await this.http
        .post('http://localhost:5000/api/process-matricule', formData, {
          headers: new HttpHeaders({ Authorization: `Bearer ${this.authService.getToken()}` }),
        })
        .toPromise();
      this.vehicleForm.matricule = (response as any).matricule;
      this.vehicleForm.isMatriculeProcessed = true;
      this.isLoading.set(false);
    } catch (err: any) {
      this.errorMessage.set(`Erreur lors du traitement de l'image: ${err.message}`);
      this.isLoading.set(false);
    }
  }

  submitVehicle(): void {
    if (
      !this.vehicleForm.matricule ||
      !this.vehicleForm.brand ||
      !this.vehicleForm.model ||
      !this.vehicleForm.color
    ) {
      this.errorMessage.set('Veuillez remplir tous les champs');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set(null);
    const vehicleData = {
      matricule: this.vehicleForm.matricule,
      vehicleType: 'car',
      brand: this.vehicleForm.brand,
      model: this.vehicleForm.model,
      color: this.vehicleForm.color,
    };
    this.http
      .post('http://localhost:8082/parking/api/vehicle', vehicleData, { headers: this.getHeaders() })
      .subscribe({
        next: () => {
          this.vehicleForm = {
            matricule: '',
            brand: '',
            model: '',
            color: '',
            matriculeImage: null,
            isMatriculeProcessed: false,
            imagePreview: null,
          };
          this.loadUserProfile();
          this.snackBar.open('Véhicule ajouté avec succès', 'Fermer', { duration: 3000 });
          this.dialog.closeAll();
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  onBrandChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === 'Other') {
      this.vehicleForm.brand = '';
      this.openManualInputDialog('Marque', (value: string) => (this.vehicleForm.brand = value));
    } else {
      this.vehicleForm.brand = value;
    }
  }

  onModelChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === 'Other') {
      this.vehicleForm.model = '';
      this.openManualInputDialog('Modèle', (value: string) => (this.vehicleForm.model = value));
    } else {
      this.vehicleForm.model = value;
    }
  }

  onColorChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === 'Other') {
      this.vehicleForm.color = '';
      this.openManualInputDialog('Couleur', (value: string) => (this.vehicleForm.color = value));
    } else {
      this.vehicleForm.color = value;
    }
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  openEditProfileDialog(): void {
    this.dialog.open(this.editProfileDialog, {
      width: '500px',
      panelClass: 'custom-dialog-container',
      data: {
        editForm: { ...this.editForm },
        saveProfileChanges: () => this.saveProfileChanges(),
        errorMessage: this.errorMessage,
        isLoading: this.isLoading,
      },
    });
  }

  openPasswordChangeDialog(): void {
    this.dialog.open(this.passwordChangeDialog, {
      width: '500px',
      panelClass: 'custom-dialog-container',
      data: {
        user: this.user(),
        requestPasswordReset: () => this.requestPasswordReset(),
        changePassword: () => this.changePassword(),
        isVerificationCodeSent: this.isVerificationCodeSent,
        passwordForm: this.passwordForm,
        errorMessage: this.errorMessage,
        isLoading: this.isLoading,
      },
    });
  }

  openAddVehicleDialog(): void {
    this.dialog.open(this.addVehicleDialog, {
      width: '500px',
      panelClass: 'custom-dialog-container',
      data: {
        vehicleForm: this.vehicleForm,
        triggerFileInput: () => this.triggerFileInput(),
        onFileSelected: (event: Event) => this.onFileSelected(event),
        processMatriculeImage: () => this.processMatriculeImage(),
        submitVehicle: () => this.submitVehicle(),
        onBrandChange: (event: Event) => this.onBrandChange(event),
        onModelChange: (event: Event) => this.onModelChange(event),
        onColorChange: (event: Event) => this.onColorChange(event),
        brands: this.brands,
        models: this.models,
        colors: this.colors,
        errorMessage: this.errorMessage,
        isLoading: this.isLoading,
      },
    });
  }

  openManualInputDialog(label: string, callback: (value: string) => void): void {
    this.manualInput.value = '';
    this.manualInput.label = label;
    const dialogRef = this.dialog.open(this.manualInputDialog, {
      width: '300px',
      panelClass: 'custom-dialog-container',
      data: {
        label,
        inputValue: this.manualInput.value,
        callback,
        errorMessage: this.errorMessage,
      },
    });
    dialogRef.afterClosed().subscribe(() => {
      this.manualInput.value = '';
    });
  }

  toggleSection(section: 'reservations' | 'vehicles' | 'subscription'): void {
    if (section === 'reservations') {
      this.isReservationsExpanded.set(!this.isReservationsExpanded());
    } else if (section === 'vehicles') {
      this.isVehiclesExpanded.set(!this.isVehiclesExpanded());
    } else if (section === 'subscription') {
      this.isSubscriptionExpanded.set(!this.isSubscriptionExpanded());
    }
  }

  navigateTo(path: string): void {
    this.router.navigate([path]);
  }

  toggleSidebar(): void {
    this.showSidebar.set(!this.showSidebar());
  }
}