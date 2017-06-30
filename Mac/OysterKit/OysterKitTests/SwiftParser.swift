//
// STLR Generated Swift File
//
// Generated: 2016-08-19 10:49:16 +0000
//
import OysterKit

//
// SwiftParser Parser
//
class SwiftParser : Parser{
    
    // Convenience alias
    private typealias GrammarToken = Tokens
    
    // Token & Rules Definition
    enum Tokens : Int, Token {
        case _transient, whitespace, symbol, comment, number, stringQuote, escapedCharacter, stringCharacter, string, keyword, variable
        
        func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
            switch self {
            case ._transient:
                return CharacterSet(charactersIn: "").terminal(token: GrammarToken._transient)
            // whitespace
            case .whitespace:
                return CharacterSet.whitespacesAndNewlines.terminal(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken.whitespace)
            // symbol
            case .symbol:
                return CharacterSet(charactersIn: ".{}[]:=,()-><?#!").terminal(token: GrammarToken.symbol)
            // comment
            case .comment:
                return [
                    "//".terminal(token: GrammarToken._transient),
                    CharacterSet.newlines.terminal(token: GrammarToken._transient).not(producing: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.comment)
            // number
            case .number:
                return [
                    CharacterSet.decimalDigits.terminal(token: GrammarToken._transient).repeated(min: 1, producing: GrammarToken._transient),
                    [
                        ".".terminal(token: GrammarToken._transient),
                        CharacterSet.decimalDigits.terminal(token: GrammarToken._transient),
                        ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.number)
            // stringQuote
            case .stringQuote:
                return "\"".terminal(token: GrammarToken.stringQuote)
            // escapedCharacter
            case .escapedCharacter:
                return [
                    "\\".terminal(token: GrammarToken._transient),
                    CharacterSet(charactersIn: "\"rnt\\").terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.escapedCharacter)
            // stringCharacter
            case .stringCharacter:
                return [
                    GrammarToken.escapedCharacter._rule(),
                    [
                        GrammarToken.stringQuote._rule(),
                        CharacterSet.newlines.terminal(token: GrammarToken._transient),
                        ].oneOf(token: GrammarToken._transient).not(producing: GrammarToken._transient),
                    ].oneOf(token: GrammarToken.stringCharacter)
            // string
            case .string:
                return [
                    "\"".terminal(token: GrammarToken._transient),
                    GrammarToken.stringCharacter._rule().repeated(min: 0, producing: GrammarToken._transient),
                    "\"".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.string)
            // keyword
            case .keyword:
                return [
                    ScannerRule.oneOf(token: GrammarToken._transient, ["private", "class", "func", "var", "guard", "let", "static", "init", "case", "typealias", "enum"],[:]),
                    CharacterSet.whitespacesAndNewlines.terminal(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.keyword)
            // variable
            case .variable:
                return CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: GrammarToken._transient).repeated(min: 1, producing: GrammarToken.variable)
            }
        }
        
        // Color Definitions
        fileprivate var color : NSColor? {
            switch self {
            case .comment:	return #colorLiteral(red:0.11457, green:0.506016, blue:0.128891, alpha: 1)
            case .string:	return #colorLiteral(red:0.815686, green:0.129412, blue:0.12549, alpha: 1)
            case .variable:	return #colorLiteral(red:0.309804, green:0.541176, blue:0.6, alpha: 1)
            default:	return nil
            }
        }
        
    }
    
    // Color Dictionary
    static var colors = ["comment" : GrammarToken.comment.color!, "string" : GrammarToken.string.color!, "variable" : GrammarToken.variable.color!]
    
    // Initialize the parser with the base rule set
    init(){
        super.init(grammar: [GrammarToken.whitespace._rule(), GrammarToken.symbol._rule(), GrammarToken.comment._rule(), GrammarToken.number._rule(), GrammarToken.string._rule(), GrammarToken.keyword._rule(), GrammarToken.variable._rule()])
    }
}
