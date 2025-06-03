import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, NavigationEnd } from '@angular/router';
import { Observable, Subscription } from 'rxjs';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { map, shareReplay, filter } from 'rxjs/operators';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import { UserProfileComponent } from '../user-profile/user-profile.component';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { NotificationsService } from 'src/app/services/notifications.service';

interface Notification {
  id: number;
  type: string;
  message: string;
  createdAt: string;
  isRead: boolean;
  action?: { action: string; subscriptionId?: number };
}

@Component({
  selector: 'app-user-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, SidebarComponent],
  templateUrl: './user-dashboard.component.html',
  styleUrls: ['./user-dashboard.component.css']
})
export class UserDashboardComponent implements OnInit, OnDestroy {
  private authService = inject(AuthService);
  private breakpointObserver = inject(BreakpointObserver);
  private router = inject(Router);
  private notificationsService = inject(NotificationsService);

  isLoggedIn$: Observable<boolean> = this.authService.authStatus$;
  isMobile$: Observable<boolean> = this.breakpointObserver
    .observe(Breakpoints.Handset)
    .pipe(
      map(result => result.matches),
      shareReplay()
    );

  isMobile = false;
  isCollapsed = false;
  userName: string | null = null;
  userInitials: string | null = null;
  pageTitle: string = 'Vue d’ensemble du tableau de bord';
  notifications: Notification[] = [];
  showNotifications = false;
  private routerSubscription!: Subscription;

  ngOnInit(): void {
    this.isMobile$.subscribe(isMobile => {
      this.isMobile = isMobile;
    });

    this.authService.user$.subscribe(user => {
      if (user) {
        this.userName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || null;
        this.userInitials = user.initials || `${user.firstName?.charAt(0) || ''}${user.lastName?.charAt(0) || ''}`.toUpperCase() || 'UN';
      } else {
        this.userName = null;
        this.userInitials = 'UN';
      }
    });

    this.authService.isSidebarCollapsed$.subscribe(isCollapsed => {
      this.isCollapsed = isCollapsed;
    });

    this.notificationsService.getNotifications().subscribe(notifications => {
      this.notifications = notifications;
    });

    this.notificationsService.notifications$.subscribe(notification => {
      this.notifications.unshift(notification);
    });

    this.routerSubscription = this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd)
      )
      .subscribe((event: NavigationEnd) => {
        const routeTitles: { [key: string]: string } = {
          '/dashboard': 'Vue d’ensemble du tableau de bord',
          '/dashboard/reservations': 'Vos réservations',
          '/dashboard/subscriptions': 'Vos abonnements',
          '/dashboard/profile/info': 'Profil - Informations',
          '/dashboard/profile/password': 'Profil - Mot de passe',
          '/dashboard/profile/vehicles': 'Profil - Véhicules',
          '/dashboard/profile/subscription': 'Profil - Abonnement',
          '/dashboard/profile/history': 'Profil - Historique des Réservations',
          '/dashboard/settings': 'Paramètres',
          '/dashboard/spot-status': 'Statut des places',
          '/dashboard/notifications': 'Notifications'
        };
        this.pageTitle = routeTitles[event.urlAfterRedirects] || routeTitles[event.url] || 'Vue d’ensemble du tableau de bord';
      });
  }

  ngOnDestroy(): void {
    this.routerSubscription?.unsubscribe();
  }

  toggleSidebar(): void {
    this.authService.toggleSidebar();
  }

  toggleNotifications(): void {
    this.showNotifications = !this.showNotifications;
  }

  markAsRead(notification: Notification): void {
    if (!notification.isRead) {
      this.notificationsService.markAsRead(notification.id).subscribe(() => {
        notification.isRead = true;
      });
    }
  }

  handleAction(notification: Notification): void {
    if (notification.action && notification.action.action === 'RENEW' && notification.action.subscriptionId) {
      this.router.navigate(['/dashboard/subscriptions'], { queryParams: { renew: notification.action.subscriptionId } });
      this.showNotifications = false;
    }
  }

  get unreadCount(): number {
    return this.notifications.filter(n => !n.isRead).length;
  }
}