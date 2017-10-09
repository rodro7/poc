/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { Component, OnInit } from '@angular/core';
import { NewsService } from '../../services/news.service'
import './style.less';
import { News } from '../../models/News';
let obj = {
    "id": 1,
    "source": "the economist",
    "pubDate": "2017-10-07T17:42:15.703Z",
    "body": "news body",
    "url": "htts://www.theeconomist.com",
    "rate": 5.0,
    "userRate": 4.9,
    "categories": ["bank", "country"],
    "comments": [
    {
        "author": 1,
        "body": "this news is relevant",
        "parentId": 1,
        "id": 1
    }
],
    "keywords": ["EEUU", "default", "bank", "Trump"]
};
@Component({
    selector: 'idb-news',
    templateUrl: './template.html',
    styles: ['style.less']
})
export class NewsComponent implements OnInit{
    news: News[] = [];
    constructor(private newsSevice: NewsService){
    }
    ngOnInit(){
        this.newsSevice.get().then(news => this.news = news.sort((v1, v2)=>{
            return v1.rate > v2.rate ? -1 :v1.rate < v2.rate ? 1 : 0;
        }));
        var self = this;
        /*setInterval(()=>
        {
            console.info(this);
            obj.body = "body" + new Date();
            this.newsSevice.create(new News(obj)).then(news => self.news.unshift(news));
        }
        , 1000 );*/
    }
    update(news: News){
        debugger;
        this.newsSevice.update(news);
    }
}
