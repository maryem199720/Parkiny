import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, FormsModule, MatSnackBarModule, RouterLink],
  templateUrl: './forgot-password.component.html',
  styleUrls: ['./forgot-password.component.css'],
  styles: [`
    :host {
      display: block;
    }
  `]
})
export class ForgotPasswordComponent implements OnInit {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private snackBar = inject(MatSnackBar);
  private router = inject(Router);

  forgotPasswordForm = {
    email: '',
    newPassword: '',
    repeatPassword: '',
    verificationCode: ''
  };

  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  isFormSubmitted = signal(false);
  isVerificationStep = signal(false);

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  ngOnInit(): void {
    this.resetForm(); // Reset form state on component initialization
  }

  // Step 1: Request Password Reset
  requestPasswordReset(): void {
    this.isFormSubmitted.set(true);
    if (!this.forgotPasswordForm.email) {
      this.errorMessage.set('Email requis');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .post<{ message: string }>(
        'http://localhost:8082/parking/api/user/request-password-reset',
        { method: 'email', email: this.forgotPasswordForm.email, phone: null },
        { headers: this.getHeaders() }
      )
      .subscribe({
        next: (response) => {
          this.isLoading.set(false);
          this.snackBar.open('Code de vérification envoyé par email', 'Fermer', { duration: 3000 });
          this.isVerificationStep.set(true);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.error?.message || err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  // Step 2: Reset Password
  resetPassword(): void {
    this.isFormSubmitted.set(true);
    if (
      !this.forgotPasswordForm.newPassword ||
      !this.forgotPasswordForm.repeatPassword ||
      !this.forgotPasswordForm.verificationCode
    ) {
      this.errorMessage.set('Veuillez remplir tous les champs');
      return;
    }
    if (this.forgotPasswordForm.newPassword !== this.forgotPasswordForm.repeatPassword) {
      this.errorMessage.set('Les mots de passe ne correspondent pas');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.http
      .post<{ message: string }>(
        'http://localhost:8082/parking/api/user/change-password',
        {
          currentPassword: null,
          newPassword: this.forgotPasswordForm.newPassword,
          verificationCode: this.forgotPasswordForm.verificationCode
        },
        { headers: this.getHeaders() }
      )
      .subscribe({
        next: (response) => {
          this.isLoading.set(false);
          this.snackBar.open('Mot de passe réinitialisé avec succès', 'Fermer', { duration: 3000 });
          this.resetForm();
          this.router.navigate(['/dashboard/profile/password']);
        },
        error: (err) => {
          this.errorMessage.set(`Erreur: ${err.error?.message || err.message}`);
          this.isLoading.set(false);
        },
      });
  }

  // Go back to Step 1
  goBack(): void {
    this.isVerificationStep.set(false);
    this.forgotPasswordForm.newPassword = '';
    this.forgotPasswordForm.repeatPassword = '';
    this.forgotPasswordForm.verificationCode = '';
    this.errorMessage.set(null);
    this.isFormSubmitted.set(false);
  }

  // Reset the form
  resetForm(): void {
    this.forgotPasswordForm = { email: '', newPassword: '', repeatPassword: '', verificationCode: '' };
    this.isVerificationStep.set(false);
    this.isFormSubmitted.set(false);
    this.errorMessage.set(null);
  }
}