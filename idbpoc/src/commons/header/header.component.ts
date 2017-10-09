/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { Component, OnInit } from '@angular/core';
import { AuthService } from '../../services/auth.service';
import './style.less';
import * as $ from 'jquery';
import Utils  from '../../utils';
@Component({
    selector: 'idb-header',
    templateUrl: './template.html',
    styles: ['./style.less']
})
export class HeaderComponent implements OnInit{
    constructor(private authService: AuthService){

    }
    ngOnInit(){
        Utils.invoke('dropdown', $(".dropdown-toggle"), null);
    }
    logout(){
        this.authService.logout();
    }
}