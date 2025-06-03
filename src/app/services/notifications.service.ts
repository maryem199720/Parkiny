import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject } from 'rxjs';
import { AuthService } from 'src/app/auth/services/auth/auth.service';
import SockJS from 'sockjs-client';
import { Stomp } from '@stomp/stompjs';

interface Notification {
  id: number;
  type: string;
  message: string;
  createdAt: string;
  isRead: boolean;
  action?: { action: string; subscriptionId?: number };
}

@Injectable({
  providedIn: 'root'
})
export class NotificationsService {
  private stompClient: any;
  private notificationsSubject = new Subject<Notification>();
  notifications$ = this.notificationsSubject.asObservable();
  private apiUrl = 'http://localhost:8082/parking/api/notifications';

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) {
    this.initializeWebSocket();
  }

  private initializeWebSocket() {
    const user = this.authService.getCurrentUser();
    if (user && user.id) {
      const socket = new SockJS('http://localhost:8082/parking/ws');
      this.stompClient = Stomp.over(socket);

      this.stompClient.connect({}, () => {
        console.log('WebSocket connected for user:', user.id);
        this.stompClient.subscribe(`/user/${user.id}/topic/notifications`, (message: any) => {
          console.log('Received notification:', message.body);
          const notification: Notification = JSON.parse(message.body);
          this.notificationsSubject.next(notification);
        });
      }, (error: any) => {
        console.error('WebSocket connection error:', error);
      });
    } else {
      console.warn('No user found for WebSocket initialization');
    }
  }

  getNotifications(): Observable<Notification[]> {
    return this.http.get<Notification[]>(this.apiUrl);
  }

  markAsRead(notificationId: number): Observable<string> {
    return this.http.post<string>(`${this.apiUrl}/${notificationId}/read`, {});
  }
}