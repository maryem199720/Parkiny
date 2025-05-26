import { Routes } from '@angular/router';
import { AuthGuard } from './core/auth.guard/auth.guard.component';

export const routes: Routes = [
  // Make user dashboard the home page
  { 
    path: '',
    redirectTo: 'app/user/dashboard',
    pathMatch: 'full'
  },
  { 
    path: 'auth',
    loadComponent: () => import('./auth/components/auth/auth.component').then(m => m.AuthComponent),
    data: { hideNavbar: true }
  },
  {
    path: 'app',
    loadComponent: () => import('./layout/layout.component').then(m => m.LayoutComponent),
    children: [
      {
        path: 'user/dashboard',
        // Removed canActivate to allow non-authenticated users to see the dashboard
        children: [
          { path: '', loadComponent: () => import('./components/user-dashboard/user-dashboard.component').then(m => m.UserDashboardComponent) },
          { 
            path: 'profile', 
            canActivate: [AuthGuard],
            data: { role: 'ROLE_USER' },
            loadComponent: () => import('./components/profile/profile.component').then(m => m.ProfileComponent) 
          },
          { 
            path: 'reservations', 
            canActivate: [AuthGuard],
            data: { role: 'ROLE_USER' },
            loadComponent: () => import('./components/reservations/reservations.component').then(m => m.ReservationComponent) 
          },
          { 
            path: 'abonnements', 
            canActivate: [AuthGuard],
            data: { role: 'ROLE_USER' },
            loadComponent: () => import('./components/subscription/subscription.component').then(m => m.SubscriptionComponent) 
          },
          { path: '**', redirectTo: '' }
        ]
      },
      { path: '**', redirectTo: 'user/dashboard' }
    ]
  },
  { path: '**', redirectTo: '' }
];
