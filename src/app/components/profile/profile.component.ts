import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MAT_DIALOG_DATA, MatDialog, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, MatDialogModule, MatSnackBarModule],
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.scss']
})
export class ProfileComponent {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private router = inject(Router);
  private dialog = inject(MatDialog);
  private snackBar = inject(MatSnackBar);

  // User data
  user = signal({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    vehicles: [] as any[],
    subscription: { subscriptionEndDate: '' },
    createdAt: '',
    reservationHistory: [] as any[]
  });

  // UI states
  isLoading = signal(true);
  errorMessage = signal<string | null>(null);
  isReservationsExpanded = signal(true);
  isVehiclesExpanded = signal(false);
  isSubscriptionExpanded = signal(false);
  isVerificationCodeSent = signal(false);
  isActiveReservations = signal(true);

  // Form data
  editForm = {
    firstName: '',
    lastName: '',
    email: '',
    phone: ''
  };
  passwordForm = {
    currentPassword: '',
    newPassword: '',
    verificationCode: ''
  };
  vehicleForm = {
    matricule: '',
    brand: '',
    model: '',
    color: '',
    matriculeImage: null as File | null,
    isMatriculeProcessed: false
  };

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
      'Authorization': `Bearer ${token}`
    });
  }

  loadUserProfile(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.http.get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() }).subscribe({
      next: (data: any) => {
        this.user.set({
          firstName: data.firstName || '',
          lastName: data.lastName || '',
          email: data.email || '',
          phone: data.phone || '',
          vehicles: data.vehicles || [],
          subscription: data.subscription || { subscriptionEndDate: 'Non défini' },
          createdAt: data.createdAt || '',
          reservationHistory: data.reservationHistory || []
        });
        this.editForm = {
          firstName: data.firstName || '',
          lastName: data.lastName || '',
          email: data.email || '',
          phone: data.phone || ''
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
      }
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
        endTime: endTime,
        status: res.status,
        totalCost: res.totalCost?.toString() ?? 'N/A'
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

    this.http.put('http://localhost:8082/parking/api/user/profile', this.editForm, { headers: this.getHeaders() }).subscribe({
      next: (data: any) => {
        this.user.set({
          ...this.user(),
          firstName: data.firstName,
          lastName: data.lastName,
          email: data.email,
          phone: data.phone,
          vehicles: data.vehicles || [],
          subscription: data.subscription || { subscriptionEndDate: 'Non défini' },
          reservationHistory: data.reservationHistory || []
        });
        this.processReservations(data.reservationHistory || []);
        this.isLoading.set(false);
        this.snackBar.open('Profil mis à jour avec succès', 'Fermer', { duration: 3000 });
        this.dialog.closeAll();
      },
      error: (err) => {
        this.errorMessage.set(`Erreur lors de la mise à jour: ${err.message}`);
        this.isLoading.set(false);
      }
    });
  }

  requestPasswordReset(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.http.post('http://localhost:8082/parking/api/user/request-password-reset', {
      method: 'email',
      email: this.user().email,
      phone: this.user().phone
    }, { headers: this.getHeaders() }).subscribe({
      next: () => {
        this.isVerificationCodeSent.set(true);
        this.isLoading.set(false);
        this.snackBar.open('Code de vérification envoyé par email', 'Fermer', { duration: 3000 });
      },
      error: (err) => {
        this.errorMessage.set(`Erreur lors de la demande: ${err.message}`);
        this.isLoading.set(false);
      }
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

    this.http.post('http://localhost:8082/parking/api/user/change-password', {
      currentPassword: this.passwordForm.currentPassword,
      newPassword: this.passwordForm.newPassword,
      verificationCode: this.passwordForm.verificationCode
    }, { headers: this.getHeaders() }).subscribe({
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
      }
    });
  }

  async processMatriculeImage(): Promise<void> {
    if (!this.vehicleForm.matriculeImage) return;

    this.isLoading.set(true);
    this.errorMessage.set(null);

    const formData = new FormData();
    formData.append('image', this.vehicleForm.matriculeImage, 'car.jpg');

    try {
      const response = await this.http.post('http://localhost:5000/api/process-matricule', formData, {
        headers: new HttpHeaders({ 'Authorization': `Bearer ${this.authService.getToken()}` })
      }).toPromise();
      this.vehicleForm.matricule = (response as any).matricule;
      this.vehicleForm.isMatriculeProcessed = true;
      this.isLoading.set(false);
    } catch (err: any) {
      this.errorMessage.set(`Erreur lors du traitement de l'image: ${err.message}`);
      this.isLoading.set(false);
    }
  }

  submitVehicle(): void {
    if (!this.vehicleForm.matricule || !this.vehicleForm.brand || !this.vehicleForm.model || !this.vehicleForm.color) {
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
      color: this.vehicleForm.color
    };

    this.http.post('http://localhost:8082/parking/api/vehicle', vehicleData, { headers: this.getHeaders() }).subscribe({
      next: () => {
        this.vehicleForm = {
          matricule: '',
          brand: '',
          model: '',
          color: '',
          matriculeImage: null,
          isMatriculeProcessed: false
        };
        this.loadUserProfile();
        this.snackBar.open('Véhicule ajouté avec succès', 'Fermer', { duration: 3000 });
        this.dialog.closeAll();
      },
      error: (err) => {
        this.errorMessage.set(`Erreur: ${err.message}`);
        this.isLoading.set(false);
      }
    });
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  openEditProfileDialog(): void {
    this.dialog.open(EditProfileDialogComponent, {
      data: {
        editForm: { ...this.editForm },
        saveProfileChanges: () => this.saveProfileChanges(),
        errorMessage: this.errorMessage,
        isLoading: this.isLoading
      },
      width: '500px'
    });
  }

  openPasswordChangeDialog(): void {
    this.dialog.open(PasswordChangeDialogComponent, {
      data: {
        user: this.user(),
        requestPasswordReset: () => this.requestPasswordReset(),
        changePassword: () => this.changePassword(),
        isVerificationCodeSent: this.isVerificationCodeSent,
        passwordForm: this.passwordForm,
        errorMessage: this.errorMessage,
        isLoading: this.isLoading
      },
      width: '500px'
    });
  }

  openAddVehicleDialog(): void {
    this.dialog.open(AddVehicleDialogComponent, {
      data: {
        vehicleForm: this.vehicleForm,
        processMatriculeImage: () => this.processMatriculeImage(),
        submitVehicle: () => this.submitVehicle(),
        errorMessage: this.errorMessage,
        isLoading: this.isLoading
      },
      width: '500px'
    });
  }

  toggleReservationsTab(active: boolean): void {
    this.isActiveReservations.set(active);
  }

  navigateTo(path: string): void {
    this.router.navigate([path]);
  }
}

@Component({
  selector: 'app-edit-profile-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, MatDialogModule],
  template: `
    <h2 mat-dialog-title class="text-2xl font-bold font-poppins">Modifier les Informations Personnelles</h2>
    <mat-dialog-content class="space-y-4">
      <input
        type="text"
        [(ngModel)]="data.editForm.firstName"
        placeholder="Prénom"
        class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
      />
      <input
        type="text"
        [(ngModel)]="data.editForm.lastName"
        placeholder="Nom"
        class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
      />
      <input
        type="email"
        [(ngModel)]="data.editForm.email"
        placeholder="Email"
        class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
      />
      <input
        type="tel"
        [(ngModel)]="data.editForm.phone"
        placeholder="Téléphone"
        class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
      />
      @if (data.errorMessage()) {
        <p class="text-error font-poppins">{{ data.errorMessage() }}</p>
      }
      @if (data.isLoading()) {
        <div class="flex justify-center">
          <div class="w-6 h-6 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      } @else {
        <button
          (click)="data.saveProfileChanges()"
          class="w-full bg-primary text-gray-900 px-4 py-3 rounded-button hover:bg-opacity-90 transition-colors"
        >
          Enregistrer
        </button>
      }
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button (click)="dialogRef.close()" class="text-primary font-poppins">Annuler</button>
    </mat-dialog-actions>
  `
})
export class EditProfileDialogComponent {
  dialogRef = inject(MatDialogRef<EditProfileDialogComponent>);
  data = inject(MAT_DIALOG_DATA);
}

@Component({
  selector: 'app-password-change-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, MatDialogModule],
  template: `
    <h2 mat-dialog-title class="text-2xl font-bold font-poppins">Changer le Mot de Passe</h2>
    <mat-dialog-content class="space-y-4">
      <p class="font-poppins text-base font-medium">Étape 1 : Demander un code de vérification</p>
      <p class="font-poppins text-sm text-gray-500">Un code sera envoyé à votre email: {{ data.user.email }}</p>
      <button
        (click)="data.requestPasswordReset()"
        class="w-full bg-primary text-gray-900 px-4 py-3 rounded-button hover:bg-opacity-90 transition-colors"
        [disabled]="data.isLoading()"
      >
        Demander le code
      </button>
      @if (data.isVerificationCodeSent()) {
        <p class="font-poppins text-base font-medium">Étape 2 : Entrer les détails du mot de passe</p>
        <input
          type="text"
          [(ngModel)]="data.passwordForm.verificationCode"
          placeholder="Code de vérification (6 chiffres)"
          class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
          maxlength="6"
        />
        <input
          type="password"
          [(ngModel)]="data.passwordForm.currentPassword"
          placeholder="Mot de passe actuel"
          class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
        />
        <input
          type="password"
          [(ngModel)]="data.passwordForm.newPassword"
          placeholder="Nouveau mot de passe"
          class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary focus:border-primary"
        />
        <button
          (click)="data.changePassword()"
          class="w-full bg-primary text-gray-900 px-4 py-3 rounded-button hover:bg-opacity-90 transition-colors"
          [disabled]="data.isLoading()"
        >
          Confirmer le changement
        </button>
      }
      @if (data.errorMessage()) {
        <p class="text-error font-poppins">{{ data.errorMessage() }}</p>
      }
      @if (data.isLoading()) {
        <div class="flex justify-center">
          <div class="w-6 h-6 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      }
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button (click)="dialogRef.close()" class="text-primary font-poppins">Annuler</button>
    </mat-dialog-actions>
  `
})
export class PasswordChangeDialogComponent {
  dialogRef = inject(MatDialogRef<PasswordChangeDialogComponent>);
  data = inject(MAT_DIALOG_DATA);
}

@Component({
  selector: 'app-add-vehicle-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, MatDialogModule],
  template: `
    <h2 mat-dialog-title class="text-2xl font-bold font-poppins">Ajouter un Véhicule</h2>
    <mat-dialog-content class="space-y-4">
      @if (!data.vehicleForm.isMatriculeProcessed) {
        <div
          (click)="triggerFileInput()"
          class="h-36 bg-gray-100 rounded-lg border border-gray-300 flex items-center justify-center cursor-pointer relative"
        >
          @if (!data.vehicleForm.matriculeImage) {
            <div class="text-center">
              <i class="ri-camera-line text-2xl text-gray-500"></i>
              <p class="font-poppins text-gray-500">Uploader l'image de la matricule</p>
            </div>
          } @else {
            <img [src]="imagePreview" class="h-full w-full object-cover rounded-lg" />
            <button
              (click)="data.processMatriculeImage(); $event.stopPropagation()"
              class="absolute bottom-2 bg-primary text-gray-900 px-4 py-2 rounded-button hover:bg-opacity-90"
              [disabled]="data.isLoading()"
            >
              Envoyer
            </button>
          }
        </div>
        <input
          type="file"
          #fileInput
          (change)="onFileSelected($event)"
          accept="image/*"
          class="hidden"
        />
        <input
          type="text"
          [(ngModel)]="data.vehicleForm.matricule"
          placeholder="Matricule (sera rempli après envoi)"
          class="w-full px-4 py-2 border border-gray-300 rounded bg-gray-100"
          disabled
        />
        <button
          (click)="data.vehicleForm.isMatriculeProcessed = true"
          class="w-full bg-primary text-gray-900 px-4 py-3 rounded-button hover:bg-opacity-90"
          [disabled]="!data.vehicleForm.matricule || data.isLoading()"
        >
          Passer à l'étape suivante
        </button>
      } @else {
        <input
          type="text"
          [(ngModel)]="data.vehicleForm.matricule"
          placeholder="Matricule"
          class="w-full px-4 py-2 border border-gray-300 rounded bg-gray-100"
          disabled
        />
        <select
          [(ngModel)]="data.vehicleForm.brand"
          class="w-full px-4 py-2 border border-gray-300 rounded"
          (change)="onBrandChange($event)"
        >
          <option value="" disabled selected>Marque</option>
          <option *ngFor="let brand of brands" [value]="brand">{{ brand }}</option>
        </select>
        <select
          [(ngModel)]="data.vehicleForm.model"
          class="w-full px-4 py-2 border border-gray-300 rounded"
          (change)="onModelChange($event)"
        >
          <option value="" disabled selected>Modèle</option>
          <option *ngFor="let model of models" [value]="model">{{ model }}</option>
        </select>
        <select
          [(ngModel)]="data.vehicleForm.color"
          class="w-full px-4 py-2 border border-gray-300 rounded"
          (change)="onColorChange($event)"
        >
          <option value="" disabled selected>Couleur</option>
          <option *ngFor="let color of colors" [value]="color">{{ color }}</option>
        </select>
        <button
          (click)="data.submitVehicle()"
          class="w-full bg-primary text-gray-900 px-4 py-3 rounded-button hover:bg-opacity-90"
          [disabled]="data.isLoading()"
        >
          Ajouter
        </button>
      }
      @if (data.errorMessage()) {
        <p class="text-error font-poppins">{{ data.errorMessage() }}</p>
      }
      @if (data.isLoading()) {
        <div class="flex justify-center">
          <div class="w-6 h-6 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      }
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button (click)="dialogRef.close()" class="text-primary font-poppins">Annuler</button>
    </mat-dialog-actions>
  `
})
export class AddVehicleDialogComponent {
  dialogRef = inject(MatDialogRef<AddVehicleDialogComponent>);
  data = inject(MAT_DIALOG_DATA);
  imagePreview: string | null = null;

  brands = ['Toyota', 'Honda', 'Ford', 'Volkswagen', 'Other'];
  models = ['Civic', 'Corolla', 'Focus', 'Golf', 'Other'];
  colors = ['Rouge', 'Bleu', 'Noir', 'Blanc', 'Other'];
  dialog: any;

  triggerFileInput(): void {
    const fileInput = document.querySelector('#fileInput') as HTMLInputElement;
    fileInput.click();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      this.data.vehicleForm.matriculeImage = input.files[0];
      const reader = new FileReader();
      reader.onload = () => (this.imagePreview = reader.result as string);
      reader.readAsDataURL(input.files[0]);
    }
  }

  onBrandChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === 'Other') {
      this.data.vehicleForm.brand = '';
      this.openManualInputDialog('Marque', (value: string) => (this.data.vehicleForm.brand = value));
    }
  }

  onModelChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === 'Other') {
      this.data.vehicleForm.model = '';
      this.openManualInputDialog('Modèle', (value: string) => (this.data.vehicleForm.model = value));
    }
  }

  onColorChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === 'Other') {
      this.data.vehicleForm.color = '';
      this.openManualInputDialog('Couleur', (value: string) => (this.data.vehicleForm.color = value));
    }
  }

  openManualInputDialog(label: string, callback: (value: string) => void): void {
    this.dialog.open(ManualInputDialogComponent, {
      data: { label, callback },
      width: '300px'
    });
  }
}

@Component({
  selector: 'app-manual-input-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, MatDialogModule],
  template: `
    <h2 mat-dialog-title class="text-2xl font-bold font-poppins">Entrer {{ data.label }} manuellement</h2>
    <mat-dialog-content>
      <input
        type="text"
        [(ngModel)]="inputValue"
        [placeholder]="data.label"
        class="w-full px-4 py-2 border border-gray-300 rounded focus:ring-2 focus:ring-primary"
      />
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button (click)="dialogRef.close()" class="text-primary font-poppins">Annuler</button>
      <button mat-button (click)="data.callback(inputValue); dialogRef.close()" class="text-primary font-poppins">OK</button>
    </mat-dialog-actions>
  `
})
export class ManualInputDialogComponent {
  dialogRef = inject(MatDialogRef<ManualInputDialogComponent>);
  data = inject(MAT_DIALOG_DATA);
  inputValue = '';
}