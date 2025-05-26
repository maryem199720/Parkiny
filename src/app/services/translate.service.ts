import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface TranslationSet {
  [key: string]: string;
}

@Injectable({
  providedIn: 'root'
})
export class TranslateService {
  private currentLang = new BehaviorSubject<string>('FR');
  private translations: { [lang: string]: TranslationSet } = {
    FR: {
      // Navigation
      'nav.home': 'Accueil',
      'nav.reservations': 'Réservations',
      'nav.subscriptions': 'Abonnements',
      'nav.about': 'À Propos',
      'nav.contact': 'Contact',
      'nav.login': 'Connexion',
      'nav.signup': 'S\'inscrire',
      'nav.logout': 'Déconnexion',
      'nav.profile': 'Mon Profil',
      'nav.myReservations': 'Mes Réservations',
      'nav.myVehicles': 'Mes Véhicules',
      'nav.language': 'Langue',
      'nav.myAccount': 'Mon compte',
      
      // Home Page
      'home.hero.title': 'Parkiny - Stationnement Intelligent',
      'home.hero.subtitle': 'Projet de fin d\'études développé pour TuniPark',
      'home.hero.subtitle2': 'Système de reconnaissance de plaques d\'immatriculation tunisiennes',
      'home.hero.register': 'S\'inscrire',
      'home.hero.login': 'Connexion',
      
      'home.info.title': 'Parkiny - Solution de Stationnement Intelligent',
      'home.info.subtitle': 'Développé pour TuniPark, ce système transforme l\'expérience de stationnement grâce à la reconnaissance automatique des plaques d\'immatriculation tunisiennes.',
      
      'home.how.title': 'Comment fonctionne Parkiny?',
      'home.how.ai.title': 'Détection IA Tunisienne',
      'home.how.ai.desc': 'Notre système utilise une technologie d\'IA développée spécifiquement pour reconnaître les plaques d\'immatriculation tunisiennes, avec une précision exceptionnelle.',
      'home.how.realtime.title': 'Disponibilité en Temps Réel',
      'home.how.realtime.desc': 'Consultez la disponibilité des places de stationnement en temps réel via notre application mobile avant même de quitter votre domicile.',
      'home.how.security.title': 'Sécurité Renforcée',
      'home.how.security.desc': 'Accès exclusif pour les utilisateurs autorisés avec surveillance 24/7, garantissant la sécurité de votre véhicule à tout moment.',
      'home.how.app.title': 'Application Mobile Intuitive',
      'home.how.app.desc': 'Gérez vos réservations, consultez votre historique et recevez des notifications importantes directement sur votre smartphone.',
      
      'home.parking.title': 'Statut du Parking en Temps Réel',
      'home.parking.standard': 'Parking Standard',
      'home.parking.vip': 'Zone VIP',
      'home.parking.reserved': 'Zone Réservée',
      'home.parking.available': 'Disponible',
      'home.parking.limited': 'Limité',
      'home.parking.full': 'Complet',
      'home.parking.spots': 'Places disponibles:',
      'home.parking.reserve': 'Réserver une place',
      'home.parking.noSpots': 'Aucune place disponible',
      
      'home.subscriptions.title': 'Nos Abonnements',
      'home.subscriptions.subtitle': 'Choisissez l\'abonnement qui correspond à vos besoins de stationnement.',
      'home.subscriptions.dynamic': '* Les plans d\'abonnement sont chargés dynamiquement depuis notre backend',
      'home.subscriptions.basic.title': 'Basique',
      'home.subscriptions.basic.subtitle': 'Parfait pour un usage occasionnel',
      'home.subscriptions.premium.title': 'Premium',
      'home.subscriptions.premium.subtitle': 'Le choix le plus populaire',
      'home.subscriptions.enterprise.title': 'Entreprise',
      'home.subscriptions.enterprise.subtitle': 'Pour les besoins professionnels',
      'home.subscriptions.month': '/mois',
      'home.subscriptions.billed': 'Facturé mensuellement',
      'home.subscriptions.choose': 'Choisir ce plan',
      'home.subscriptions.specific': 'Vous avez des besoins spécifiques ?',
      'home.subscriptions.contact': 'Contactez-nous pour une solution personnalisée',
      
      // Features section
      'home.features.title': 'Fonctionnalités Développées',
      'home.features.subtitle': 'Découvrez les fonctionnalités clés développées pour TuniPark dans le cadre de ce projet de fin d\'études.',
      'home.features.ai.title': 'Analyse alimentée par l\'IA',
      'home.features.ai.desc': 'Détectez automatiquement les habitudes de stationnement et proposez des suggestions instantanées de disponibilité des places.',
      'home.features.recognition.title': 'Reconnaissance des véhicules',
      'home.features.recognition.desc': 'Détectez et identifiez avec précision les véhicules grâce à notre technologie avancée de vision par ordinateur.',
      'home.features.dashboard.title': 'Tableau de bord d\'analyse',
      'home.features.dashboard.desc': 'Obtenez des informations précieuses sur les habitudes d\'utilisation du stationnement grâce à une visualisation complète des données.',
      'home.features.storage.title': 'Stockage Local Sécurisé',
      'home.features.storage.desc': 'Toutes les données sont stockées localement avec un chiffrement de pointe pour garantir la confidentialité et la sécurité.',
      
      // AI Technology section
      'home.tech.title': 'Technologie IA Tunisienne',
      'home.tech.desc1': 'Notre système de reconnaissance de plaques d\'immatriculation est spécialement conçu pour les plaques tunisiennes, avec une précision exceptionnelle pour tous les formats (civils, taxis, officiels, etc.).',
      'home.tech.desc2': 'Développé dans le cadre d\'un projet de fin d\'études, ce système s\'adapte parfaitement aux conditions spécifiques du pays et offre une solution sur mesure pour les besoins de stationnement privé de TuniPark.',
      'home.tech.learnMore': 'En savoir plus',
      'home.tech.contact': 'Nous contacter',
      
      // Analytics section
      'home.analytics.title': 'Occupation et efficacité',
      'home.analytics.subtitle': 'Notre tableau de bord d\'analyse complet fournit des informations précieuses sur l\'occupation du stationnement et l\'efficacité de l\'installation.',
      'home.analytics.occupation.title': 'Taux d\'occupation',
      'home.analytics.occupation.desc': 'Suivez en temps réel l\'utilisation des places de parking pour optimiser l\'allocation des espaces.',
      'home.analytics.duration.title': 'Durée moyenne',
      'home.analytics.duration.desc': 'Analysez la durée moyenne de stationnement pour mieux gérer les rotations.',
      'home.analytics.peak.title': 'Heures de pointe',
      'home.analytics.peak.desc': 'Identifiez les périodes de forte affluence pour planifier vos ressources.',
      
      // Location section
      'home.location.title': 'Emplacement du client',
      
      // Testimonials section
      'home.testimonials.title': 'Témoignages Utilisateurs',
      'home.testimonials.subtitle': 'Retours des utilisateurs lors de nos tests de la solution.',
      
      // CTA section
      'home.cta.title': 'Projet de Fin d\'Études - Juin 2025',
      'home.cta.subtitle': 'Développé par des étudiants en informatique pour répondre aux besoins de TuniPark.',
      'home.cta.demo': 'Tester la démo',
      
      // Footer
      'footer.description': 'Projet de fin d\'études - Solution de stationnement intelligent avec reconnaissance de plaques d\'immatriculation.',
      'footer.features': 'Fonctionnalités',
      'footer.features.recognition': 'Reconnaissance de plaques',
      'footer.features.subscriptions': 'Gestion des abonnements',
      'footer.features.dashboard': 'Tableau de bord d\'analyse',
      'footer.features.mobile': 'Application Mobile',
      'footer.features.api': 'API et intégrations',
      'footer.resources': 'Ressources',
      'footer.resources.docs': 'Documentation',
      'footer.resources.specs': 'Cahier des charges',
      'footer.resources.report': 'Rapport de projet',
      'footer.resources.presentation': 'Présentation',
      'footer.resources.demo': 'Démonstration',
      'footer.project': 'Projet',
      'footer.project.about': 'À propos du projet',
      'footer.project.team': 'Équipe de développement',
      'footer.project.client': 'Client: TuniPark',
      'footer.project.contact': 'Contact',
      'footer.project.legal': 'Mentions légales',
      'footer.copyright': '© 2025 Parkiny - Projet de Fin d\'Études. Tous droits réservés.',
      'footer.payment': 'Carte Bancaire',
      'footer.terms': 'Termes',
      'footer.privacy': 'Confidentialité',
      'footer.cookies': 'Cookies',
      
      // About page
      'about.hero.title': 'À Propos de Parkiny',
      'about.hero.subtitle': 'Un projet de fin d\'études développé pour TuniPark',
      
      // Contact page
      'contact.hero.title': 'Contactez-Nous',
      'contact.hero.subtitle': 'Nous sommes là pour répondre à vos questions',
      
      // Common buttons and labels
      'common.submit': 'Soumettre',
      'common.cancel': 'Annuler',
      'common.save': 'Enregistrer',
      'common.edit': 'Modifier',
      'common.delete': 'Supprimer',
      'common.back': 'Retour',
      'common.next': 'Suivant',
      'common.loading': 'Chargement...',
      'common.success': 'Succès',
      'common.error': 'Erreur',
      'common.required': 'Requis',
      'common.optional': 'Optionnel',
      'common.search': 'Rechercher',
      'common.filter': 'Filtrer',
      'common.sort': 'Trier',
      'common.view': 'Voir',
      'common.details': 'Détails',
      'common.more': 'Plus',
      'common.less': 'Moins',
      'common.all': 'Tous',
      'common.none': 'Aucun',
      'common.yes': 'Oui',
      'common.no': 'Non',
      'common.or': 'ou',
      'common.and': 'et',
    },
    EN: {
      // Navigation
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
      
      // Home Page
      'home.hero.title': 'Parkiny - Smart Parking',
      'home.hero.subtitle': 'Final year project developed for TuniPark',
      'home.hero.subtitle2': 'Tunisian license plate recognition system',
      'home.hero.register': 'Register',
      'home.hero.login': 'Login',
      
      'home.info.title': 'Parkiny - Smart Parking Solution',
      'home.info.subtitle': 'Developed for TuniPark, this system transforms the parking experience through automatic recognition of Tunisian license plates.',
      
      'home.how.title': 'How does Parkiny work?',
      'home.how.ai.title': 'Tunisian AI Detection',
      'home.how.ai.desc': 'Our system uses AI technology specifically developed to recognize Tunisian license plates with exceptional accuracy.',
      'home.how.realtime.title': 'Real-Time Availability',
      'home.how.realtime.desc': 'Check parking space availability in real-time via our mobile app before even leaving your home.',
      'home.how.security.title': 'Enhanced Security',
      'home.how.security.desc': 'Exclusive access for authorized users with 24/7 surveillance, ensuring your vehicle\'s security at all times.',
      'home.how.app.title': 'Intuitive Mobile App',
      'home.how.app.desc': 'Manage your reservations, check your history, and receive important notifications directly on your smartphone.',
      
      'home.parking.title': 'Real-Time Parking Status',
      'home.parking.standard': 'Standard Parking',
      'home.parking.vip': 'VIP Zone',
      'home.parking.reserved': 'Reserved Zone',
      'home.parking.available': 'Available',
      'home.parking.limited': 'Limited',
      'home.parking.full': 'Full',
      'home.parking.spots': 'Available spots:',
      'home.parking.reserve': 'Reserve a spot',
      'home.parking.noSpots': 'No spots available',
      
      'home.subscriptions.title': 'Our Subscriptions',
      'home.subscriptions.subtitle': 'Choose the subscription that matches your parking needs.',
      'home.subscriptions.dynamic': '* Subscription plans are dynamically loaded from our backend',
      'home.subscriptions.basic.title': 'Basic',
      'home.subscriptions.basic.subtitle': 'Perfect for occasional use',
      'home.subscriptions.premium.title': 'Premium',
      'home.subscriptions.premium.subtitle': 'The most popular choice',
      'home.subscriptions.enterprise.title': 'Enterprise',
      'home.subscriptions.enterprise.subtitle': 'For business needs',
      'home.subscriptions.month': '/month',
      'home.subscriptions.billed': 'Billed monthly',
      'home.subscriptions.choose': 'Choose this plan',
      'home.subscriptions.specific': 'Do you have specific needs?',
      'home.subscriptions.contact': 'Contact us for a customized solution',
      
      // Features section
      'home.features.title': 'Developed Features',
      'home.features.subtitle': 'Discover the key features developed for TuniPark as part of this final year project.',
      'home.features.ai.title': 'AI-Powered Analysis',
      'home.features.ai.desc': 'Automatically detect parking patterns and provide instant suggestions for space availability.',
      'home.features.recognition.title': 'Vehicle Recognition',
      'home.features.recognition.desc': 'Accurately detect and identify vehicles using our advanced computer vision technology.',
      'home.features.dashboard.title': 'Analytics Dashboard',
      'home.features.dashboard.desc': 'Gain valuable insights into parking usage habits through comprehensive data visualization.',
      'home.features.storage.title': 'Secure Local Storage',
      'home.features.storage.desc': 'All data is stored locally with state-of-the-art encryption to ensure privacy and security.',
      
      // AI Technology section
      'home.tech.title': 'Tunisian AI Technology',
      'home.tech.desc1': 'Our license plate recognition system is specifically designed for Tunisian plates, with exceptional accuracy for all formats (civilian, taxi, official, etc.).',
      'home.tech.desc2': 'Developed as part of a final year project, this system perfectly adapts to the country\'s specific conditions and offers a tailored solution for TuniPark\'s private parking needs.',
      'home.tech.learnMore': 'Learn More',
      'home.tech.contact': 'Contact Us',
      
      // Analytics section
      'home.analytics.title': 'Occupancy and Efficiency',
      'home.analytics.subtitle': 'Our comprehensive analytics dashboard provides valuable information on parking occupancy and facility efficiency.',
      'home.analytics.occupation.title': 'Occupancy Rate',
      'home.analytics.occupation.desc': 'Track real-time usage of parking spaces to optimize space allocation.',
      'home.analytics.duration.title': 'Average Duration',
      'home.analytics.duration.desc': 'Analyze average parking duration to better manage rotations.',
      'home.analytics.peak.title': 'Peak Hours',
      'home.analytics.peak.desc': 'Identify high-traffic periods to plan your resources.',
      
      // Location section
      'home.location.title': 'Client Location',
      
      // Testimonials section
      'home.testimonials.title': 'User Testimonials',
      'home.testimonials.subtitle': 'Feedback from users during our solution testing.',
      
      // CTA section
      'home.cta.title': 'Final Year Project - June 2025',
      'home.cta.subtitle': 'Developed by computer science students to meet TuniPark\'s needs.',
      'home.cta.demo': 'Test the demo',
      
      // Footer
      'footer.description': 'Final year project - Smart parking solution with license plate recognition.',
      'footer.features': 'Features',
      'footer.features.recognition': 'Plate Recognition',
      'footer.features.subscriptions': 'Subscription Management',
      'footer.features.dashboard': 'Analytics Dashboard',
      'footer.features.mobile': 'Mobile App',
      'footer.features.api': 'API & Integrations',
      'footer.resources': 'Resources',
      'footer.resources.docs': 'Documentation',
      'footer.resources.specs': 'Specifications',
      'footer.resources.report': 'Project Report',
      'footer.resources.presentation': 'Presentation',
      'footer.resources.demo': 'Demonstration',
      'footer.project': 'Project',
      'footer.project.about': 'About the project',
      'footer.project.team': 'Development Team',
      'footer.project.client': 'Client: TuniPark',
      'footer.project.contact': 'Contact',
      'footer.project.legal': 'Legal Notice',
      'footer.copyright': '© 2025 Parkiny - Final Year Project. All rights reserved.',
      'footer.payment': 'Bank Card',
      'footer.terms': 'Terms',
      'footer.privacy': 'Privacy',
      'footer.cookies': 'Cookies',
      
      // About page
      'about.hero.title': 'About Parkiny',
      'about.hero.subtitle': 'A final year project developed for TuniPark',
      
      // Contact page
      'contact.hero.title': 'Contact Us',
      'contact.hero.subtitle': 'We\'re here to answer your questions',
      
      // Common buttons and labels
      'common.submit': 'Submit',
      'common.cancel': 'Cancel',
      'common.save': 'Save',
      'common.edit': 'Edit',
      'common.delete': 'Delete',
      'common.back': 'Back',
      'common.next': 'Next',
      'common.loading': 'Loading...',
      'common.success': 'Success',
      'common.error': 'Error',
      'common.required': 'Required',
      'common.optional': 'Optional',
      'common.search': 'Search',
      'common.filter': 'Filter',
      'common.sort': 'Sort',
      'common.view': 'View',
      'common.details': 'Details',
      'common.more': 'More',
      'common.less': 'Less',
      'common.all': 'All',
      'common.none': 'None',
      'common.yes': 'Yes',
      'common.no': 'No',
      'common.or': 'or',
      'common.and': 'and',
    }
  };

