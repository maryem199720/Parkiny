import { Component, OnInit, HostListener } from '@angular/core';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { CommonModule } from '@angular/common';

import { TranslateService } from '../services/translate.service';
import { AuthService } from '../auth/services/auth/auth.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.css']
})
export class NavbarComponent implements OnInit {
  showMobileMenu = false;
  showUserDropdown = false;
  showLanguageDropdown = false;
  currentLanguage = 'FR';
  userName = 'Utilisateur';
  isScrolled = false;

  constructor(
    public authService: AuthService,
    private router: Router,
    private translateService: TranslateService
  ) {}

  ngOnInit(): void {
  // Get user name if authenticated
  if (this.authService.isAuthenticated()) {
    const user = this.authService.getCurrentUser();
    if (user && user.name) {
      this.userName = user.name;
    }
  }

  // Get current language from service
  this.currentLanguage = this.translateService.getCurrentLanguage();
}


  @HostListener('window:scroll', [])
  onWindowScroll() {
    this.isScrolled = window.scrollY > 20;
  }

  toggleMobileMenu(): void {
    this.showMobileMenu = !this.showMobileMenu;
    // Close other dropdowns when toggling mobile menu
    this.showUserDropdown = false;
    this.showLanguageDropdown = false;
  }

  toggleUserDropdown(): void {
    this.showUserDropdown = !this.showUserDropdown;
    // Close language dropdown when toggling user dropdown
    this.showLanguageDropdown = false;
  }

  toggleLanguageDropdown(): void {
    this.showLanguageDropdown = !this.showLanguageDropdown;
    // Close user dropdown when toggling language dropdown
    this.showUserDropdown = false;
  }

  changeLanguage(lang: string): void {
    this.currentLanguage = lang;
    this.translateService.setLanguage(lang);
    this.showLanguageDropdown = false;
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth']);
  }

  // Close dropdowns when clicking outside
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const userMenuElement = document.querySelector('.user-menu');
    const languageSelectorElement = document.querySelector('.language-selector');
    
    // Check if click is outside user menu
    if (userMenuElement && !userMenuElement.contains(event.target as Node)) {
      this.showUserDropdown = false;
    }
    
    // Check if click is outside language selector
    if (languageSelectorElement && !languageSelectorElement.contains(event.target as Node)) {
      this.showLanguageDropdown = false;
    }
  }
}
