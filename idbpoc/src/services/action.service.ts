import { Injectable } from '@angular/core';
import { Http }       from '@angular/http';
import { Action } from '../models/Action';
const ACTION_BASE_URL = '/action/';
@Injectable()
export class ActionService {
    create(){

    }
    get(id = ''): [Action]{
       let url = `${ACTION_BASE_URL}/${id}`;
       if(id === ''){
           return [new Action({id: 1})];
       }else{
           return [new Action({id: 1, name: "sape"})];
       }
    }
    update(){

    }
    remove(){

    }
}