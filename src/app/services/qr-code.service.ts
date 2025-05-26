import { Injectable } from '@angular/core';
import * as QRCode from 'qrcode';

@Injectable({
  providedIn: 'root',
})
export class QrCodeService {
  generateQrCode(element: HTMLCanvasElement, text: string, width: number = 200): Promise<void> {
    return QRCode.toCanvas(element, text, { width, errorCorrectionLevel: 'M' });
  }
}