/**
 * Created by rodrigo.rossi on 10/5/2017.
 */
import { Component, OnInit } from '@angular/core';
import { AuthService} from '../../services/auth.service';
import './style.less';
import * as $ from 'jquery';
@Component({
    selector: 'idb-login',
    templateUrl: './template.html',
    styles: ['style.less']
})
export class LoginComponent implements OnInit{
    constructor(private authService: AuthService){}
    ngOnInit(){
        $('#login-container').css('opacity', 1);
    }
    login(event: any){
        event.preventDefault();
        this.authService.login();
    }
}
