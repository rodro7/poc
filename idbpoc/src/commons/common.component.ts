/**
 * Created by rodrigo.rossi on 9/30/2017.
 */
import { NgModule } from '@angular/core';
import { LoaderComponent} from './loader/loader.component';
import { HeaderComponent } from './header/header.component';
import { NavComponent } from './navpan/navpan.component'
const exportsComps = [LoaderComponent, HeaderComponent, NavComponent];
@NgModule({
    declarations: exportsComps,
    exports: exportsComps
})
export class CommonComponent{ }
