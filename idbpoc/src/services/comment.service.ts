/**
 * Created by rodrigo.rossi on 9/29/2017.
 */
import { Injectable } from '@angular/core';
import { Http }       from '@angular/http';
import { Comment } from '../models/Comment';
const COMMENTS_BASE_URL = '/comment/';
@Injectable()
export class CommentService {
    create(){

    }
    get(id = ''){
        let url = `${COMMENTS_BASE_URL}/${id}`;
        if(id === ''){
            return [new Comment({body: 'comment'})];
        }else{
            return new Comment({body: 'comment'});
        }
    }
    update(){

    }
    remove(){

    }
}