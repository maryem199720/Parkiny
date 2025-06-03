import { Routes } from '@angular/router';
import { AuthGuard } from './core/auth.guard/auth.guard.component';
import { LayoutComponent } from './layout/layout.component';

export const routes: Routes = [
  {
    path: '',
    component: LayoutComponent,
    children: [
      { path: '', redirectTo: '/home', pathMatch: 'full' },
      {
        path: 'home',
        loadComponent: () => import('./components/home/home.component').then(m => m.HomeComponent),
        data: { public: true }
      },
      {
        path: 'about',
        loadComponent: () => import('./components/about/about.component').then(m => m.AboutComponent),
        data: { public: true }
      },
      {
        path: 'contact',
        loadComponent: () => import('./components/contact/contact.component').then(m => m.ContactComponent),
        data: { public: true }
      },
      {
        path: 'faq',
        loadComponent: () => import('./components/faq/faq.component').then(m => m.FaqComponent),
        data: { public: true }
      },
      {
        path: 'how-it-works',
        loadComponent: () => import('./components/how-it-works/how-it-works.component').then(m => m.HowItWorksComponent),
        data: { public: true }
      },
      {
        path: 'privacy-policy',
        loadComponent: () => import('./components/privacy-policy/privacy-policy.component').then(m => m.PrivacyPolicyComponent),
        data: { public: true }
      },
      {
        path: 'auth',
        loadComponent: () => import('./auth/components/auth/auth.component').then(m => m.AuthComponent),
        data: { public: true }
      }
    ]
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./components/user-dashboard/user-dashboard.component').then(m => m.UserDashboardComponent),
    canActivate: [AuthGuard],
    data: { role: 'ROLE_USER' },
    children: [
      {
        path: '',
        loadComponent: () => import('./components/user-dashboard/components/dashboard/dashboard.component').then(m => m.DashboardComponent)
      },
      {
        path: 'reservations',
        loadComponent: () => import('./components/reservations/reservations.component').then(m => m.ReservationsComponent)
      },
      {
        path: 'profile/info',
        loadComponent: () => import('./components/profile-info/profile-info.component').then(m => m.ProfileInfoComponent)
      },
      {
        path: 'profile/password',
        loadComponent: () => import('./components/profile-password/profile-password.component').then(m => m.ProfilePasswordComponent)
      },
      {
        path: 'profile/vehicles',
        loadComponent: () => import('./components/profile-vehicles/profile-vehicles.component').then(m => m.ProfileVehiclesComponent)
      },
      {
        path: 'profile/forgot-password',
        loadComponent: () => import('./components/forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent)
      },
      {
        path: 'profile/subscription',
        loadComponent: () => import('./components/profile-subscription/profile-subscription.component').then(m => m.ProfileSubscriptionComponent)
      },
      {
        path: 'profile/history',
        loadComponent: () => import('./components/reservation-history/reservation-history.component').then(m => m.ReservationHistoryComponent)
      },
      {
        path: 'subscriptions',
        loadComponent: () => import('./components/subscription/subscription.component').then(m => m.SubscriptionComponent)
      },
      {
        path: 'notifications',
        loadComponent: () => import('./components/user-dashboard/components/notifications/notifications.component').then(m => m.NotificationsComponent)
      },
      {
        path: 'profile',
        redirectTo: 'profile/info',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: 'app/admin/dashboard',
    loadComponent: () => import('./dashboard-admin/admin-dashboard.component').then(m => m.AdminDashboardComponent),
    canActivate: [AuthGuard],
    data: { role: 'ROLE_ADMIN' }
  },
  {
    path: '**',
    redirectTo: '/home'
  }
];