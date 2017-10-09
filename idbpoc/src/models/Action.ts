/**
 * Created by rodrigo.rossi on 9/29/2017.
 */
enum ActionTypes {
    READ = 0,
    UNREAD = 1,
    SAVED = 2,
    DISCARDED = 3,
    APPLIED= 4
};
/***
 * @class Action
 */
class Action {
    id: string;
    name: string;
    constructor(rest : object){
        for(let key in rest){
            this[key] = rest[key];
        }
    }
}
export {Action, ActionTypes};
