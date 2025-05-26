import { Routes } from '@angular/router';
import { AuthGuard } from './core/auth.guard/auth.guard.component';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/app/user/dashboard',
    pathMatch: 'full'
  },
  {
  path: 'auth',
  loadComponent: () => import('./auth/components/auth/auth.component').then(m => m.AuthComponent) // <-- CORRIGÉ : Utiliser loadComponent
},
  {
    path: 'app',
    children: [
      {
        path: 'user',
        canActivate: [AuthGuard],
        children: [
          {
            path: 'dashboard',
            loadComponent: () => import('./components/user-dashboard/user-dashboard.component').then(m => m.UserDashboardComponent)
          },
          {
            path: 'dashboard/profile',
            loadComponent: () => import('./components/profile/profile.component').then(m => m.ProfileComponent)
          },
          {
            path: 'dashboard/reservations',
            loadComponent: () => import('./components/reservations/reservations.component').then(m => m.ReservationComponent)
          },
          {
            path: 'dashboard/subscriptions',
            loadComponent: () => import('./components/subscription/subscription.component').then(m => m.SubscriptionComponent)
          },
          {
            path: 'dashboard/about',
            loadComponent: () => import('./components/about/about.component').then(m => m.AboutComponent)
          },
          {
            path: 'dashboard/contact',
            loadComponent: () => import('./components/contact/contact.component').then(m => m.ContactComponent)
          },
          {
            path: 'dashboard/faq',
            loadComponent: () => import('./components/faq/faq.component').then(m => m.FaqComponent)
          },
          {
            path: 'dashboard/how-it-works',
            loadComponent: () => import('./components/how-it-works/how-it-works.component').then(m => m.HowItWorksComponent)
          }
        ]
      }
    ]
  },
  {
    path: '**',
    redirectTo: '/app/user/dashboard'
  }
];
