import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslateService } from '../../services/translate.service';
import { ContentService } from '../../services/content.service';

@Component({
  selector: 'app-faq',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './faq.component.html',
  styleUrls: ['./faq.component.css']
})
export class FaqComponent implements OnInit {
  faqContent: any = {};
  isLoading = true;
  currentLanguage = 'FR';
  activeCategory = 'all';
  
  constructor(
    private translateService: TranslateService,
    private contentService: ContentService
  ) { }

  ngOnInit(): void {
    // Subscribe to language changes
    this.translateService.getLanguage().subscribe(lang => {
      this.currentLanguage = lang;
      this.loadContent();
    });
  }

  /**
   * Load FAQ content from the content service
   * This allows admin to edit the content
   */
  loadContent(): void {
    this.isLoading = true;
    
    // Get content from service based on current language
    this.contentService.getPageContent('faq', this.currentLanguage).subscribe({
      next: (content) => {
        this.faqContent = content;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading FAQ content:', error);
        // Fallback to default content if API fails
        this.loadDefaultContent();
        this.isLoading = false;
      }
    });
  }

  /**
   * Fallback content if API fails
   */
  loadDefaultContent(): void {
    this.faqContent = {
      hero: {
        title: this.currentLanguage === 'FR' ? 'Questions Fréquemment Posées' : 'Frequently Asked Questions',
        subtitle: this.currentLanguage === 'FR' ? 'Trouvez des réponses à vos questions sur notre service de stationnement intelligent' : 'Find answers to your questions about our smart parking service'
      },
      categories: [
        {
          id: 'general',
          name: this.currentLanguage === 'FR' ? 'Général' : 'General'
        },
        {
          id: 'account',
          name: this.currentLanguage === 'FR' ? 'Compte & Abonnements' : 'Account & Subscriptions'
        },
        {
          id: 'parking',
          name: this.currentLanguage === 'FR' ? 'Stationnement' : 'Parking'
        },
        {
          id: 'technology',
          name: this.currentLanguage === 'FR' ? 'Technologie' : 'Technology'
        },
        {
          id: 'billing',
          name: this.currentLanguage === 'FR' ? 'Facturation' : 'Billing'
        }
      ],
      questions: [
        {
          id: 1,
          category: 'general',
          question: this.currentLanguage === 'FR' ? 'Qu\'est-ce que Parkiny ?' : 'What is Parkiny?',
          answer: this.currentLanguage === 'FR' 
            ? 'Parkiny est un système de stationnement intelligent développé dans le cadre d\'un projet de fin d\'études pour TuniPark. Il utilise la reconnaissance automatique des plaques d\'immatriculation tunisiennes pour faciliter l\'accès au parking et améliorer l\'expérience utilisateur.'
            : 'Parkiny is a smart parking system developed as a final year project for TuniPark. It uses automatic recognition of Tunisian license plates to facilitate parking access and improve the user experience.'
        },
        {
          id: 2,
          category: 'general',
          question: this.currentLanguage === 'FR' ? 'Où est situé le parking ?' : 'Where is the parking located?',
          answer: this.currentLanguage === 'FR' 
            ? 'Notre parking est situé à Tunis, Tunisie. Vous pouvez trouver l\'adresse exacte et les directions sur la page Contact.'
            : 'Our parking is located in Tunis, Tunisia. You can find the exact address and directions on the Contact page.'
        },
        {
          id: 3,
          category: 'general',
          question: this.currentLanguage === 'FR' ? 'Quelles sont les heures d\'ouverture ?' : 'What are the opening hours?',
          answer: this.currentLanguage === 'FR' 
            ? 'Notre parking est accessible 24h/24 et 7j/7 pour les utilisateurs enregistrés avec un abonnement actif.'
            : 'Our parking is accessible 24/7 for registered users with an active subscription.'
        },
        {
          id: 4,
          category: 'account',
          question: this.currentLanguage === 'FR' ? 'Comment créer un compte ?' : 'How do I create an account?',
          answer: this.currentLanguage === 'FR' 
            ? 'Vous pouvez créer un compte en cliquant sur le bouton "S\'inscrire" dans la barre de navigation. Vous devrez fournir votre nom, adresse e-mail, et créer un mot de passe. Une vérification par e-mail sera envoyée pour confirmer votre compte.'
            : 'You can create an account by clicking the "Sign Up" button in the navigation bar. You will need to provide your name, email address, and create a password. An email verification will be sent to confirm your account.'
        },
        {
          id: 5,
          category: 'account',
          question: this.currentLanguage === 'FR' ? 'Quels types d\'abonnements proposez-vous ?' : 'What types of subscriptions do you offer?',
          answer: this.currentLanguage === 'FR' 
            ? 'Nous proposons trois types d\'abonnements : Basique (accès limité en semaine), Premium (accès 24/7 avec 2 véhicules), et Entreprise (jusqu\'à 5 véhicules avec fonctionnalités avancées). Consultez la page Abonnements pour plus de détails.'
            : 'We offer three types of subscriptions: Basic (limited weekday access), Premium (24/7 access with 2 vehicles), and Enterprise (up to 5 vehicles with advanced features). Check the Subscriptions page for more details.'
        },
        {
          id: 6,
          category: 'account',
          question: this.currentLanguage === 'FR' ? 'Comment puis-je modifier mes informations personnelles ?' : 'How can I edit my personal information?',
          answer: this.currentLanguage === 'FR' 
            ? 'Vous pouvez modifier vos informations personnelles en vous connectant à votre compte et en accédant à la section "Mon Profil". Là, vous pourrez mettre à jour votre nom, adresse e-mail, mot de passe et autres détails.'
            : 'You can edit your personal information by logging into your account and accessing the "My Profile" section. There, you can update your name, email address, password, and other details.'
        },
        {
          id: 7,
          category: 'parking',
          question: this.currentLanguage === 'FR' ? 'Comment fonctionne la réservation de place ?' : 'How does spot reservation work?',
          answer: this.currentLanguage === 'FR' 
            ? 'Les abonnés Premium et Entreprise peuvent réserver une place de parking à l\'avance via l\'application. Sélectionnez simplement la date et l\'heure souhaitées, et une place vous sera garantie pendant cette période.'
            : 'Premium and Enterprise subscribers can reserve a parking spot in advance through the application. Simply select the desired date and time, and a spot will be guaranteed for you during that period.'
        },
        {
          id: 8,
          category: 'parking',
          question: this.currentLanguage === 'FR' ? 'Que se passe-t-il si je dépasse mon temps de stationnement réservé ?' : 'What happens if I exceed my reserved parking time?',
          answer: this.currentLanguage === 'FR' 
            ? 'Des frais supplémentaires peuvent s\'appliquer si vous dépassez votre temps de stationnement réservé. Les tarifs de dépassement varient selon votre type d\'abonnement. Vous recevrez une notification avant l\'expiration de votre réservation.'
            : 'Additional fees may apply if you exceed your reserved parking time. Overtime rates vary depending on your subscription type. You will receive a notification before your reservation expires.'
        },
        {
          id: 9,
          category: 'technology',
          question: this.currentLanguage === 'FR' ? 'Comment fonctionne la reconnaissance de plaques d\'immatriculation ?' : 'How does license plate recognition work?',
          answer: this.currentLanguage === 'FR' 
            ? 'Notre système utilise une technologie d\'IA combinant YOLO pour la détection des plaques et EasyOCR pour la lecture des caractères. Il est spécialement adapté aux formats de plaques tunisiennes et fonctionne dans diverses conditions d\'éclairage et météorologiques.'
            : 'Our system uses AI technology combining YOLO for plate detection and EasyOCR for character reading. It is specially adapted to Tunisian plate formats and works in various lighting and weather conditions.'
        },
        {
          id: 10,
          category: 'technology',
          question: this.currentLanguage === 'FR' ? 'Mes données sont-elles sécurisées ?' : 'Is my data secure?',
          answer: this.currentLanguage === 'FR' 
            ? 'Oui, nous prenons la sécurité des données très au sérieux. Toutes les informations personnelles et les données de véhicules sont cryptées et stockées en toute sécurité. Nous ne partageons pas vos données avec des tiers sans votre consentement explicite.'
            : 'Yes, we take data security very seriously. All personal information and vehicle data are encrypted and securely stored. We do not share your data with third parties without your explicit consent.'
        },
        {
          id: 11,
          category: 'billing',
          question: this.currentLanguage === 'FR' ? 'Quels modes de paiement acceptez-vous ?' : 'What payment methods do you accept?',
          answer: this.currentLanguage === 'FR' 
            ? 'Nous acceptons les paiements par carte bancaire tunisienne. Le paiement est sécurisé et traité via notre passerelle de paiement certifiée.'
            : 'We accept payments via Tunisian bank cards. Payment is secure and processed through our certified payment gateway.'
        },
        {
          id: 12,
          category: 'billing',
          question: this.currentLanguage === 'FR' ? 'Comment puis-je obtenir une facture ?' : 'How can I get an invoice?',
          answer: this.currentLanguage === 'FR' 
            ? 'Les factures sont automatiquement générées et envoyées à votre adresse e-mail après chaque paiement. Vous pouvez également accéder à toutes vos factures dans la section "Historique de paiement" de votre compte.'
            : 'Invoices are automatically generated and sent to your email address after each payment. You can also access all your invoices in the "Payment History" section of your account.'
        },
        {
          id: 13,
          category: 'billing',
          question: this.currentLanguage === 'FR' ? 'Comment puis-je annuler mon abonnement ?' : 'How can I cancel my subscription?',
          answer: this.currentLanguage === 'FR' 
            ? 'Vous pouvez annuler votre abonnement à tout moment en accédant à la section "Abonnements" de votre compte. L\'annulation prendra effet à la fin de votre période de facturation en cours. Aucun remboursement partiel n\'est disponible pour les périodes non utilisées.'
            : 'You can cancel your subscription at any time by accessing the "Subscriptions" section of your account. Cancellation will take effect at the end of your current billing period. No partial refunds are available for unused periods.'
        }
      ]
    };
  }

  /**
   * Filter questions by category
   * @param categoryId Category ID to filter by, or 'all' for all questions
   */
  filterByCategory(categoryId: string): void {
    this.activeCategory = categoryId;
  }

  /**
   * Get filtered questions based on active category
   */
  get filteredQuestions(): any[] {
    if (!this.faqContent.questions) return [];
    
    if (this.activeCategory === 'all') {
      return this.faqContent.questions;
    }
    
    return this.faqContent.questions.filter((q: any) => q.category === this.activeCategory);
  }

  /**
   * Toggle question expansion
   * @param question Question object to toggle
   */
  toggleQuestion(question: any): void {
    question.isExpanded = !question.isExpanded;
  }

  /**
   * Translate a key using the translation service
   */
  translate(key: string): string {
    return this.translateService.translate(key);
  }
}
