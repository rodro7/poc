/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { CommonComponent }  from '../../commons/common.component';
import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { LoginRouter } from './router';
import { LoginComponent } from '../../components/login/login.component';
@NgModule({
    imports:[LoginRouter, CommonModule, CommonComponent],
    exports: [LoginComponent],
    declarations: [LoginComponent]
})
export class LoginPage { }
