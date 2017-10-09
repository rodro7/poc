/**
 * Created by rodrigo.rossi on 9/29/2017.
 */
import { Injectable } from '@angular/core';
import { Http, Headers }       from '@angular/http';
import { News } from '../models/News';
const NEWS_BASE_URL = 'http://api.idb-dashboard.com:5002/news';
@Injectable()
export class  NewsService {
    results: News[];
    constructor(private http: Http){}
    create(news:News){
        let url = NEWS_BASE_URL;
        return  this.http
            .post(url, JSON.stringify(news), {headers: new Headers({"content-type": "application/json"})})
            .toPromise()
            .then(res => res.json() as News);
    }
    get(id:string = ''){
        let url = `${NEWS_BASE_URL}/${id}`;
        return  this.http
            .get(url)
            .toPromise()
            .then( data => this.results = data.json() as News[]);
    }
    update(news:News){
        let url = NEWS_BASE_URL;
        return  this.http
            .put(url, JSON.stringify(news), {headers: new Headers({"content-type": "application/json"})})
            .toPromise()
            .then(()=> news);
    }
    remove(id:string){
        let url = `${NEWS_BASE_URL}/${id}`;
        return  this.http
            .delete(url)
            .toPromise()
            .then(()=> null);
    }
}
export default NewsService;