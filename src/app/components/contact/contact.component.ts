import { Component, OnInit, OnDestroy } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule, ReactiveFormsModule, FormGroup, FormBuilder, Validators } from "@angular/forms";
import { TranslateService, TranslateModule } from "@ngx-translate/core"; // Ensure TranslateModule is imported
import { Subscription } from "rxjs";
import { ContentService, PageContent } from "../../services/content.service";

@Component({
  selector: "app-contact",
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, TranslateModule], // Add TranslateModule here
  templateUrl: "./contact.component.html",
  styleUrls: ["./contact.component.css"],
})
export class ContactComponent implements OnInit, OnDestroy {
  contactContent: PageContent | undefined;
  isLoading = true;
  contactForm: FormGroup;
  formSubmitted = false;
  formSuccess = false;
  formError = false;
  private langChangeSubscription!: Subscription;

  constructor(
    private translateService: TranslateService,
    private contentService: ContentService,
    private fb: FormBuilder
  ) {
    this.contactForm = this.fb.group({
      name: ["", Validators.required],
      email: ["", [Validators.required, Validators.email]],
      subject: ["", Validators.required],
      message: ["", [Validators.required, Validators.minLength(10)]],
    });
  }

  ngOnInit(): void {
    this.loadContent(this.translateService.currentLang || 'fr'); // Fallback to 'fr' if currentLang is undefined
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
    this.contentService.getPageContent("contact", lang).subscribe({
      next: (content) => {
        this.contactContent = content;
        this.isLoading = false;
      },
      error: (error) => {
        console.error("Error loading contact content:", error);
        this.contactContent = { 
          title: this.translateService.instant("ERROR.CONTENT_LOAD_FAILED"), 
          paragraphs: [this.translateService.instant("ERROR.CONTENT_LOAD_FAILED")] 
        };
        this.isLoading = false;
      },
    });
  }

  onSubmit(): void {
    this.formSubmitted = true;

    if (this.contactForm.valid) {
      console.log("Form Submitted:", this.contactForm.value);
      this.formSuccess = true;
      this.formError = false;
      this.contactForm.reset();
      Object.keys(this.contactForm.controls).forEach(key => {
        this.contactForm.get(key)?.setErrors(null);
        this.contactForm.get(key)?.markAsUntouched();
        this.contactForm.get(key)?.markAsPristine();
      });
      this.formSubmitted = false;

      setTimeout(() => {
        this.formSuccess = false;
      }, 5000);
    } else {
      console.log("Form is invalid");
      this.formError = true;
      this.formSuccess = false;
    }
  }
}