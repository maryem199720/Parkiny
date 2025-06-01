import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

@Component({
  selector: 'app-profile-password',
  standalone: true,
  imports: [CommonModule, FormsModule, MatSnackBarModule],
  templateUrl: './profile-password.component.html',
  styles: []
})
export class ProfilePasswordComponent {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private snackBar = inject(MatSnackBar);

  changePasswordForm = {
    currentPassword: '',
    newPassword: '',
    verificationCode: ''
  };
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  submitChangePassword(): void {
    if (!this.changePasswordForm.currentPassword || !this.changePasswordForm.newPassword || !this.changePasswordForm.verificationCode) {
      this.errorMessage.set('Veuillez remplir tous les champs');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .post('http://localhost:8082/parking/api/user/change-password', this.changePasswordForm, { headers: this.getHeaders() })
      .subscribe({
        next: () => {
          this.isLoading.set(false);
          this.snackBar.open('Mot de passe mis à jour avec succès', 'Fermer', { duration: 3000 });
          this.changePasswordForm = { currentPassword: '', newPassword: '', verificationCode: '' };
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.message}`);
          this.isLoading.set(false);
        },
      });
  }
}