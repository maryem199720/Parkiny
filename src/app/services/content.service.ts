import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

// Interface simple pour le contenu (peut être enrichie)
export interface PageContent {
  title: string;
  paragraphs: string[];
  // Ajoutez d'autres champs si nécessaire (ex: contactInfo, mapUrl)
}

@Injectable({
  providedIn: 'root'
})
export class ContentService {

  // Contenu codé en dur pour l'exemple PFE
  private contentData: { [lang: string]: { [page: string]: PageContent } } = {
    'fr': {
      'about': {
        title: 'À Propos de Parkiny',
        paragraphs: [
          'Parkiny est bien plus qu\'un simple parking. C\'est une solution innovante conçue pour transformer votre expérience de stationnement en Tunisie. Né d\'un projet de fin d\'études (PFE) ambitieux, Parkiny vise à démontrer comment la technologie peut simplifier le quotidien des automobilistes en offrant un service de parking sécurisé, pratique et moderne.',
          'Notre mission est de fluidifier et de sécuriser le stationnement dans les zones urbaines denses. Nous croyons en l\'utilisation intelligente de la technologie pour offrir une expérience utilisateur sans tracas.',
          'Actuellement, Parkiny opère sur un site unique, stratégiquement situé à [Localisation Fictive, Tunis]. Notre parking privé est ouvert 24/7 et offre une sécurité renforcée.'
        ]
      },
      'contact': {
        title: 'Contactez Parkiny',
        paragraphs: [
          'Vous avez une question ou besoin d\'assistance ? Contactez-nous :',
          'Adresse : [Localisation Fictive, Tunis]',
          'Téléphone : [+216 XX XXX XXX]',
          'Email : [contact@parkiny-pfe.tn]',
          'Le parking est ouvert 24/7.'
        ]
      }
    },
    'en': {
      'about': {
        title: 'About Parkiny',
        paragraphs: [
          'Parkiny is much more than just a parking lot. It\'s an innovative solution designed to transform your parking experience in Tunisia. Born from an ambitious final year project (PFE), Parkiny aims to demonstrate how technology can simplify drivers\' daily lives by offering a secure, practical, and modern parking service.',
          'Our mission is to streamline and secure parking in dense urban areas. We believe in the smart use of technology to provide a hassle-free user experience.',
          'Currently, Parkiny operates at a single site, strategically located in [Fictional Location, Tunis]. Our private parking is open 24/7 and offers enhanced security.'
        ]
      },
      'contact': {
        title: 'Contact Parkiny',
        paragraphs: [
          'Have a question or need assistance? Contact us:',
          'Address: [Fictional Location, Tunis]',
          'Phone: [+216 XX XXX XXX]',
          'Email: [contact@parkiny-pfe.tn]',
          'The parking lot is open 24/7.'
        ]
      }
    },
    'ar': {
      'about': {
        title: 'حول باركيني',
        paragraphs: [
          'باركيني هو أكثر بكثير من مجرد موقف سيارات. إنه حل مبتكر مصمم لتغيير تجربة ركن سيارتك في تونس. يهدف باركيني، الذي ولد من مشروع تخرج طموح، إلى إظهار كيف يمكن للتكنولوجيا تبسيط الحياة اليومية للسائقين من خلال تقديم خدمة ركن سيارات آمنة وعملية وحديثة.',
          'مهمتنا هي تبسيط وتأمين مواقف السيارات في المناطق الحضرية المكتظة. نحن نؤمن بالاستخدام الذكي للتكنولوجيا لتوفير تجربة مستخدم خالية من المتاعب.',
          'حاليًا، يعمل باركيني في موقع واحد، ذي موقع استراتيجي في [موقع وهمي، تونس]. موقفنا الخاص مفتوح على مدار الساعة طوال أيام الأسبوع ويوفر أمانًا معززًا.' // Traduction exemple
        ]
      },
      'contact': {
        title: 'اتصل بـ باركيني',
        paragraphs: [
          'هل لديك سؤال أو تحتاج إلى مساعدة؟ اتصل بنا:',
          'العنوان: [موقع وهمي، تونس]',
          'الهاتف: [+216 XX XXX XXX]',
          'البريد الإلكتروني: [contact@parkiny-pfe.tn]',
          'الموقف مفتوح 24/7.' // Traduction exemple
        ]
      }
    }
  };

  constructor() { }

  getPageContent(pageKey: 'about' | 'contact', lang: string): Observable<PageContent | undefined> {
    const language = this.contentData[lang] ? lang : 'fr'; // Fallback sur 'fr' si la langue n'existe pas
    const content = this.contentData[language]?.[pageKey];
    return of(content);
  }
}

