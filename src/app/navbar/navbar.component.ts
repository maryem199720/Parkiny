import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../auth/services/auth/auth.service';
import { TranslateService, TranslateModule } from '@ngx-translate/core';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, TranslateModule],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.css']
})
export class NavbarComponent implements OnInit, OnDestroy {
  private authSubscription!: Subscription;

  constructor(
    public authService: AuthService,
    private translateService: TranslateService,
    private router: Router
  ) {}

  ngOnInit(): void {
    const savedLang = localStorage.getItem('parkiny_lang') || 'fr'; // Align with AppComponent
    this.translateService.use(savedLang);
    this.authSubscription = this.authService.authStatus$.subscribe(status => {
      console.log('Auth status changed:', status);
    });
  }

  ngOnDestroy(): void {
    if (this.authSubscription) {
      this.authSubscription.unsubscribe();
    }
  }

  switchLanguage(lang: string): void {
    this.translateService.use(lang);
    localStorage.setItem('parkiny_lang', lang); // Align with AppComponent
  }

  changeLanguage(lang: string): void {
    this.switchLanguage(lang); // Implement changeLanguage to call switchLanguage
  }

  logout(): void {
    this.authService.logout();
    console.log('Logged out, staying on current page');
  }
}