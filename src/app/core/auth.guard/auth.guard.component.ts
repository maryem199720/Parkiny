import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private authService: AuthService, private router: Router) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    const isPublic = route.data['public'] || false;
    console.log('AuthGuard: Checking route:', state.url, 'Public:', isPublic); // Debug log

    if (isPublic) {
      console.log('AuthGuard: Allowing public route'); // Debug log
      return true;
    }

    const isAuth = this.authService.isAuthenticated();
    const user = this.authService.getUser();

    console.log('AuthGuard: Is authenticated:', isAuth, 'User:', user); // Debug log

    if (!isAuth || !user) {
      console.log('AuthGuard: User not authenticated, redirecting to /auth'); // Debug log
      this.router.navigate(['/auth'], { queryParams: { returnUrl: state.url } });
      return false;
    }

    const requiredRole = route.data['role'];
    const userRole = user.role === 'ADMIN' ? 'ROLE_ADMIN' : 'ROLE_USER'; // Map to expected role format
    if (requiredRole && userRole !== requiredRole) {
      console.log('AuthGuard: Role mismatch, required:', requiredRole, 'user role:', userRole, 'redirecting to /access-denied'); // Debug log
      this.router.navigate(['/access-denied']);
      return false;
    }

    console.log('AuthGuard: Allowing access'); // Debug log
    return true;
  }
}