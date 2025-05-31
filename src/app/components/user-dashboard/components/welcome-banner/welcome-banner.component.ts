import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from 'src/app/auth/services/auth/auth.service';

@Component({
  selector: 'app-welcome-banner',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './welcome-banner.component.html',
  styleUrl: './welcome-banner.component.css'
})
export class WelcomeBannerComponent implements OnInit {
  userName: string | null = null;

  constructor(private authService: AuthService) {}

  ngOnInit() {
    this.authService.getUser().subscribe(user => {
      this.userName = user ? `${user.firstName} ${user.lastName}`.trim() || null : null;
    });
  }
}