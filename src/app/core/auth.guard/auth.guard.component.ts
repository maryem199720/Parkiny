import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private authService: AuthService, private router: Router) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> {
    const isPublic = route.data['public'] || false;
    console.log('AuthGuard: Checking route:', state.url, 'Public:', isPublic);

    if (isPublic) {
      console.log('AuthGuard: Allowing public route');
      return of(true);
    }

    return this.authService.getUser().pipe(
      map(user => {
        console.log('AuthGuard: User:', user);

        if (!user) {
          console.log('AuthGuard: User not authenticated, redirecting to /auth');
          this.router.navigate(['/auth'], { queryParams: { returnUrl: state.url } });
          return false;
        }

        const requiredRole = route.data['role'] as string | undefined;
        const userRole = user.role === 'ADMIN' ? 'ROLE_ADMIN' : 'ROLE_USER';
        console.log('AuthGuard: Required role:', requiredRole, 'User role:', userRole);

        if (requiredRole && userRole !== requiredRole) {
          console.log('AuthGuard: Role mismatch, redirecting to /access-denied');
          this.router.navigate(['/access-denied']);
          return false;
        }

        console.log('AuthGuard: Allowing access');
        return true;
      }),
      catchError(err => {
        console.error('AuthGuard: Error fetching user', err);
        this.router.navigate(['/auth'], { queryParams: { returnUrl: state.url } });
        return of(false);
      })
    );
  }
}