/**
 * Created by rodrigo.rossi on 10/5/2017.
 */

import { Component, Input, Output, EventEmitter } from '@angular/core';
import { AuthService} from '../../services/auth.service';
import './style.less';
import * as $ from 'jquery';
@Component({
    selector: 'idb-comment',
    templateUrl: './template.html',
    styles: ['style.less']
})
export class CommentsComponent{
    @Input() comments: [object];
    @Input() active: boolean;
    @Output() commentUpdated = new EventEmitter();
    @Output() closeEmitter = new EventEmitter();
    constructor(private authService: AuthService){}
    login(event: any){
        event.preventDefault();
        this.authService.login();
    }
    closeComment(){
        this.closeEmitter.emit();
    }
    createComment($event: any, val: string){
        $event.preventDefault();
        $event.stopPropagation();
        this.commentUpdated.emit(val);
    }
}
