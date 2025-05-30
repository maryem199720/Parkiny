import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class StorageService {
  private tokenKey = 'token'; // Consistent key for token storage

  // Check if the user is logged in by verifying the presence of the token
  isLoggedIn(): boolean {
    return !!localStorage.getItem(this.tokenKey);
  }

  // Retrieve the token from localStorage
  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  // Retrieve the user ID from the stored user object
  getUserId(): number {
    try {
      const user = JSON.parse(localStorage.getItem('user') || '{}');
      return user.id ? Number(user.id) : 0;
    } catch (error) {
      console.error('Error parsing user from localStorage:', error);
      return 0;
    }
  }

  // Retrieve the user object from localStorage
  getUser(): any {
    try {
      return JSON.parse(localStorage.getItem('user') || '{}');
    } catch (error) {
      console.error('Error parsing user from localStorage:', error);
      return {};
    }
  }

  // Log out by removing token and user from localStorage
  logout(): void {
    localStorage.removeItem(this.tokenKey); // Use consistent tokenKey
    localStorage.removeItem('user');
  }
}