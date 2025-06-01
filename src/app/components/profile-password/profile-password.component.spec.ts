import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ProfilePasswordComponent } from './profile-password.component';

describe('ProfilePasswordComponent', () => {
  let component: ProfilePasswordComponent;
  let fixture: ComponentFixture<ProfilePasswordComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ProfilePasswordComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(ProfilePasswordComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
