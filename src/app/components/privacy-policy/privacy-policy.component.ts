import { Component, OnInit, OnDestroy } from "@angular/core";
import { CommonModule } from "@angular/common";
import { TranslateService } from "@ngx-translate/core";
import { Subscription } from "rxjs";

// Interface for Privacy Policy Content
interface PrivacyContent {
  titleKey: string;
  lastUpdatedKey: string;
  sections: { titleKey: string; contentKey: string }[];
}

@Component({
  selector: "app-privacy-policy",
  standalone: true,
  imports: [CommonModule], // Add TranslateModule if using pipe in template
  templateUrl: "./privacy-policy.component.html",
  styleUrls: ["./privacy-policy.component.css"],
})
export class PrivacyPolicyComponent implements OnInit, OnDestroy {
  privacyContent: PrivacyContent | undefined;
  isLoading = true;
  private langChangeSubscription!: Subscription;

  // Mock Privacy Policy data - Keys refer to translation files
  // Adapt content for a PFE context (fictional)
  private privacyData: PrivacyContent = {
    titleKey: "PRIVACY_POLICY.TITLE",
    lastUpdatedKey: "PRIVACY_POLICY.LAST_UPDATED", // Example: "Dernière mise à jour : Mai 2025"
    sections: [
      {
        titleKey: "PRIVACY_POLICY.SECTION_1.TITLE", // Introduction
        contentKey: "PRIVACY_POLICY.SECTION_1.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_2.TITLE", // Data Collected
        contentKey: "PRIVACY_POLICY.SECTION_2.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_3.TITLE", // Use of Data
        contentKey: "PRIVACY_POLICY.SECTION_3.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_4.TITLE", // Data Sharing
        contentKey: "PRIVACY_POLICY.SECTION_4.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_5.TITLE", // Data Security
        contentKey: "PRIVACY_POLICY.SECTION_5.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_6.TITLE", // User Rights
        contentKey: "PRIVACY_POLICY.SECTION_6.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_7.TITLE", // Cookies
        contentKey: "PRIVACY_POLICY.SECTION_7.CONTENT",
      },
      {
        titleKey: "PRIVACY_POLICY.SECTION_8.TITLE", // Contact
        contentKey: "PRIVACY_POLICY.SECTION_8.CONTENT",
      },
    ],
  };

  constructor(private translateService: TranslateService) {}

  ngOnInit(): void {
    // Privacy data is static with keys, just set it
    this.privacyContent = this.privacyData;
    this.isLoading = false;

    // Subscribe to language changes if needed
    this.langChangeSubscription = this.translateService.onLangChange.subscribe(
      (event) => {
        // Content uses keys, no reload needed
      }
    );
  }

  ngOnDestroy(): void {
    if (this.langChangeSubscription) {
      this.langChangeSubscription.unsubscribe();
    }
  }
}

