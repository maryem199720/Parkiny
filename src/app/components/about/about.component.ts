/* About Us Page Component */
import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink, RouterModule } from '@angular/router';
import { TranslateService } from '../../services/translate.service';
import { ContentService } from '../../services/content.service';

@Component({
  selector: 'app-about',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './about.component.html',
  styleUrls: ['./about.component.css']
})
export class AboutComponent implements OnInit {
  aboutContent: any = {};
  isLoading = true;
  currentLanguage = 'FR';

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
   * Load about page content from the content service
   * This allows admin to edit the content
   */
  loadContent(): void {
    this.isLoading = true;
    
    // Get content from service based on current language
    this.contentService.getPageContent('about', this.currentLanguage).subscribe({
      next: (content) => {
        this.aboutContent = content;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading about content:', error);
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
    this.aboutContent = {
      hero: {
        title: this.translateService.translate('about.hero.title'),
        subtitle: this.translateService.translate('about.hero.subtitle')
      },
      client: {
        name: 'TuniPark',
        founded: '2020',
        location: 'Tunis, Tunisie',
        description: this.currentLanguage === 'FR' 
          ? 'TuniPark est une entreprise tunisienne spécialisée dans la gestion de parkings privés, cherchant à moderniser l\'expérience de stationnement grâce à des solutions technologiques innovantes.'
          : 'TuniPark is a Tunisian company specializing in private parking management, seeking to modernize the parking experience through innovative technological solutions.'
      },
      project: {
        title: this.currentLanguage === 'FR' ? 'Projet de Fin d\'Études - Juin 2025' : 'Final Year Project - June 2025',
        description: this.currentLanguage === 'FR'
          ? 'Parkiny est un projet de fin d\'études développé pour répondre aux besoins spécifiques de TuniPark. Notre mission était de créer une solution de stationnement intelligent utilisant la reconnaissance de plaques d\'immatriculation tunisiennes pour automatiser et sécuriser l\'accès au parking.'
          : 'Parkiny is a final year project developed to meet the specific needs of TuniPark. Our mission was to create a smart parking solution using Tunisian license plate recognition to automate and secure parking access.',
        features: this.currentLanguage === 'FR'
          ? ['Reconnaissance automatique des plaques tunisiennes', 'Fonctionnement 24/7', 'Tableau de bord d\'analyse', 'Application mobile pour les utilisateurs', 'Gestion des abonnements']
          : ['Automatic recognition of Tunisian plates', '24/7 operation', 'Analytics dashboard', 'Mobile app for users', 'Subscription management']
      },
      team: {
        title: this.currentLanguage === 'FR' ? 'Notre Équipe' : 'Our Team',
        members: [
          {
            name: this.currentLanguage === 'FR' ? 'Équipe de développement' : 'Development Team',
            role: this.currentLanguage === 'FR' ? 'Étudiants en informatique' : 'Computer Science Students',
            bio: this.currentLanguage === 'FR'
              ? 'Projet réalisé dans le cadre de notre formation en informatique, spécialisation en intelligence artificielle et développement web.'
              : 'Project carried out as part of our computer science education, specializing in artificial intelligence and web development.'
          }
        ]
      },
      technology: {
        title: this.currentLanguage === 'FR' ? 'Notre Technologie' : 'Our Technology',
        description: this.currentLanguage === 'FR'
          ? 'Au cœur de Parkiny se trouve un système de reconnaissance de plaques d\'immatriculation spécialement conçu pour le format tunisien. Cette technologie combine la vision par ordinateur (YOLO) pour la détection des plaques et l\'OCR (EasyOCR) pour la lecture des caractères.'
          : 'At the heart of Parkiny is a license plate recognition system specially designed for the Tunisian format. This technology combines computer vision (YOLO) for plate detection and OCR (EasyOCR) for character reading.',
        features: this.currentLanguage === 'FR'
          ? ['Adapté aux formats tunisiens', 'Haute précision même dans des conditions difficiles', 'Traitement en temps réel', 'Sécurité et confidentialité des données']
          : ['Adapted to Tunisian formats', 'High accuracy even in difficult conditions', 'Real-time processing', 'Data security and confidentiality']
      },
      timeline: {
        title: this.currentLanguage === 'FR' ? 'Notre Parcours' : 'Our Journey',
        events: [
          {
            date: this.currentLanguage === 'FR' ? 'Janvier 2025' : 'January 2025',
            title: this.currentLanguage === 'FR' ? 'Début du projet' : 'Project start',
            description: this.currentLanguage === 'FR' ? 'Analyse des besoins et spécifications' : 'Needs analysis and specifications'
          },
          {
            date: this.currentLanguage === 'FR' ? 'Mars 2025' : 'March 2025',
            title: this.currentLanguage === 'FR' ? 'Développement du prototype' : 'Prototype development',
            description: this.currentLanguage === 'FR' ? 'Premier modèle fonctionnel de reconnaissance de plaques' : 'First functional license plate recognition model'
          },
          {
            date: this.currentLanguage === 'FR' ? 'Mai 2025' : 'May 2025',
            title: this.currentLanguage === 'FR' ? 'Tests et optimisation' : 'Testing and optimization',
            description: this.currentLanguage === 'FR' ? 'Amélioration de la précision et des performances' : 'Improving accuracy and performance'
          },
          {
            date: this.currentLanguage === 'FR' ? 'Juin 2025' : 'June 2025',
            title: this.currentLanguage === 'FR' ? 'Présentation finale' : 'Final presentation',
            description: this.currentLanguage === 'FR' ? 'Démonstration du système complet' : 'Demonstration of the complete system'
          }
        ]
      }
    };
  }

  /**
   * Translate a key using the translation service
   */
  translate(key: string): string {
    return this.translateService.translate(key);
  }
}
