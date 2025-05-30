import { Routes } from '@angular/router';
import { AuthGuard } from './core/auth.guard/auth.guard.component';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/app/user/dashboard', // Redirect root to dashboard
    pathMatch: 'full'
  },
  {
    path: 'auth',
    loadComponent: () => import('./auth/components/auth/auth.component').then(m => m.AuthComponent)
  },
  {
    path: 'app',
    children: [
      {
        path: 'user',
        canActivate: [AuthGuard], // Protect user routes
        children: [
          {
            path: '',
            redirectTo: 'dashboard',
            pathMatch: 'full'
          },
          {
            path: 'dashboard',
            loadComponent: () => import('./components/user-dashboard/user-dashboard.component').then(m => m.UserDashboardComponent)
          },
          {
            path: 'profile',
            loadComponent: () => import('./components/profile/profile.component').then(m => m.ProfileComponent)
          },
          {
            path: 'reservations',
            loadComponent: () => import('./components/reservations/reservations.component').then(m => m.ReservationsComponent)
          },
          {
            path: 'subscriptions',
            loadComponent: () => import('./components/subscription/subscription.component').then(m => m.SubscriptionComponent)
          },
          {
            path: 'about',
            loadComponent: () => import('./components/about/about.component').then(m => m.AboutComponent)
          },
          {
            path: 'contact',
            loadComponent: () => import('./components/contact/contact.component').then(m => m.ContactComponent)
          },
          {
            path: 'faq',
            loadComponent: () => import('./components/faq/faq.component').then(m => m.FaqComponent)
          },
          {
            path: 'how-it-works',
            loadComponent: () => import('./components/how-it-works/how-it-works.component').then(m => m.HowItWorksComponent)
          },
          {
            path: 'privacy-policy',
            loadComponent: () => import('./components/privacy-policy/privacy-policy.component').then(m => m.PrivacyPolicyComponent)
          }
          // Optional: If you want abonnements as a sub-route of dashboard
          // {
          //   path: 'dashboard/abonnements',
          //   loadComponent: () => import('./components/subscription/subscription.component').then(m => m.SubscriptionComponent)
          // }
        ]
      }
    ]
  },
  {
    path: '**', // Wildcard route for 404s
    redirectTo: '/app/user/dashboard'
  }
];