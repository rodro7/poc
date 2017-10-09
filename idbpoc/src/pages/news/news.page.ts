/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CommonComponent }  from '../../commons/common.component';
import { NewsRouter } from './router';
import { NewsComponent } from '../../components/news/news.component';
import { NewsCardComponent } from '../../components/news_card/news_card';
import { NewsService } from '../../services/news.service'
import { HttpModule }    from '@angular/http';
import { RateComponent } from '../../components/rate/rate.component'
import { WordRelevanceComponent } from '../../components/word_relevance/word_relevance.component'
import { CommentsComponent} from '../../components/comments/comments.component'
@NgModule({//
    imports:[NewsRouter, HttpModule, CommonModule, CommonComponent],
    declarations: [NewsCardComponent, NewsComponent, RateComponent, WordRelevanceComponent,CommentsComponent],
    providers: [NewsService]
})
export class NewsPage { }
