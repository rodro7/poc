/**
 * Created by rodrigo.rossi on 9/29/2017.
 */
import { Comment } from '../models/Comment';
import { Action } from '../models/Action';
class Sentiment{
    positive: number;
    negative: number;
}
class News {
    id: string;
    source: string;
    date: Date;
    body: string;
    selected: boolean;
    url: string;
    rate: number;
    userRate: number;
    categories: [string];
    comments: [object];
    actions: [Action];
    keywords: [string];
    sentiment: Sentiment;
    constructor(rest: object){
        for(let key in rest){
            this[key] = rest[key];
        }
    }
}
export {News};