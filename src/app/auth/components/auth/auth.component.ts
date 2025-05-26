import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth/auth.service';
import { CommonModule } from '@angular/common';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatSnackBarModule
  ]
})
export class AuthComponent implements OnInit {
  isSignUp = false;
  loginForm: FormGroup;
  signupForm: FormGroup;
  showLoginPassword = false;
  showSignupPassword = false;
  showSignupConfirmPassword = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private snackBar: MatSnackBar,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      rememberMe: [false] // Added rememberMe control
    });

    this.signupForm = this.fb.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', [Validators.required, Validators.pattern(/^\d{10}$/)]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });
  }

  ngOnInit(): void {
    // Load remembered email if exists
    const rememberedEmail = localStorage.getItem('rememberedEmail');
    if (rememberedEmail) {
      this.loginForm.patchValue({ email: rememberedEmail, rememberMe: true });
    }
  }

  passwordMatchValidator(group: FormGroup): { [key: string]: any } | null {
    return group.get('password')?.value === group.get('confirmPassword')?.value
      ? null
      : { mismatch: true };
  }

  toggleForm(): void {
    this.isSignUp = !this.isSignUp;
    console.log('isSignUp:', this.isSignUp); // Debug log
  }

  toggleLoginPassword(): void {
    this.showLoginPassword = !this.showLoginPassword;
  }

  toggleSignupPassword(): void {
    this.showSignupPassword = !this.showSignupPassword;
  }

  toggleSignupConfirmPassword(): void {
    this.showSignupConfirmPassword = !this.showSignupConfirmPassword;
  }

  login(): void {
    if (this.loginForm.invalid) {
      this.snackBar.open('Veuillez remplir correctement le formulaire', 'Fermer', { duration: 3000 });
      return;
    }

    const { email, password, rememberMe } = this.loginForm.value;
    
    // Handle remember me locally
    if (rememberMe) {
      localStorage.setItem('rememberedEmail', email);
    } else {
      localStorage.removeItem('rememberedEmail');
    }

    // Only send email and password to the API
    this.authService.login({ email, password }).subscribe({
      next: (response) => {
        // Success is handled in the service
        this.snackBar.open('Connexion réussie!', 'Fermer', { duration: 3000 });
      },
      error: (err) => {
        this.snackBar.open(err.error?.message || 'Erreur de connexion', 'Fermer', { duration: 3000 });
      }
    });
  }

  register(): void {
    if (this.signupForm.invalid) {
      this.snackBar.open('Veuillez corriger les erreurs du formulaire', 'Fermer', { duration: 3000 });
      return;
    }

    const { confirmPassword, ...userData } = this.signupForm.value;
    this.authService.register(userData).subscribe({
      next: (res) => {
        if (res.message?.toLowerCase().includes('success')) {
          this.snackBar.open('Inscription réussie !', 'Fermer', { duration: 3000 });
          this.isSignUp = false;
        } else {
          this.snackBar.open('Compte créé avec succès !', 'Fermer', { duration: 3000 });
        }
      },
      error: (err) => {
        this.snackBar.open(err.error?.message || 'Erreur lors de l\'inscription', 'Fermer', { duration: 3000 });
      }
    });
  }
}
