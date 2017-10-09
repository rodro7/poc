/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { Component, Input, Output, EventEmitter } from '@angular/core';
import './style.less';
import { News } from '../../models/News';

@Component({
    selector: 'idb-rate',
    templateUrl: './template.html',
    styles: ['style.less']
})
export class RateComponent{
    @Input() rating: string;
    @Input() id: string;
    @Output() rateUpdated = new EventEmitter();
    rate(val: string){
        this.rating = val;
        this.rateUpdated.emit(val);
    }
}
