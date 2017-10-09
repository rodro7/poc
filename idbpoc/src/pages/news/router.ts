/**
 * Created by rodrigo.rossi on 10/5/2017.
 */
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { NewsComponent } from '../../components/news/news.component';
const routes: Routes = [
    {
        path: '',
        component: NewsComponent
    }
];

@NgModule({
    imports: [
        RouterModule.forChild(routes)
    ],
    exports: [
        RouterModule
    ]
})
export class NewsRouter {};
