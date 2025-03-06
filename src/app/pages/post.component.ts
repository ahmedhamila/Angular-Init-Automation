import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PostService } from '../services/post.service';
import { Post } from '../models/post.model';

@Component({
  selector: 'app-post',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
  <div class="container mx-auto p-6">
    <h1 class="text-2xl font-bold mb-4">Post Management</h1>

    <!-- Form for Adding / Updating -->
    <form (ngSubmit)="save()" class="bg-gray-100 p-4 rounded mb-4">
      <div *ngFor="let field of displayFields">
        <label class="block font-semibold">{{ field }}</label>
        <input [ngModel]="getFormValue(field)" (ngModelChange)="setFormValue(field, $event)" name="{{field}}" class="w-full p-2 border rounded" required>
      </div>
      <button type="submit" class="mt-3 px-4 py-2 bg-green-500 text-white rounded">
        {{ editing ? 'Update' : 'Add' }} Post
      </button>
      <button type="button" *ngIf="editing" (click)="resetForm()" class="ml-2 px-4 py-2 bg-gray-500 text-white rounded">Cancel</button>
    </form>

    <!-- Table of Records -->
    <table class="w-full border-collapse border">
      <thead>
        <tr class="bg-gray-300">
          <th *ngFor="let field of displayFields" class="border p-2">{{ field }}</th>
          <th class="border p-2">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr *ngFor="let item of items">
          <td *ngFor="let field of displayFields" class="border p-2">{{ getItemValue(item, field) }}</td>
          <td class="border p-2">
            <button (click)="edit(item)" class="bg-blue-500 text-white px-2 py-1 rounded">Edit</button>
            <button (click)="deleteItem(item)" class="bg-red-500 text-white px-2 py-1 rounded ml-2">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
  `
})
export class PostComponent implements OnInit {
  items: Post[] = [];
  // Define fields for the data model
  displayFields: string[] = ['title'];
  formData: Post = {} as Post;
  editing = false;
  editId: number | null = null;
  private service = inject(PostService);

  ngOnInit(): void {
    this.fetchData();
  }

  fetchData(): void {
    this.service.getAll().subscribe(data => this.items = data);
  }

  // Helper methods for type-safe property access
  getFormValue(field: string): string {
    return (this.formData as any)[field] || '';
  }

  setFormValue(field: string, value: string): void {
    (this.formData as any)[field] = value;
  }

  getItemValue(item: Post, field: string): string {
    return (item as any)[field] || '';
  }

  save(): void {
    if (this.editing && this.editId !== null) {
      this.service.update(this.editId, this.formData).subscribe(() => {
        this.fetchData();
        this.resetForm();
      });
    } else {
      this.service.create(this.formData).subscribe(() => {
        this.fetchData();
        this.resetForm();
      });
    }
  }

  edit(item: Post): void {
    this.formData = { ...item };
    this.editId = item.id !== undefined ? item.id : null;
    this.editing = true;
  }

  deleteItem(item: Post): void {
    if (item.id !== undefined) {
      this.service.delete(item.id).subscribe(() => this.fetchData());
    }
  }

  resetForm(): void {
    this.formData = {} as Post;
    this.editing = false;
    this.editId = null;
  }
}
