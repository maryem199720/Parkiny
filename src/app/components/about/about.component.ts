// src/app/components/about/about.component.ts
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-about',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './about.component.html',
  styleUrls: ['./about.component.css']
})
export class AboutComponent implements OnInit {
  aboutContent: any = {};
  isLoading = true;

  private defaultContent = {
    hero: {
      title: 'About Parkiny',
      subtitle: 'Revolutionizing Parking in Tunisia'
    },
    client: {
      name: 'TuniPark',
      founded: '2020',
      location: 'Tunis, Tunisia',
      description: 'TuniPark is a Tunisian company specializing in private parking management, seeking to modernize the parking experience through innovative technological solutions.'
    },
    project: {
      title: 'Final Year Project - June 2025',
      description: 'Parkiny is a final year project developed to meet the specific needs of TuniPark. Our mission was to create a smart parking solution using Tunisian license plate recognition to automate and secure parking access.',
      features: ['Automatic recognition of Tunisian plates', '24/7 operation', 'Analytics dashboard', 'Mobile app for users', 'Subscription management']
    },
    team: {
      title: 'Our Team',
      members: [
        {
          name: 'Development Team',
          role: 'Computer Science Students',
          bio: 'Project carried out as part of our computer science education, specializing in artificial intelligence and web development.'
        }
      ]
    },
    technology: {
      title: 'Our Technology',
      description: 'At the heart of Parkiny is a license plate recognition system specially designed for the Tunisian format. This technology combines computer vision (YOLO) for plate detection and OCR (EasyOCR) for character reading.',
      features: ['Adapted to Tunisian formats', 'High accuracy even in difficult conditions', 'Real-time processing', 'Data security and confidentiality']
    },
    timeline: {
      title: 'Our Journey',
      events: [
        { date: 'January 2025', title: 'Project start', description: 'Needs analysis and specifications' },
        { date: 'March 2025', title: 'Prototype development', description: 'First functional license plate recognition model' },
        { date: 'May 2025', title: 'Testing and optimization', description: 'Improving accuracy and performance' },
        { date: 'June 2025', title: 'Final presentation', description: 'Demonstration of the complete system' }
      ]
    }
  };

  constructor() {}

  ngOnInit(): void {
    this.aboutContent = this.defaultContent;
    this.isLoading = false;
  }
}