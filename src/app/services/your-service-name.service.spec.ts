import { TestBed } from '@angular/core/testing';

import { YourServiceNameService } from './your-service-name.service';

describe('YourServiceNameService', () => {
  let service: YourServiceNameService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(YourServiceNameService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
