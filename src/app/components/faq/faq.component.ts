// src/app/components/faq/faq.component.ts
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';

interface FaqItem {
  question: string;
  answer: string;
  open?: boolean;
}

interface FaqPageContent {
  title: string;
  items: FaqItem[];
}

@Component({
  selector: 'app-faq',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './faq.component.html',
  styleUrls: ['./faq.component.css']
})
export class FaqComponent implements OnInit {
  faqContent: FaqPageContent | undefined;
  isLoading = true;

  private faqData: FaqPageContent = {
    title: 'Frequently Asked Questions',
    items: [
      {
        question: 'How does booking work?',
        answer: 'You can book a spot through the app by selecting your arrival and departure dates and times. Availability is checked in real-time.'
      },
      {
        question: 'Is the parking lot secure?',
        answer: 'Yes, our parking lot is equipped with 24/7 surveillance cameras, controlled access, and security personnel.'
      },
      {
        question: 'What are the opening hours?',
        answer: 'The parking lot is accessible 24 hours a day, 7 days a week for customers with a valid reservation or subscription.'
      },
      {
        question: 'How does payment work?',
        answer: 'Payment is made through the app. You can save a payment method or pay per reservation. Subscriptions are billed monthly.'
      },
      {
        question: 'What if my license plate is not recognized?',
        answer: 'If there’s an issue with license plate recognition, a call button at the entrance will connect you with our support for manual assistance.'
      }
    ]
  };

  constructor() {}

  ngOnInit(): void {
    this.faqContent = {
      ...this.faqData,
      items: this.faqData.items.map(item => ({ ...item, open: false }))
    };
    this.isLoading = false;
  }

  toggleItem(item: FaqItem): void {
    if (this.faqContent) {
      item.open = !item.open;
    }
  }
}