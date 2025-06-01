// src/app/components/layout/layout.component.ts
import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';

import { filter, Subscription } from 'rxjs';
import { FooterComponent } from '../components/footer/footer.component';
import { NavbarComponent } from '../navbar/navbar.component';

@Component({
  selector: 'app-layout',
  standalone: true,
  imports: [CommonModule, RouterOutlet, NavbarComponent, FooterComponent],
  template: `
    <app-navbar *ngIf="showNavbar"></app-navbar>
    <div class="content" [ngClass]="{ 'with-navbar': showNavbar }">
      <router-outlet></router-outlet>
    </div>
    <app-footer *ngIf="showNavbar"></app-footer>
  `,
  styles: [`
    .content {
      padding-top: 0;
      min-height: calc(100vh - 64px); /* Adjust based on navbar height */
    }
  `]
})
export class LayoutComponent implements OnInit, OnDestroy {
  showNavbar = true;
  private routerSubscription!: Subscription;

  constructor(private router: Router) {}

  ngOnInit(): void {
    console.log('LayoutComponent initialized, Initial URL:', this.router.url);
    this.updateNavbarVisibility(this.router.url);

    this.routerSubscription = this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe(event => {
        console.log('NavigationEnd URL:', event.urlAfterRedirects || event.url);
        this.updateNavbarVisibility(event.urlAfterRedirects || event.url);
      });
  }

  ngOnDestroy(): void {
    this.routerSubscription?.unsubscribe();
  }

  private updateNavbarVisibility(url: string): void {
    const shouldHide = url.startsWith('/auth') || url.startsWith('/dashboard') || url.startsWith('/app/admin/dashboard');
    this.showNavbar = !shouldHide;
    console.log('URL:', url, 'showNavbar:', this.showNavbar);
  }
}