import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { NavbarComponent } from './navbar/navbar.component';
import { HttpClientModule } from '@angular/common/http';
import { Router, NavigationEnd } from '@angular/router';
import { filter, Subscription } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    NavbarComponent,
    HttpClientModule
  ],
  template: `
    <app-navbar *ngIf="showNavbar"></app-navbar>
    <div class="page-content" [ngClass]="{ 'with-navbar': showNavbar }">
      <router-outlet></router-outlet>
    </div>
  `,
  styles: [`
    :host {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
      text-rendering: optimizeLegibility;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
    .page-content {
      @apply flex-1 pt-0;
    }
    .page-content.with-navbar {
      @apply pt-0;
    }
  `]
})
export class AppComponent implements OnInit, OnDestroy {
  showNavbar = true;
  private routerSubscription!: Subscription;

  constructor(private router: Router) {}

  ngOnInit(): void {
    this.routerSubscription = this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd)
      )
      .subscribe(event => {
        const url = event.urlAfterRedirects || event.url;
        console.log('NavigationEnd:', url); // Debug log
        this.showNavbar = !url.includes('/auth');
      });

    const initialUrl = this.router.url;
    console.log('Initial URL:', initialUrl); // Debug log
    this.showNavbar = !initialUrl.includes('/auth');
  }

  ngOnDestroy(): void {
    if (this.routerSubscription) {
      this.routerSubscription.unsubscribe();
    }
  }
}