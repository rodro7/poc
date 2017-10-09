/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import './style.less';
import { Component, OnInit } from '@angular/core';
import Utils from '../../utils';
import * as $ from 'jquery';
@Component({
    selector: 'idb-nav',
    templateUrl: './template.html',
    styles: ['./style.less']
})
export class NavComponent implements OnInit{
    ngOnInit(){
        Utils.invoke('tooltip', $('.floating-menu .btn-menu'), {});
    }

}