import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Observable } from 'rxjs';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { map, shareReplay } from 'rxjs/operators';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.css'
})
export class SidebarComponent implements OnInit {
  isLoggedIn$: Observable<boolean>;
  isSidebarOpen$: Observable<boolean>;
  isMobile$: Observable<boolean>;
  userName: string | null = null;
  userInitials: string | null = null;

  constructor(
    private authService: AuthService,
    private breakpointObserver: BreakpointObserver
  ) {
    this.isLoggedIn$ = this.authService.authStatus$;
    this.isSidebarOpen$ = this.authService.sidebarOpen$;
    this.isMobile$ = this.breakpointObserver
      .observe(Breakpoints.Handset)
      .pipe(
        map(result => result.matches),
        shareReplay()
      );
  }

  ngOnInit() {
    this.authService.getUser().subscribe(user => {
      this.userName = user ? `${user.firstName} ${user.lastName}`.trim() || null : null;
      this.userInitials = user ? user.initials : 'UN';
    });
  }

  toggleSidebar() {
    this.authService.toggleSidebar();
  }

  logout() {
    this.authService.logout();
  }
}