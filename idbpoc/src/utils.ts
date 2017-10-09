/**
 * Created by rodrigo.rossi on 10/8/2017.
 */


export default class Utils{
    static invoke(fnc:string, context:any, argumetns: any){
        var func = context[fnc];
        return func.apply(context, argumetns);
    }
    /* credits https://stackoverflow.com/questions/30906807/word-frequency-in-javascript*/
    static wordCount(phrase:string){
        var pattern = /\w+/g,
            matchedWords = phrase.match( pattern ),
            result:object = {};
        let wordMap: object = matchedWords.reduce(function ( stats, word ) {
           word = word.toLowerCase();
            if (!stats.hasOwnProperty( word ) ) {
                stats[ word ] = 0;
            }
            stats[ word ] = stats[ word ] + 1;
            return stats;

        }, {} );
        for(let n in wordMap){
            let val = wordMap[n];
            if(!result.hasOwnProperty(val)){
                result[val] = [];
            }
            result[val].push(n);
        }
        return result;
    }
}