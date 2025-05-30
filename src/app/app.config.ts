import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideRouter, withRouterConfig } from '@angular/router';
import { provideHttpClient, withInterceptors, HttpClient } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { authInterceptor } from './auth.interceptor';
import { provideClientHydration } from '@angular/platform-browser';
import { routes } from './app.routes';
import { FormsModule } from '@angular/forms';
import { MatNativeDateModule } from '@angular/material/core';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { TranslateLoader, TranslateModule, TranslateStore } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';

// Factory function for TranslateHttpLoader
export function HttpLoaderFactory(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(
      routes,
      withRouterConfig({
        onSameUrlNavigation: 'reload',
        canceledNavigationResolution: 'computed'
      })
    ),
    provideClientHydration(),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimations(),
    provideAnimationsAsync(),
    // Explicitly provide TranslateStore to ensure it's available
    { provide: TranslateStore, useClass: TranslateStore },
    // Provide TranslateLoader
    { provide: TranslateLoader, useFactory: HttpLoaderFactory, deps: [HttpClient] },
    // Use importProvidersFrom for TranslateModule.forRoot()
    importProvidersFrom(
      TranslateModule.forRoot({
        loader: { provide: TranslateLoader, useFactory: HttpLoaderFactory, deps: [HttpClient] },
        defaultLanguage: 'fr'
      })
    ),
    importProvidersFrom(
      FormsModule,
      MatNativeDateModule
    ),
  ]
};