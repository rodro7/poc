import { NgModule } from '@angular/core';
import { BrowserModule }  from '@angular/platform-browser';
import { CommonComponent }  from './commons/common.component';
import { AppRouter } from './router';
import { AppComponent } from './app/app.component';
import { Router } from '@angular/router';
import { AuthGuard } from './services/authguard.service';
import { AuthService }      from './services/auth.service';
import 'bootstrap';
import './assets/css/font-awesome.min.css'
import 'bootstrap/dist/css/bootstrap.min.css';
@NgModule({
  imports: [
    BrowserModule,
    CommonComponent,
    AppRouter
  ],
  providers: [AuthGuard, AuthService],
  declarations: [
    AppComponent
  ],
  bootstrap: [ AppComponent ]
})
export class AppModule {
  constructor(router: Router) {
  }
}
