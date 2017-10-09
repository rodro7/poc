/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import './style.less';
import Utils  from '../../utils';

@Component({
    selector: 'idb-word-relevance',
    templateUrl: './template.html',
    styles: ['style.less']
})
export class WordRelevanceComponent implements OnInit{
    @Input() body: string;
    wordMap: object;
    ngOnInit(){
        this.wordMap = Utils.wordCount(this.body);

    }
    get Words(){
        let result = [];
        for(let n in this.wordMap){
            result.push(n);
        }
        return result.sort().reverse().filter((n)=>{ return parseFloat(n)>= 2});
    }
    wordSize(ocurrences: number){
        return new String(Math.min(30, 2 + ocurrences))+'px';
    }
}
