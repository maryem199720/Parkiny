import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../auth/services/auth/auth.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.css']
})
export class NavbarComponent {
 
  constructor(
    public authService: AuthService,
    private router: Router
  ) {}

  navigateTo(route: string): void {
    // Only navigate if user is authenticated for protected routes
    if (route.includes('/profile') || route.includes('/reservations') || route.includes('/abonnements')) {
      if (!this.authService.isAuthenticated()) {
        this.router.navigate(['/auth']);
        return;
      }
    }
    
    this.router.navigate([route])
      .then(success => {
        if (!success) {
          console.error('Navigation failed to:', route);
          this.router.navigate(['/error']);
        }
      });
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/']);
  }
}
