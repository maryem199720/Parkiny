import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { environment } from 'src/environments/environment';


@Injectable({
  providedIn: 'root'
})
export class ContentService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) { }

  /**
   * Get page content from the API
   * @param pageName Name of the page (about, contact, faq, etc.)
   * @param language Language code (FR, EN)
   * @returns Observable with page content
   */
  getPageContent(pageName: string, language: string): Observable<any> {
    return this.http.get(`${this.apiUrl}/content/${pageName}?lang=${language}`).pipe(
      catchError(error => {
        console.error(`Error fetching ${pageName} content:`, error);
        return of(null);
      })
    );
  }

  /**
   * Update page content (admin only)
   * @param pageName Name of the page
   * @param language Language code
   * @param content Content object to update
   * @returns Observable with update result
   */
  updatePageContent(pageName: string, language: string, content: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/content/${pageName}?lang=${language}`, content).pipe(
      catchError(error => {
        console.error(`Error updating ${pageName} content:`, error);
        return of({ success: false, error: 'Failed to update content' });
      })
    );
  }

  /**
   * Get all editable content for admin dashboard
   * @returns Observable with all content
   */
  getAllContent(): Observable<any> {
    return this.http.get(`${this.apiUrl}/content/all`).pipe(
      catchError(error => {
        console.error('Error fetching all content:', error);
        return of(null);
      })
    );
  }
}
