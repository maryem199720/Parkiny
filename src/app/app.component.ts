import { Component, OnInit, OnDestroy, Renderer2, Inject } from '@angular/core';
import { CommonModule, DOCUMENT } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { NavbarComponent } from './navbar/navbar.component';
import { FooterComponent } from './components/footer/footer.component';
import { Router, NavigationEnd } from '@angular/router';
import { filter, Subscription } from 'rxjs';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    NavbarComponent,
    FooterComponent,
    TranslateModule
  ],
  template: `
    <app-navbar *ngIf="showNavbar"></app-navbar>
    <div class="page-content flex-grow" [ngClass]="{ 'with-navbar': showNavbar }">
      <router-outlet></router-outlet>
    </div>
    <app-footer *ngIf="showNavbar"></app-footer>
  `,
  styles: [`
    :host {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
      text-rendering: optimizeLegibility;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
    .page-content {
      flex-grow: 1;
      padding-top: 0;
    }
    .page-content.with-navbar {
      padding-top: 4rem; /* Adjust to navbar height if fixed/sticky */
    }
  `]
})
export class AppComponent implements OnInit, OnDestroy {
  showNavbar = true;
  private routerSubscription!: Subscription;
  private langChangeSubscription!: Subscription;

  constructor(
    private router: Router,
    private translate: TranslateService,
    private renderer: Renderer2,
    @Inject(DOCUMENT) private document: Document
  ) {
    this.translate.setDefaultLang('fr');
    const initialLang = localStorage.getItem('parkiny_lang') || 'fr';
    this.translate.use(initialLang);
  }

  ngOnInit(): void {
    this.routerSubscription = this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe(event => {
        const url = event.urlAfterRedirects || event.url;
        this.showNavbar = !url.includes('/auth');
      });

    const initialUrl = this.router.url;
    this.showNavbar = !initialUrl.includes('/auth');

    this.langChangeSubscription = this.translate.onLangChange.subscribe((event) => {
      this.updateDirectionality(event.lang);
      localStorage.setItem('parkiny_lang', event.lang);
    });

    this.updateDirectionality(this.translate.currentLang);
  }

  ngOnDestroy(): void {
    if (this.routerSubscription) {
      this.routerSubscription.unsubscribe();
    }
    if (this.langChangeSubscription) {
      this.langChangeSubscription.unsubscribe();
    }
  }

  private updateDirectionality(lang: string): void {
    const direction = lang === 'ar' ? 'rtl' : 'ltr';
    this.renderer.setAttribute(this.document.documentElement, 'dir', direction);
    this.renderer.setAttribute(this.document.documentElement, 'lang', lang);
    if (direction === 'rtl') {
      this.renderer.addClass(this.document.body, 'rtl');
      this.renderer.removeClass(this.document.body, 'ltr');
    } else {
      this.renderer.addClass(this.document.body, 'ltr');
      this.renderer.removeClass(this.document.body, 'rtl');
    }
  }
}