import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ProfileVehiclesComponent } from './profile-vehicles.component';

describe('ProfileVehiclesComponent', () => {
  let component: ProfileVehiclesComponent;
  let fixture: ComponentFixture<ProfileVehiclesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ProfileVehiclesComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(ProfileVehiclesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
