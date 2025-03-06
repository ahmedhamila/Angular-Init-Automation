import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home.component';
import { PostComponent } from './pages/post.component';

export const routes: Routes = [
  { path: '', redirectTo: 'home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: 'post', component: PostComponent },
];
