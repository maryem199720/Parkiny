import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

@Component({
  selector: 'app-profile-vehicles',
  standalone: true,
  imports: [CommonModule, FormsModule, MatSnackBarModule],
  templateUrl: './profile-vehicles.component.html',
  styles: []
})
export class ProfileVehiclesComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private snackBar = inject(MatSnackBar);

  vehicles = signal<any[]>([]);
  vehicleForm = {
    matricule: '',
    brand: '',
    model: '',
    color: ''
  };
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  brands = ['Toyota', 'Honda', 'Ford', 'Volkswagen', 'Other'];
  models = ['Civic', 'Corolla', 'Focus', 'Golf', 'Other'];
  colors = ['Rouge', 'Bleu', 'Noir', 'Blanc', 'Other'];

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
            color: ''
          };
          this.loadVehicles();
          this.snackBar.open('Véhicule ajouté avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  deleteVehicle(matricule: string): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .delete(`http://localhost:8082/parking/api/vehicle/${matricule}`, { headers: this.getHeaders() })
      .subscribe({
        next: () => {
          this.loadVehicles();
          this.snackBar.open('Véhicule supprimé avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }
}