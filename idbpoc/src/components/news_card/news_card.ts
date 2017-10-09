/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { Component, Input, Output, EventEmitter, OnInit  } from '@angular/core';
import './style.less';
import { News } from '../../models/News';

@Component({
    selector: 'idb-news-card',
    templateUrl: './template.html',
    styles: ['style.less']
})
export class NewsCardComponent implements OnInit{
    @Input() news: News;
    @Output() updateNews = new EventEmitter();
    ngOnInit(){
       // console.info(this.news);
    }
    rateUpdate(rate: any){
        this.news.userRate = parseFloat(rate);
        this.updateNews.emit(this.news);
    }
    commentUpdated(comment: string){
        this.news.comments.push({body: comment, date: new Date(), newsId: this.news.id});
        this.updateNews.emit(this.news);
    }
    select(){
        this.news.selected = !this.news.selected;
        this.updateNews.emit(this.news);
    }
    get background(){
        let result:string = "linear-gradient(to right, rgba(222, 76, 76, 0.85) "+ new String(this.news.sentiment.negative)  + "%,#5cb85c " + new String(110 - this.news.sentiment.positive) + "%)";
        return result;
    }
}