  constructor() { }

  /**
   * Get the current language
   */
  getCurrentLanguage(): string {
    return this.currentLang.getValue();
  }

  /**
   * Set the current language
   * @param lang Language code (FR, EN)
   */
  setLanguage(lang: string): void {
    // Store in localStorage for persistence
    localStorage.setItem('parkiny_language', lang);
    this.currentLang.next(lang);
  }

  /**
   * Get language as observable for reactive components
   */
  getLanguage(): Observable<string> {
    // Check localStorage first for saved preference
    const savedLang = localStorage.getItem('parkiny_language');
    if (savedLang && (savedLang === 'FR' || savedLang === 'EN')) {
      this.currentLang.next(savedLang);
    }
    return this.currentLang.asObservable();
  }

  /**
   * Translate a key to the current language
   * @param key Translation key
   * @param params Optional parameters for string interpolation
   */
  translate(key: string, params: { [key: string]: string } = {}): string {
    const lang = this.currentLang.getValue();
    
    // Get translation or fallback to key if not found
    let translation = this.translations[lang][key] || key;
    
    // Replace parameters if any
    if (params) {
      Object.keys(params).forEach(param => {
        translation = translation.replace(`{{${param}}}`, params[param]);
      });
    }
    
    return translation;
  }

  /**
   * Add or update translations
   * @param lang Language code
   * @param translations Object with key-value pairs of translations
   */
  addTranslations(lang: string, newTranslations: TranslationSet): void {
    if (!this.translations[lang]) {
      this.translations[lang] = {};
    }
    
    this.translations[lang] = {
      ...this.translations[lang],
      ...newTranslations
    };
  }
}
