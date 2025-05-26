import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormBuilder, Validators } from '@angular/forms';
import { TranslateService } from '../../services/translate.service';
import { ContentService } from '../../services/content.service';

@Component({
  selector: 'app-contact',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.css']
})
export class ContactComponent implements OnInit {
  contactContent: any = {};
  isLoading = true;
  currentLanguage = 'FR';
  contactForm: FormGroup;
  formSubmitted = false;
  formSuccess = false;
  formError = false;

  constructor(
    private translateService: TranslateService,
    private contentService: ContentService,
    private fb: FormBuilder
  ) {
    // Initialize form
    this.contactForm = this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      subject: ['', Validators.required],
      message: ['', [Validators.required, Validators.minLength(10)]]
    });
  }

  ngOnInit(): void {
    // Subscribe to language changes
    this.translateService.getLanguage().subscribe(lang => {
      this.currentLanguage = lang;
      this.loadContent();
    });
  }

  /**
   * Load contact page content from the content service
   * This allows admin to edit the content
   */
  loadContent(): void {
    this.isLoading = true;
    
    // Get content from service based on current language
    this.contentService.getPageContent('contact', this.currentLanguage).subscribe({
      next: (content) => {
        this.contactContent = content;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading contact content:', error);
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
    this.contactContent = {
      hero: {
        title: this.translateService.translate('contact.hero.title'),
        subtitle: this.translateService.translate('contact.hero.subtitle')
      },
      form: {
        title: this.currentLanguage === 'FR' ? 'Envoyez-nous un message' : 'Send us a message',
        name: this.currentLanguage === 'FR' ? 'Nom complet' : 'Full name',
        email: this.currentLanguage === 'FR' ? 'Adresse email' : 'Email address',
        subject: this.currentLanguage === 'FR' ? 'Sujet' : 'Subject',
        message: this.currentLanguage === 'FR' ? 'Votre message' : 'Your message',
        submit: this.currentLanguage === 'FR' ? 'Envoyer le message' : 'Send message',
        success: this.currentLanguage === 'FR' ? 'Votre message a été envoyé avec succès!' : 'Your message has been sent successfully!',
        error: this.currentLanguage === 'FR' ? 'Une erreur est survenue. Veuillez réessayer.' : 'An error occurred. Please try again.'
      },
      info: {
        title: this.currentLanguage === 'FR' ? 'Informations de contact' : 'Contact information',
        address: {
          title: this.currentLanguage === 'FR' ? 'Adresse' : 'Address',
          value: 'Tunis, Tunisie'
        },
        email: {
          title: this.currentLanguage === 'FR' ? 'Email' : 'Email',
          value: 'contact@parkiny.tn'
        },
        phone: {
          title: this.currentLanguage === 'FR' ? 'Téléphone' : 'Phone',
          value: '+216 XX XXX XXX'
        },
        hours: {
          title: this.currentLanguage === 'FR' ? 'Heures d\'ouverture' : 'Opening hours',
          value: this.currentLanguage === 'FR' ? '24/7 - Service automatisé' : '24/7 - Automated service'
        }
      },
      team: {
        title: this.currentLanguage === 'FR' ? 'Équipe de développement PFE' : 'PFE Development Team',
        description: this.currentLanguage === 'FR' 
          ? 'Projet réalisé dans le cadre de notre formation en informatique, spécialisation en intelligence artificielle et développement web.'
          : 'Project carried out as part of our computer science education, specializing in artificial intelligence and web development.',
        members: [
          {
            name: 'Développeur 1',
            role: this.currentLanguage === 'FR' ? 'Étudiant en informatique' : 'Computer Science Student',
            email: 'dev1@example.com'
          },
          {
            name: 'Développeur 2',
            role: this.currentLanguage === 'FR' ? 'Étudiant en informatique' : 'Computer Science Student',
            email: 'dev2@example.com'
          }
        ]
      },
      faq: {
        title: this.currentLanguage === 'FR' ? 'Questions fréquentes' : 'Frequently Asked Questions',
        items: [
          {
            question: this.currentLanguage === 'FR' ? 'Comment fonctionne la reconnaissance de plaques ?' : 'How does the license plate recognition work?',
            answer: this.currentLanguage === 'FR' 
              ? 'Notre système utilise l\'intelligence artificielle pour détecter et lire les plaques d\'immatriculation tunisiennes, permettant un accès automatisé au parking.'
              : 'Our system uses artificial intelligence to detect and read Tunisian license plates, allowing automated access to the parking.'
          },
          {
            question: this.currentLanguage === 'FR' ? 'Le parking est-il ouvert 24h/24 et 7j/7 ?' : 'Is the parking open 24/7?',
            answer: this.currentLanguage === 'FR' 
              ? 'Oui, notre système fonctionne en continu, permettant l\'accès au parking à tout moment pour les utilisateurs enregistrés.'
              : 'Yes, our system operates continuously, allowing access to the parking at any time for registered users.'
          },
          {
            question: this.currentLanguage === 'FR' ? 'Comment puis-je m\'abonner ?' : 'How can I subscribe?',
            answer: this.currentLanguage === 'FR' 
              ? 'Vous pouvez vous inscrire via notre application et choisir l\'abonnement qui correspond à vos besoins dans la section Abonnements.'
              : 'You can register via our application and choose the subscription that matches your needs in the Subscriptions section.'
          }
        ]
      }
    };
  }

  /**
   * Submit contact form
   */
  onSubmit(): void {
    this.formSubmitted = true;
    
    if (this.contactForm.valid) {
      // In a real implementation, this would send the form data to a backend API
      // For demo purposes, we'll simulate a successful submission
      setTimeout(() => {
        this.formSuccess = true;
        this.formError = false;
        this.contactForm.reset();
        this.formSubmitted = false;
        
        // Reset success message after 5 seconds
        setTimeout(() => {
          this.formSuccess = false;
        }, 5000);
      }, 1500);
    }
  }

  /**
   * Translate a key using the translation service
   */
  translate(key: string): string {
    return this.translateService.translate(key);
  }
}
