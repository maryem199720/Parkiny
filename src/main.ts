import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter, withDebugTracing, withRouterConfig } from '@angular/router';
import { routes } from './app/app.routes';
import { registerLocaleData } from '@angular/common';
import en from '@angular/common/locales/en';
import { FormsModule } from '@angular/forms';
import { importProvidersFrom } from '@angular/core';
import { provideAnimations } from '@angular/platform-browser/animations';
import { provideHttpClient } from '@angular/common/http';
import { AppComponent } from './app/app.component';
import { MatNativeDateModule } from '@angular/material/core';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';

registerLocaleData(en);

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(
      routes,
      withDebugTracing(), // Enable router event logging for debugging
      withRouterConfig({
        onSameUrlNavigation: 'reload', // Handle navigation to the same URL
        canceledNavigationResolution: 'computed' // Resolve canceled navigations
      })
    ),
    importProvidersFrom(FormsModule),
    provideAnimations(),
    provideHttpClient(),
    importProvidersFrom(MatNativeDateModule),
    provideAnimationsAsync()
  ]
}).catch((err) => console.error(err));