// src/app/components/privacy-policy/privacy-policy.component.ts
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';

interface PrivacyContent {
  title: string;
  lastUpdated: string;
  sections: { title: string; content: string }[];
}

@Component({
  selector: 'app-privacy-policy',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './privacy-policy.component.html',
  styleUrls: ['./privacy-policy.component.css']
})
export class PrivacyPolicyComponent implements OnInit {
  privacyContent: PrivacyContent | undefined;
  isLoading = true;

  private privacyData: PrivacyContent = {
    title: 'Privacy Policy',
    lastUpdated: 'Last Updated: June 1, 2025',
    sections: [
      { title: 'Introduction', content: 'This Privacy Policy explains how Parkiny collects, uses, and protects your personal information.' },
      { title: 'Information We Collect', content: 'We collect personal information such as your name, email, and vehicle details when you register or make a reservation.' },
      { title: 'How We Use Your Information', content: 'Your information is used to process reservations, manage subscriptions, and improve our services.' },
      { title: 'Data Sharing', content: 'We do not share your personal information with third parties except as required by law or to provide our services.' },
      { title: 'Data Security', content: 'We implement security measures to protect your data, including encryption and access controls.' },
      { title: 'Your Rights', content: 'You have the right to access, correct, or delete your personal information.' },
      { title: 'Cookies', content: 'Our website uses cookies to enhance user experience and track usage.' },
      { title: 'Contact Us', content: 'For questions about this Privacy Policy, contact us at support@parkiny.com.' }
    ]
  };

  constructor() {}

  ngOnInit(): void {
    this.privacyContent = this.privacyData;
    this.isLoading = false;
  }
}