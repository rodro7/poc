/**
 * Created by rodrigo.rossi on 10/5/2017.
 */
/**
 * Created by rodrigo.rossi on 10/5/2017.
 */
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { PreloadAllModules } from '@angular/router';
import { AuthGuard } from './services/authguard.service'
const routes: Routes = [
    {
        path: 'news',
        loadChildren: './pages/news/news.page#NewsPage',
        canActivate: [AuthGuard],
    },{
        path: 'login',
        loadChildren: './pages/login/login.page#LoginPage'
    },
    { path: '**',
        redirectTo: '/news',
        pathMatch: 'full'
    },
];

@NgModule({
    imports: [
        RouterModule.forRoot(routes, {
            enableTracing: false,
            preloadingStrategy: PreloadAllModules
        })
    ],
    exports: [
        RouterModule
    ]
})
export class AppRouter {};
