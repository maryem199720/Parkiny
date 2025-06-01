// src/app/components/user-dashboard/user-dashboard.component.ts
import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, NavigationEnd } from '@angular/router';
import { Observable, Subscription } from 'rxjs';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { map, shareReplay, filter } from 'rxjs/operators';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { SidebarComponent } from './components/sidebar/sidebar.component';

@Component({
  selector: 'app-user-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, SidebarComponent],
  templateUrl: './user-dashboard.component.html',
  styleUrls: ['./user-dashboard.component.css']
})
export class UserDashboardComponent implements OnInit, OnDestroy {
  isLoggedIn$: Observable<boolean>;
  isMobile$: Observable<boolean>;
  isMobile = false;
  userName: string | null = null;
  userInitials: string | null = null;
  pageTitle: string = 'Vue d’ensemble du tableau de bord';
  private routerSubscription!: Subscription;

  constructor(
    private authService: AuthService,
    private breakpointObserver: BreakpointObserver,
    private router: Router
  ) {
    this.isLoggedIn$ = this.authService.authStatus$;
    this.isMobile$ = this.breakpointObserver
      .observe(Breakpoints.Handset)
      .pipe(
        map(result => result.matches),
        shareReplay()
      );
  }

  ngOnInit(): void {
    this.isMobile$.subscribe(isMobile => {
      this.isMobile = isMobile;
    });

    const user = this.authService.getCurrentUser();
    this.userName = user ? `${user.firstName} ${user.lastName}`.trim() || null : null;
    this.userInitials = user ? user.initials : 'UN';

    this.routerSubscription = this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd)
      )
      .subscribe((event: NavigationEnd) => {
        const routeTitles: { [key: string]: string } = {
          '/app/user/dashboard': 'Vue d’ensemble du tableau de bord',
          '/app/user/reservations': 'Vos réservations',
          '/app/user/subscriptions': 'Vos abonnements',
          '/app/user/profile': 'Profil'
        };
        this.pageTitle = routeTitles[event.urlAfterRedirects || event.url] || 'Vue d’ensemble du tableau de bord';
      });
  }

  ngOnDestroy(): void {
    this.routerSubscription?.unsubscribe();
  }

  toggleSidebar(): void {
    this.authService.toggleSidebar();
  }
}