import { Injectable } from '@angular/core';
import { Observable, BehaviorSubject } from 'rxjs';

export interface TranslationSet {
  [key: string]: string;
}

@Injectable({
  providedIn: 'root'
})
export class CustomTranslateService {
  private currentLang = new BehaviorSubject<string>('FR');
  private translations: { [lang: string]: TranslationSet } = {
    FR: {
      'nav.home': 'Accueil',
      'nav.reservations': 'Réservations',
      'nav.subscriptions': 'Abonnements',
      'nav.about': 'À Propos',
      'nav.contact': 'Contact',
      'nav.login': 'Connexion',
      'nav.signup': 'Inscription',
      'nav.logout': 'Déconnexion',
      'nav.profile': 'Mon Profil',
      'nav.myReservations': 'Mes Réservations',
      'nav.myVehicles': 'Mes Véhicules',
      'nav.language': 'Langue',
      'nav.myAccount': 'Mon compte',
      'home.hero.title': 'Parkiny - Stationnement Intelligent',
      'home.hero.subtitle': 'Projet de fin d\'études développé pour TuniPark',
      'home.hero.subtitle2': 'Système de reconnaissance de plaques d\'immatriculation tunisiennes',
      'home.hero.register': 'S\'inscrire',
      'home.hero.login': 'Connexion'
      // Other translations omitted for brevity
    },
    EN: {
      'nav.home': 'Home',
      'nav.reservations': 'Reservations',
      'nav.subscriptions': 'Subscriptions',
      'nav.about': 'About',
      'nav.contact': 'Contact',
      'nav.login': 'Login',
      'nav.signup': 'Sign Up',
      'nav.logout': 'Logout',
      'nav.profile': 'My Profile',
      'nav.myReservations': 'My Reservations',
      'nav.myVehicles': 'My Vehicles',
      'nav.language': 'Language',
      'nav.myAccount': 'My Account',
      'home.hero.title': 'Parkiny - Smart Parking',
      'home.hero.subtitle': 'Final year project developed for TuniPark',
      'home.hero.subtitle2': 'Tunisian license plate recognition system',
      'home.hero.register': 'Register',
      'home.hero.login': 'Login'
      // Other translations omitted for brevity
    }
  };

  constructor() { }

  getCurrentLanguage(): string {
    return this.currentLang.getValue();
  }

  setLanguage(lang: string): void {
    localStorage.setItem('parkiny_language', lang);
    this.currentLang.next(lang);
  }

  getLanguage(): Observable<string> {
    const savedLang = localStorage.getItem('parkiny_language');
    if (savedLang && (savedLang === 'FR' || savedLang === 'EN')) {
      this.currentLang.next(savedLang);
    }
    return this.currentLang.asObservable();
  }

  translate(key: string, params: { [key: string]: string } = {}): string {
    const lang = this.currentLang.getValue();
    let translation = this.translations[lang][key] || key;
    if (params) {
      Object.keys(params).forEach(param => {
        translation = translation.replace(`{{${param}}}`, params[param]);
      });
    }
    return translation;
  }

  addTranslations(lang: string, newTranslations: TranslationSet): void {
    if (!this.translations[lang]) {
      this.translations[lang] = {};
    }
    this.translations[lang] = { ...this.translations[lang], ...newTranslations };
  }
}