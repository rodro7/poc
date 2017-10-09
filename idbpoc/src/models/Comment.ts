/**
 * Created by rodrigo.rossi on 9/29/2017.
 */
class Comment {
    id: string;
    userId: string;
    newsId: string;
    date: Date;
    body: string;
    constructor(rest: object){
        for(let key in rest){
            this[key] = rest[key];
        }
    }
}
export {Comment};
