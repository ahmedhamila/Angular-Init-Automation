#!/bin/sh

APP_NAME=$1      # Used in API URL
MODELS_DATA=$2   # Format: "model1:field1,field2;model2:field1,field2"

# Ensure required directories exist
mkdir -p src/app/models
mkdir -p src/app/services
mkdir -p src/app/pages
mkdir -p src/environments

# Parse MODELS_DATA and generate files for each model
IFS=';' read -ra MODELS <<< "$MODELS_DATA"
for MODEL_DATA in "${MODELS[@]}"; do
    # Split model name and fields
    IFS=':' read -r MODEL_NAME FIELDS <<< "$MODEL_DATA"
    
    # Convert model name to PascalCase (e.g., product -> Product)
    CAP_MODEL_NAME=$(echo "$MODEL_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    
    # Convert comma-separated fields into array
    IFS=',' read -ra FIELD_ARRAY <<< "$FIELDS"
    
    echo "Generating files for model: $MODEL_NAME with fields: $FIELDS"
    
    # Generate typed model with all fields
    cat <<EOF > src/app/models/$MODEL_NAME.model.ts
export interface $CAP_MODEL_NAME {
  id?: number;
EOF
    for FIELD in "${FIELD_ARRAY[@]}"; do
      echo "  $FIELD: string;" >> src/app/models/$MODEL_NAME.model.ts
    done
    echo "}" >> src/app/models/$MODEL_NAME.model.ts
    
    # Generate service for the model
    cat <<EOF > src/app/services/$MODEL_NAME.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { $CAP_MODEL_NAME } from '../models/$MODEL_NAME.model';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ${CAP_MODEL_NAME}Service {
  private baseUrl = \`\${environment.apiUrl}/$APP_NAME/$MODEL_NAME\`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<$CAP_MODEL_NAME[]> {
    return this.http.get<$CAP_MODEL_NAME[]>(this.baseUrl);
  }

  getOne(id: number): Observable<$CAP_MODEL_NAME> {
    return this.http.get<$CAP_MODEL_NAME>(\`\${this.baseUrl}/\${id}\`);
  }

  create(data: $CAP_MODEL_NAME): Observable<$CAP_MODEL_NAME> {
    return this.http.post<$CAP_MODEL_NAME>(this.baseUrl+"/", data);
  }

  update(id: number, data: $CAP_MODEL_NAME): Observable<$CAP_MODEL_NAME> {
    return this.http.put<$CAP_MODEL_NAME>(\`\${this.baseUrl}/\${id}/\`, data);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(\`\${this.baseUrl}/\${id}/\`);
  }
}
EOF

    # Create an array of fields for template
    FIELD_JSON_ARRAY="["
    for FIELD in "${FIELD_ARRAY[@]}"; do
      FIELD_JSON_ARRAY+="'$FIELD', "
    done
    FIELD_JSON_ARRAY="${FIELD_JSON_ARRAY%, }]"
    
    # Modify component to handle full CRUD operations
    cat <<EOF > src/app/pages/$MODEL_NAME.component.ts
import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ${CAP_MODEL_NAME}Service } from '../services/$MODEL_NAME.service';
import { $CAP_MODEL_NAME } from '../models/$MODEL_NAME.model';

@Component({
  selector: 'app-$MODEL_NAME',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: \`
  <div class="container mx-auto p-6">
    <h1 class="text-2xl font-bold mb-4">$CAP_MODEL_NAME Management</h1>

    <!-- Form for Adding / Updating -->
    <form (ngSubmit)="save()" class="bg-gray-100 p-4 rounded mb-4">
      <div *ngFor="let field of displayFields">
        <label class="block font-semibold">{{ field }}</label>
        <input [ngModel]="getFormValue(field)" (ngModelChange)="setFormValue(field, \$event)" name="{{field}}" class="w-full p-2 border rounded" required>
      </div>
      <button type="submit" class="mt-3 px-4 py-2 bg-green-500 text-white rounded">
        {{ editing ? 'Update' : 'Add' }} $CAP_MODEL_NAME
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
  \`
})
export class ${CAP_MODEL_NAME}Component implements OnInit {
  items: $CAP_MODEL_NAME[] = [];
  // Define fields for the data model
  displayFields: string[] = $FIELD_JSON_ARRAY;
  formData: $CAP_MODEL_NAME = {} as $CAP_MODEL_NAME;
  editing = false;
  editId: number | null = null;
  private service = inject(${CAP_MODEL_NAME}Service);

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

  getItemValue(item: $CAP_MODEL_NAME, field: string): string {
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

  edit(item: $CAP_MODEL_NAME): void {
    this.formData = { ...item };
    this.editId = item.id !== undefined ? item.id : null;
    this.editing = true;
  }

  deleteItem(item: $CAP_MODEL_NAME): void {
    if (item.id !== undefined) {
      this.service.delete(item.id).subscribe(() => this.fetchData());
    }
  }

  resetForm(): void {
    this.formData = {} as $CAP_MODEL_NAME;
    this.editing = false;
    this.editId = null;
  }
}
EOF
done

# Generate standalone HomeComponent 
cat <<EOF > src/app/pages/home.component.ts
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  template: \`
  <div class="container mx-auto p-4 text-center">
    <h1 class="text-3xl font-bold">Welcome to the Home Page</h1>
  </div>
  \`
})
export class HomeComponent {}
EOF

# Generate routes with all models
cat <<EOF > src/app/app.routes.ts
import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home.component';
EOF

# Add imports for each model component
for MODEL_DATA in "${MODELS[@]}"; do
    IFS=':' read -r MODEL_NAME FIELDS <<< "$MODEL_DATA"
    CAP_MODEL_NAME=$(echo "$MODEL_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    echo "import { ${CAP_MODEL_NAME}Component } from './pages/$MODEL_NAME.component';" >> src/app/app.routes.ts
done

# Continue with routes definition
echo "" >> src/app/app.routes.ts
echo "export const routes: Routes = [" >> src/app/app.routes.ts
echo "  { path: '', redirectTo: 'home', pathMatch: 'full' }," >> src/app/app.routes.ts
echo "  { path: 'home', component: HomeComponent }," >> src/app/app.routes.ts

# Add route for each model
for MODEL_DATA in "${MODELS[@]}"; do
    IFS=':' read -r MODEL_NAME FIELDS <<< "$MODEL_DATA"
    CAP_MODEL_NAME=$(echo "$MODEL_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    echo "  { path: '$MODEL_NAME', component: ${CAP_MODEL_NAME}Component }," >> src/app/app.routes.ts
done

echo "];" >> src/app/app.routes.ts

# Update app.config.ts for HTTP client
cat <<EOF > src/app/app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient()
  ]
};
EOF

# Create app.component.ts with navigation
cat <<EOF > src/app/app.component.ts
import { Component } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule],
  template: \`
    <div class="min-h-screen bg-gray-100">
      <nav class="bg-gray-800 text-white p-4">
        <div class="container mx-auto flex flex-wrap items-center justify-between">
          <a routerLink="/" class="text-xl font-bold">$APP_NAME App</a>
          <div class="flex space-x-4">
            <a routerLink="/home" class="hover:bg-gray-700 px-3 py-2 rounded">Home</a>
EOF

# Add navigation links for each model
for MODEL_DATA in "${MODELS[@]}"; do
    IFS=':' read -r MODEL_NAME FIELDS <<< "$MODEL_DATA"
    CAP_MODEL_NAME=$(echo "$MODEL_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    echo "            <a routerLink=\"/$MODEL_NAME\" class=\"hover:bg-gray-700 px-3 py-2 rounded\">$CAP_MODEL_NAME</a>" >> src/app/app.component.ts
done

# Close the navigation and component template
cat <<EOF >> src/app/app.component.ts
          </div>
        </div>
      </nav>
      <div class="container mx-auto p-4">
        <router-outlet></router-outlet>
      </div>
    </div>
  \`
})
export class AppComponent {}
EOF

echo "All files generated successfully for $APP_NAME with the following models:"
for MODEL_DATA in "${MODELS[@]}"; do
    IFS=':' read -r MODEL_NAME FIELDS <<< "$MODEL_DATA"
    echo "- $MODEL_NAME ($FIELDS)"
done