import { Injectable, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { isPlatformBrowser } from '@angular/common';

interface AuthResponse {
  message: any;
  token: string;
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  roles: string[];
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private apiUrl = 'http://localhost:8082/parking/api/auth';
  private tokenKey = 'token';
  private authStatus = new BehaviorSubject<boolean>(false);
  public authStatus$ = this.authStatus.asObservable();

  constructor(
    private http: HttpClient,
    private router: Router,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    if (isPlatformBrowser(this.platformId)) {
      this.authStatus.next(!!localStorage.getItem(this.tokenKey));
    }
  }

  login(credentials: { email: string; password: string }): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/signin`, credentials).pipe(
      tap({
        next: (response) => {
          console.log('Réponse reçue:', response);
          if (isPlatformBrowser(this.platformId)) {
            localStorage.setItem(this.tokenKey, response.token);
            localStorage.setItem('user', JSON.stringify({
              id: response.id,
              firstName: response.firstName,
              lastName: response.lastName,
              email: response.email,
              phone: response.phone,
              role: this.getUserRole(response.roles)
            }));
            this.authStatus.next(true);
            this.redirectBasedOnRole(response.roles);
          }
        },
        error: (err) => console.error('Erreur de connexion:', err)
      })
    );
  }

  register(userData: any): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/signup`, userData).pipe(
      tap({
        next: (response) => {
          console.log('Inscription réussie:', response);
          if (isPlatformBrowser(this.platformId)) {
            localStorage.setItem(this.tokenKey, response.token);
            localStorage.setItem('user', JSON.stringify({
              id: response.id,
              firstName: response.firstName,
              lastName: response.lastName,
              email: response.email,
              phone: response.phone,
              role: this.getUserRole(response.roles)
            }));
            this.authStatus.next(true);
            this.redirectBasedOnRole(response.roles);
          }
        },
        error: (err) => console.error('Erreur d\'inscription:', err)
      })
    );
  }

  private getUserRole(roles: string[]): string {
    return roles.includes('ROLE_ADMIN') ? 'ADMIN' : 'USER';
  }

  private redirectBasedOnRole(roles: string[]): void {
    const redirectPath = roles.includes('ROLE_ADMIN') 
      ? '/app/admin/dashboard' 
      : '/dashboard'; // Updated to match your current route
    
    const urlParams = new URLSearchParams(window.location.search);
    const returnUrl = urlParams.get('returnUrl') || redirectPath;

    if (isPlatformBrowser(this.platformId)) {
      this.router.navigateByUrl(returnUrl, { replaceUrl: true })
        .then(success => {
          if (!success) {
            console.error('Échec de la navigation vers:', returnUrl);
            window.location.href = returnUrl;
          }
        });
    }
  }

  logout(): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.clear();
      this.authStatus.next(false);
      console.log('Logout successful, auth status:', false); // Debug log
    }
    // Removed navigation to /auth to stay on current page
  }

  isAuthenticated(): boolean {
    return isPlatformBrowser(this.platformId)
      ? !!localStorage.getItem(this.tokenKey)
      : false;
  }

  isAdmin(): boolean {
    const user = this.getUser();
    return user.role === 'ADMIN';
  }

  getUser(): any {
    if (!isPlatformBrowser(this.platformId)) return {};
    const userData = localStorage.getItem('user') || '{}';
    return JSON.parse(userData);
  }

  getToken(): string | null {
    return isPlatformBrowser(this.platformId) ? localStorage.getItem(this.tokenKey) : null;
  }
}