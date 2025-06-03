import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

@Component({
  selector: 'app-profile-info',
  standalone: true,
  imports: [CommonModule, FormsModule, MatSnackBarModule],
  templateUrl: './profile-info.component.html',
  styles: []
})
export class ProfileInfoComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private snackBar = inject(MatSnackBar);

  user = signal({
    firstName: '',
    lastName: '',
    email: '',
    phone: ''
  });
  editForm = {
    firstName: '',
    lastName: '',
    email: '',
    phone: ''
  };
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  isFormSubmitted = false;

  ngOnInit() {
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
    this.isFormSubmitted = false; // Reset form submission state
    this.http
      .get('http://localhost:8082/parking/api/user/profile', { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.user.set({
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            email: data.email || '',
            phone: data.phone || ''
          });
          this.editForm = {
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            email: data.email || '',
            phone: data.phone || ''
          };
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur de récupération du profil: ${err.message}`);
          this.isLoading.set(false);
          if (err.status === 401) {
            this.authService.logout();
          }
        },
      });
  }

  saveProfileChanges(): void {
    this.isFormSubmitted = true;
    if (!this.editForm.firstName || !this.editForm.lastName || !this.editForm.phone) {
      this.snackBar.open('Veuillez remplir tous les champs requis', 'Fermer', { duration: 3000 });
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .put('http://localhost:8082/parking/api/user/profile', this.editForm, { headers: this.getHeaders() })
      .subscribe({
        next: (data: any) => {
          this.user.set({
            firstName: data.firstName,
            lastName: data.lastName,
            email: data.email,
            phone: data.phone
          });
          this.isLoading.set(false);
          this.snackBar.open('Profil mis à jour avec succès', 'Fermer', { duration: 3000 });
        },
        error: (err) => {
          this.errorMessage.set(`Erreur lors de la mise à jour: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }
}