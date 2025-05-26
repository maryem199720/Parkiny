import { Component, OnInit } from '@angular/core';
import { UserService } from '../../services/user.service';
import { ReservationService } from '../../services/Reservations/reservation.service';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { Reservation } from '../../models/reservation.model';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-user-dashboard',
  standalone: true,
  templateUrl: './user-dashboard.component.html',
  styleUrls: ['./user-dashboard.component.css'],
  imports: [ReactiveFormsModule, RouterOutlet, RouterLink]
})
export class UserDashboardComponent implements OnInit {
  profileForm!: FormGroup;
  reservations: Reservation[] = [];
  userId = 1;
  isAuthenticated = false;
  private authSubscription!: Subscription;

  constructor(
    private userService: UserService,
    private reservationService: ReservationService,
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit() {
    console.log('UserDashboardComponent initialized'); // Debug log
    this.initializeForm();
    this.isAuthenticated = this.authService.isAuthenticated();
    console.log('Initial auth state:', this.isAuthenticated); // Debug log

    // Subscribe to auth status changes
    this.authSubscription = this.authService.authStatus$.subscribe(status => {
      this.isAuthenticated = status;
      console.log('Auth status changed in UserDashboard:', status); // Debug log
      if (this.isAuthenticated) {
        this.loadUserProfile();
        this.loadUserReservations();
      } else {
        this.reservations = []; // Clear data on logout
      }
    });
  }

  ngOnDestroy(): void {
    if (this.authSubscription) {
      this.authSubscription.unsubscribe();
    }
  }

  initializeForm() {
    this.profileForm = this.fb.group({
      nom: [''],
      prenom: [''],
      email: ['', [Validators.email]],
      numPhone: [''],
      password: ['', [Validators.minLength(6)]],
      confirmPassword: ['', [Validators.minLength(6)]]
    });
  }

  loadUserProfile() {
    this.userService.getUserProfile().subscribe({
      next: (data) => {
        this.profileForm.patchValue(data);
      },
      error: (error) => {
        console.error('Error loading profile:', error);
      }
    });
  }

  loadUserReservations() {
    this.reservationService.getUserReservations(this.userId).subscribe({
      next: (reservations: Reservation[]) => {
        this.reservations = reservations;
      },
      error: (error) => {
        console.error('Error loading reservations:', error);
      }
    });
  }

  createNewReservation(reservationData: Reservation) {
    this.reservationService.createReservation(reservationData).subscribe({
      next: (response) => {
        console.log('Reservation created:', response);
        this.loadUserReservations();
      },
      error: (error) => {
        console.error('Error creating reservation:', error);
      }
    });
  }

  updateProfile() {
    if (this.profileForm.valid) {
      this.userService.updateUserProfile(this.profileForm.value).subscribe({
        next: () => {
          alert('Profile updated successfully!');
        },
        error: (error) => {
          console.error('Error updating profile:', error);
        }
      });
    } else {
      console.error('Form is invalid');
    }
  }
}