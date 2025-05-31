import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, NavigationEnd } from '@angular/router';
import { Observable } from 'rxjs';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { map, shareReplay, filter } from 'rxjs/operators';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { SidebarComponent } from './components/sidebar/sidebar.component';

@Component({
  selector: 'app-user-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, SidebarComponent],
  templateUrl: './user-dashboard.component.html',
  styleUrl: './user-dashboard.component.css'
})
export class UserDashboardComponent implements OnInit {
  isLoggedIn$: Observable<boolean>;
  isMobile$: Observable<boolean>;
  isMobile = false;
  userName: string | null = null;
  userInitials: string | null = null;
  pageTitle: string = 'Dashboard Overview';

  constructor(
    private authService: AuthService,
    private breakpointObserver: BreakpointObserver,
    private router: Router
  ) {
    this.isLoggedIn$ = this.authService.isLoggedIn();
    this.isMobile$ = this.breakpointObserver
      .observe(Breakpoints.Handset)
      .pipe(
        map(result => result.matches),
        shareReplay()
      );
  }

  ngOnInit() {
    this.isMobile$.subscribe(isMobile => {
      this.isMobile = isMobile;
    });

    this.authService.getUser().subscribe(user => {
      this.userName = user ? `${user.firstName} ${user.lastName}`.trim() || null : null;
      this.userInitials = user ? user.initials : 'UN';
    });

    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: NavigationEnd) => {
        const routeTitles: { [key: string]: string } = {
          '/dashboard': 'Dashboard Overview',
          '/dashboard/parking-map': 'Parking Map',
          '/dashboard/reservations': 'Your Reservations',
          '/dashboard/profile': 'Profile'
        };
        this.pageTitle = routeTitles[event.url] || 'Dashboard Overview';
      });
  }

  toggleSidebar() {
    this.authService.toggleSidebar();
  }
}