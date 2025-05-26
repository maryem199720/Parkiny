import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-parking-selection-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title class="text-2xl font-bold text-gray-800">Sélectionner une place de parking</h2>
    <mat-dialog-content class="p-4">
      <p class="text-gray-600 mb-4">Choisissez une place pour la période sélectionnée :</p>
      <div class="grid grid-cols-1 gap-2">
        <button mat-raised-button class="bg-primary-purple text-white w-full" (click)="selectSpot('P1-A1')">Place P1-A1 (Premium)</button>
        <button mat-raised-button class="bg-primary-purple text-white w-full" (click)="selectSpot('P1-B1')">Place P1-B1 (Standard)</button>
      </div>
    </mat-dialog-content>
    <mat-dialog-actions class="flex justify-end p-4">
      <button mat-button class="text-gray-600" (click)="dialogRef.close()">Annuler</button>
    </mat-dialog-actions>
  `,
  styles: []
})
export class ParkingSelectionDialogComponent {
  constructor(
    public dialogRef: MatDialogRef<ParkingSelectionDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { startTime: string; endTime: string; matricule: string; userId: number }
  ) {}

  selectSpot(spotId: string): void {
    this.dialogRef.close(spotId);
  }
}