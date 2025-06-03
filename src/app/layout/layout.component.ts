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
    <app-navbar></app-navbar>
    <div class="content">
      <router-outlet></router-outlet>
    </div>
    <app-footer></app-footer>
  `,
  styles: [`
    :host {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }

    .content {
      flex: 1;
      /* Remove padding-top to avoid gap */
    }

    /* Ensure navbar height is accounted for without extra space */
    app-navbar {
      height: 64px; /* Match the assumed navbar height */
      margin-bottom: 0;
    }

    app-footer {
      margin-top: 0;
    }

    .content > * {
      margin-top: 0;
    }
  `]
})
export class LayoutComponent implements OnInit, OnDestroy {
  private routerSubscription!: Subscription;

  constructor(private router: Router) {}

  ngOnInit(): void {
    console.log('LayoutComponent initialized, Initial URL:', this.router.url);

    this.routerSubscription = this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe(event => {
        console.log('NavigationEnd URL:', event.urlAfterRedirects || event.url);
      });
  }

  ngOnDestroy(): void {
    this.routerSubscription?.unsubscribe();
  }
}