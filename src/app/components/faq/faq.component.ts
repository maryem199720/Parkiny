import { Component, OnInit, OnDestroy } from "@angular/core";
import { CommonModule } from "@angular/common";
import { TranslateService, TranslateModule } from "@ngx-translate/core"; // Import TranslateModule
import { Subscription } from "rxjs";

// Define an interface for FAQ items
interface FaqItem {
  question: string;
  answer: string;
  open?: boolean; // For accordion functionality
}

// Define an interface for FAQ page content
interface FaqPageContent {
  title: string;
  items: FaqItem[];
}

@Component({
  selector: "app-faq",
  standalone: true,
  imports: [CommonModule, TranslateModule], // Add TranslateModule
  templateUrl: "./faq.component.html",
  styleUrls: ["./faq.component.css"],
})
export class FaqComponent implements OnInit, OnDestroy {
  faqContent: FaqPageContent | undefined;
  isLoading = true;
  private langChangeSubscription!: Subscription;

  // Mock FAQ data directly in the component for PFE simplicity
  private faqData: { [lang: string]: FaqPageContent } = {
    fr: {
      title: "Questions Fréquemment Posées",
      items: [
        {
          question: "Comment fonctionne la réservation ?",
          answer: "Vous pouvez réserver une place via l'application en sélectionnant vos dates et heures d'arrivée et de départ. La disponibilité est vérifiée en temps réel.",
        },
        {
          question: "Le parking est-il sécurisé ?",
          answer: "Oui, notre parking est équipé de caméras de surveillance 24/7, d'un accès contrôlé et de personnel de sécurité.",
        },
        {
          question: "Quels sont les horaires d'ouverture ?",
          answer: "Le parking est accessible 24 heures sur 24, 7 jours sur 7 pour les clients ayant une réservation ou un abonnement valide.",
        },
        {
          question: "Comment fonctionne le paiement ?",
          answer: "Le paiement s'effectue via l'application. Vous pouvez enregistrer un moyen de paiement ou payer à chaque réservation. Les abonnements sont facturés mensuellement.",
        },
        {
          question: "Que faire si ma plaque n'est pas reconnue ?",
          answer: "En cas de problème avec la reconnaissance de plaque, un bouton d'appel à l'entrée vous mettra en contact avec notre support pour une assistance manuelle.",
        },
      ],
    },
    en: {
      title: "Frequently Asked Questions",
      items: [
        {
          question: "How does booking work?",
          answer: "You can book a spot through the app by selecting your arrival and departure dates and times. Availability is checked in real-time.",
        },
        {
          question: "Is the parking lot secure?",
          answer: "Yes, our parking lot is equipped with 24/7 surveillance cameras, controlled access, and security personnel.",
        },
        {
          question: "What are the opening hours?",
          answer: "The parking lot is accessible 24 hours a day, 7 days a week for customers with a valid reservation or subscription.",
        },
        {
          question: "How does payment work?",
          answer: "Payment is made through the app. You can save a payment method or pay per reservation. Subscriptions are billed monthly.",
        },
        {
          question: "What if my license plate is not recognized?",
          answer: "If there's an issue with license plate recognition, a call button at the entrance will connect you with our support for manual assistance.",
        },
      ],
    },
    ar: {
      title: "الأسئلة الشائعة",
      items: [
        {
          question: "كيف يعمل الحجز؟",
          answer: "يمكنك حجز مكان عبر التطبيق عن طريق تحديد تواريخ وأوقات الوصول والمغادرة. يتم التحقق من التوفر في الوقت الفعلي.",
        },
        {
          question: "هل الموقف آمن؟",
          answer: "نعم، موقف السيارات لدينا مجهز بكاميرات مراقبة على مدار الساعة طوال أيام الأسبوع، ودخول مراقب، وموظفي أمن.",
        },
        {
          question: "ما هي ساعات العمل؟",
          answer: "يمكن الوصول إلى الموقف على مدار 24 ساعة في اليوم، 7 أيام في الأسبوع للعملاء الذين لديهم حجز أو اشتراك صالح.",
        },
        {
          question: "كيف يعمل الدفع؟",
          answer: "يتم الدفع من خلال التطبيق. يمكنك حفظ طريقة دفع أو الدفع لكل حجز. يتم إصدار فواتير الاشتراكات شهريًا.",
        },
        {
          question: "ماذا لو لم يتم التعرف على لوحة الترخيص الخاصة بي؟",
          answer: "في حالة وجود مشكلة في التعرف على لوحة الترخيص، سيقوم زر الاتصال عند المدخل بتوصيلك بدعمنا للحصول على مساعدة يدوية.",
        },
      ],
    },
  };

  constructor(private translateService: TranslateService) {}

  ngOnInit(): void {
    this.loadContent(this.translateService.currentLang || 'fr'); // Fallback to 'fr'
    this.langChangeSubscription = this.translateService.onLangChange.subscribe(
      (event) => {
        this.loadContent(event.lang);
      }
    );
  }

  ngOnDestroy(): void {
    if (this.langChangeSubscription) {
      this.langChangeSubscription.unsubscribe();
    }
  }

  loadContent(lang: string): void {
    this.isLoading = true;
    setTimeout(() => {
      const content = this.faqData[lang] || this.faqData['fr'];
      if (content) {
        this.faqContent = {
          ...content,
          items: content.items.map(item => ({ ...item, open: false }))
        };
      } else {
        this.faqContent = undefined;
      }
      this.isLoading = false;
    }, 300);
  }

  toggleItem(item: FaqItem): void {
    if (this.faqContent) {
      item.open = !item.open;
    }
  }
}