import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  template: `
  <div class="container mx-auto p-4 text-center">
    <h1 class="text-3xl font-bold">Welcome to the Home Page</h1>
  </div>
  `
})
export class HomeComponent {}
