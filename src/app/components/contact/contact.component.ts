// src/app/components/contact/contact.component.ts
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormBuilder, Validators } from '@angular/forms';

@Component({
  selector: 'app-contact',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.css']
})
export class ContactComponent implements OnInit {
  contactContent = { title: 'Contact Us' };
  isLoading = false;
  contactForm: FormGroup;
  formSubmitted = false;
  formSuccess = false;
  formError = false;

  constructor(private fb: FormBuilder) {
    this.contactForm = this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      subject: ['', Validators.required],
      message: ['', [Validators.required, Validators.minLength(10)]]
    });
  }

  ngOnInit(): void {}

  onSubmit(): void {
    this.formSubmitted = true;
    if (this.contactForm.valid) {
      console.log('Form Submitted:', this.contactForm.value);
      this.formSuccess = true;
      this.formError = false;
      this.contactForm.reset();
      Object.keys(this.contactForm.controls).forEach(key => {
        this.contactForm.get(key)?.setErrors(null);
        this.contactForm.get(key)?.markAsUntouched();
        this.contactForm.get(key)?.markAsPristine();
      });
      this.formSubmitted = false;
      setTimeout(() => this.formSuccess = false, 5000);
    } else {
      console.log('Form is invalid');
      this.formError = true;
      this.formSuccess = false;
    }
  }
}