import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs/Observable';
import 'rxjs/add/observable/of';
import 'rxjs/add/operator/do';
import 'rxjs/add/operator/delay';

@Injectable()
export class AuthService {
    isLoggedIn = false;
    // store the URL so we can redirect after logging in
    redirectUrl: string;
    constructor(private router: Router){

    }
    login(){
        this.isLoggedIn = true;
        this.redirectUrl = !this.redirectUrl || this.redirectUrl.indexOf('login') !== -1 ? '' : this.redirectUrl;
        this.router.navigate([this.redirectUrl]);
    }
    logout(): void {
        this.isLoggedIn = false;
        this.redirectUrl = '/login';
        this.router.navigate([this.redirectUrl]);
    }
}