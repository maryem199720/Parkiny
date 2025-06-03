import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

@Component({
  selector: 'app-profile-vehicles',
  standalone: true,
  imports: [CommonModule, FormsModule, MatSnackBarModule],
  templateUrl: './profile-vehicles.component.html',
  styleUrls: ['./profile-vehicles.component.css'],
})
export class ProfileVehiclesComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private snackBar = inject(MatSnackBar);

  vehicles = signal<any[]>([]);
  vehicleForm = {
    matricule: '',
    brand: '',
    customBrand: '',
    model: '',
    customModel: '',
    color: '',
    customColor: '',
    matriculeImageUrl: ''
  };
  editVehicleForm: any = null;
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  brands = ['Toyota', 'Honda', 'Ford', 'Volkswagen', 'BMW', 'Mercedes-Benz', 'Audi', 'Hyundai', 'Kia', 'Peugeot', 'Renault', 'Citroën', 'Tesla', 'Nissan', 'Chevrolet', 'Other'];
  models = ['Civic', 'Corolla', 'Focus', 'Golf', '3 Series', 'C-Class', 'A4', 'Tucson', 'Sportage', '208', 'Clio', 'C3', 'Model 3', 'Leaf', 'Camaro', 'Other'];
  colors = ['Rouge', 'Bleu', 'Noir', 'Blanc', 'Gris', 'Argent', 'Vert', 'Jaune', 'Orange', 'Marron', 'Beige', 'Violet', 'Or', 'Other'];
  selectedFile: File | null = null;

  ngOnInit() {
    this.loadVehicles();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  onFileSelected(event: any): void {
    this.selectedFile = event.target.files[0];
    if (this.selectedFile) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.vehicleForm.matriculeImageUrl = e.target.result;
      };
      reader.readAsDataURL(this.selectedFile);
    }
  }

  sendPlateImage(): void {
    if (!this.selectedFile) {
      this.errorMessage.set('Veuillez sélectionner une image de plaque');
      return;
    }

    this.isLoading.set(true);
    const formData = new FormData();
    formData.append('file', this.selectedFile);

    this.http
      .post('http://localhost:5000/api/process-plate', formData)
      .subscribe({
        next: (response: any) => {
          this.vehicleForm.matricule = response.matricule;
          this.isLoading.set(false);
          this.snackBar.open('Matricule détecté avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur lors de la détection: ${err.error?.detail || err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  loadVehicles(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.vehicles.set(data.vehicles || []);
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur de récupération des véhicules: ${err.message}`);
          this.isLoading.set(false);
          if (err.status === 401) {
            this.authService.logout();
          }
        },
      });
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

    const brand = this.vehicleForm.brand === 'Other' ? this.vehicleForm.customBrand : this.vehicleForm.brand;
    const model = this.vehicleForm.model === 'Other' ? this.vehicleForm.customModel : this.vehicleForm.model;
    const color = this.vehicleForm.color === 'Other' ? this.vehicleForm.customColor : this.vehicleForm.color;

    if (this.vehicleForm.brand === 'Other' && !this.vehicleForm.customBrand) {
      this.errorMessage.set('Veuillez spécifier la marque');
      return;
    }
    if (this.vehicleForm.model === 'Other' && !this.vehicleForm.customModel) {
      this.errorMessage.set('Veuillez spécifier le modèle');
      return;
    }
    if (this.vehicleForm.color === 'Other' && !this.vehicleForm.customColor) {
      this.errorMessage.set('Veuillez spécifier la couleur');
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);
    const user = this.authService.getCurrentUser();
    if (!user) {
      this.errorMessage.set('Utilisateur non connecté');
      this.isLoading.set(false);
      return;
    }

    const vehicleData = {
      userId: user.id,
      matricule: this.vehicleForm.matricule,
      vehicleType: 'car',
      brand: brand,
      model: model,
      color: color,
    };

    this.http
      .post('http://localhost:8082/parking/api/vehicle', vehicleData, { headers: this.getHeaders() })
      .subscribe({
        next: () => {
          this.vehicleForm = {
            matricule: '',
            brand: '',
            customBrand: '',
            model: '',
            customModel: '',
            color: '',
            customColor: '',
            matriculeImageUrl: ''
          };
          this.selectedFile = null;
          this.loadVehicles();
          this.snackBar.open('Véhicule ajouté avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.error?.message || err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  startEditVehicle(vehicle: any): void {
    this.editVehicleForm = { ...vehicle, originalMatricule: vehicle.matricule };
  }

  updateVehicle(): void {
    if (!this.editVehicleForm) return;

    const color = this.editVehicleForm.color === 'Other' ? this.editVehicleForm.customColor : this.editVehicleForm.color;
    const matricule = this.editVehicleForm.matricule;

    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.http
      .put(
        `http://localhost:8082/parking/api/user/update-vehicle/${this.editVehicleForm.id}`,
        {},
        {
          headers: this.getHeaders(),
          params: {
            matricule: matricule,
            vehicleType: this.editVehicleForm.vehicleType,
            brand: this.editVehicleForm.brand,
            model: this.editVehicleForm.model,
            color: color,
          }
        }
      )
      .subscribe({
        next: () => {
          this.editVehicleForm = null;
          this.loadVehicles();
          this.snackBar.open('Véhicule mis à jour avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.error?.message || err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  cancelEdit(): void {
    this.editVehicleForm = null;
  }

  deleteVehicle(vehicle: any): void {
    if (!confirm(`Êtes-vous sûr de vouloir supprimer le véhicule avec la matricule ${vehicle.matricule} ?`)) {
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .delete(`http://localhost:8082/parking/api/user/vehicle/${vehicle.id}`, { headers: this.getHeaders() }) // Adjusted endpoint
      .subscribe({
        next: () => {
          this.loadVehicles();
          this.snackBar.open('Véhicule supprimé avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err: HttpErrorResponse) => {
          this.errorMessage.set(`Erreur: Véhicule non trouvé ou erreur serveur (${err.status})`);
          this.isLoading.set(false);
          console.log('Delete error details:', err); // Debug log
        },
      });
  }
}