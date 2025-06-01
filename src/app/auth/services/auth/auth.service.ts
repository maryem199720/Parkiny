// src/app/auth/services/auth/auth.service.ts
import { Injectable, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { isPlatformBrowser } from '@angular/common';

interface AuthResponse {
  message: string; // Changed from any to string
  token: string;
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  roles: string[];
}

interface User {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  role: string;
  initials: string;
}

interface RegisterData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  password: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private apiUrl = 'http://localhost:8082/parking/api/auth';
  private tokenKey = 'token';
  private authStatus = new BehaviorSubject<boolean>(false);
  public authStatus$ = this.authStatus.asObservable();
  private sidebarOpen = new BehaviorSubject<boolean>(false);
  public sidebarOpen$ = this.sidebarOpen.asObservable();

  constructor(
    private http: HttpClient,
    private router: Router,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    console.log('AuthService initialized');
    if (isPlatformBrowser(this.platformId)) {
      const token = localStorage.getItem(this.tokenKey);
      console.log('Initial auth check: token exists:', !!token);
      this.authStatus.next(!!token);
    }
  }

  login(credentials: { email: string; password: string }): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/signin`, credentials).pipe(
      tap({
        next: (response) => {
          console.log('Login response:', response);
          if (isPlatformBrowser(this.platformId)) {
            localStorage.setItem(this.tokenKey, response.token);
            const user: User = {
              id: response.id,
              firstName: response.firstName || '',
              lastName: response.lastName || '',
              email: response.email,
              phone: response.phone,
              role: this.getUserRole(response.roles),
              initials: this.getInitials(response.firstName, response.lastName)
            };
            localStorage.setItem('user', JSON.stringify(user));
            this.authStatus.next(true);
            this.redirectBasedOnRole(response.roles);
          }
        },
        error: (err) => console.error('Login error:', err)
      })
    );
  }

  register(userData: RegisterData): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/signup`, userData).pipe(
      tap({
        next: (response) => {
          console.log('Register response:', response);
          if (isPlatformBrowser(this.platformId)) {
            localStorage.setItem(this.tokenKey, response.token);
            const user: User = {
              id: response.id,
              firstName: response.firstName || '',
              lastName: response.lastName || '',
              email: response.email,
              phone: response.phone,
              role: this.getUserRole(response.roles),
              initials: this.getInitials(response.firstName, response.lastName)
            };
            localStorage.setItem('user', JSON.stringify(user));
            this.authStatus.next(true);
            this.redirectBasedOnRole(response.roles);
          }
        },
        error: (err) => console.error('Register error:', err)
      })
    );
  }

  private getUserRole(roles: string[]): string {
    return roles.includes('ROLE_ADMIN') ? 'ADMIN' : 'USER';
  }

  private getInitials(firstName: string, lastName: string): string {
    if (!firstName || !lastName) return 'UN';
    return firstName.charAt(0).toUpperCase() + lastName.charAt(0).toUpperCase();
  }

  private redirectBasedOnRole(roles: string[]): void {
    const redirectPath = roles.includes('ROLE_ADMIN') ? '/app/admin/dashboard' : '/dashboard';
    const urlParams = new URLSearchParams(isPlatformBrowser(this.platformId) ? window.location.search : '');
    const returnUrl = urlParams.get('returnUrl') || redirectPath;

    if (isPlatformBrowser(this.platformId)) {
      console.log('Redirecting to:', returnUrl);
      this.router.navigateByUrl(returnUrl, { replaceUrl: true }).then(success => {
        if (!success) {
          console.error('Navigation failed to:', returnUrl);
          window.location.href = returnUrl;
        }
      });
    }
  }

  logout(): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.clear();
      this.authStatus.next(false);
      this.sidebarOpen.next(false);
      console.log('Logout successful, auth status:', false);
      this.router.navigate(['/auth']);
    }
  }

  isAuthenticated(): boolean {
    if (!isPlatformBrowser(this.platformId)) return false;
    return !!localStorage.getItem(this.tokenKey);
  }

  isLoggedIn(): Observable<boolean> {
    return this.authStatus$;
  }

  isAdmin(): boolean {
    const user = this.getCurrentUser();
    return user?.role === 'ADMIN';
  }

  getUser(): Observable<User | null> {
    if (!isPlatformBrowser(this.platformId)) return of(null);
    const userData = localStorage.getItem('user');
    if (!userData) return of(null);
    try {
      const user: User = JSON.parse(userData);
      user.initials = this.getInitials(user.firstName || '', user.lastName || '');
      return of(user);
    } catch (e) {
      console.error('Error parsing user data:', e);
      return of(null);
    }
  }

  getToken(): string | null {
    return isPlatformBrowser(this.platformId) ? localStorage.getItem(this.tokenKey) : null;
  }

  getCurrentUser(): User | null {
    if (!isPlatformBrowser(this.platformId)) return null;
    const userStr = localStorage.getItem('user');
    if (!userStr) return null;
    try {
      const user: User = JSON.parse(userStr);
      user.initials = this.getInitials(user.firstName || '', user.lastName || '');
      return user;
    } catch (e) {
      console.error('Error parsing user data:', e);
      return null;
    }
  }

  toggleSidebar(): void {
    const current = this.sidebarOpen.value;
    this.sidebarOpen.next(!current);
    console.log('Sidebar toggled:', !current);
  }
}