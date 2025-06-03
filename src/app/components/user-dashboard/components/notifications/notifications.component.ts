import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NotificationsService } from 'src/app/services/notifications.service';
import { RouterModule } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';

interface Notification {
  id: number;
  type: string;
  message: string;
  createdAt: string;
  isRead: boolean;
  action?: { action: string; subscriptionId?: number };
}

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule, RouterModule, MatButtonModule],
  templateUrl: './notifications.component.html',
  styleUrls: ['./notifications.component.css']
})
export class NotificationsComponent implements OnInit {
  notifications: Notification[] = [];

  constructor(private notificationsService: NotificationsService) {}

  ngOnInit() {
    // Fetch initial notifications
    this.notificationsService.getNotifications().subscribe(notifications => {
      this.notifications = notifications;
    });

    // Listen for real-time notifications
    this.notificationsService.notifications$.subscribe(notification => {
      this.notifications.unshift(notification);
    });
  }

  markAsRead(notification: Notification) {
    if (!notification.isRead) {
      this.notificationsService.markAsRead(notification.id).subscribe(() => {
        notification.isRead = true;
      });
    }
  }

  handleAction(notification: Notification) {
    if (notification.action && notification.action.action === 'RENEW' && notification.action.subscriptionId) {
      // Navigate to subscription renewal page
      window.location.href = `/dashboard/subscriptions?renew=${notification.action.subscriptionId}`;
    }
  }
}