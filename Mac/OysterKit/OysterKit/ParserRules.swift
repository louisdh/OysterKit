//
//  Rule.swift
//  OysterKit
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation


enum ConsumedToken : Int, Token{
    case skip
}

private struct EmptyLexicalContext : LexicalContext {
    let source   : String
    let position : String.UnicodeScalarView.Index
    
    fileprivate var range: Range<String.UnicodeScalarView.Index>{
        return position..<position
    }
    
    fileprivate var matchedString: String{
        return ""
    }
}

///: Should throw on failure, true if the token should be passed false if it should be consumed
public typealias CustomRuleClosure = (_ lexer:LexicalAnalyzer) throws -> Bool

public indirect enum ParserRule : Rule, CustomStringConvertible{
    
    public var failureIgnorable : Bool {
        switch self {
        case .optional:
            return true
        case .repeated(_, _, let min, _,_):
            return min ?? 0 == 0
        default:
            return false
        }
    }
    
    public var isNot : Bool {
        if case .not = self {
            return true
        } else {
            return false
        }
    }
    
    public func match(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws -> MatchResult {
        var matchResult = MatchResult.failure(atIndex: lexer.index)
        let endOfInput = lexer.endOfInput

        if let knownResult = ir.willEvaluate(rule: self, at: lexer.index){
            
            ir.didEvaluate(rule: self, matchResult: knownResult)
            
            switch knownResult{
            case .success(let lexicalContext):
                lexer.index = lexicalContext.range.upperBound
            case .failure:
                throw GrammarError.matchFailed
            default: break
            }
            
            return knownResult
        }
        
        // Mark the current lexer position
        lexer.mark()
        
        // When the function returns and was not successful make sure that the current
        // mark is discarded
        defer{
            switch matchResult {
            case .failure:
                lexer.rewind()
            default: break
            }
            
            ir.didEvaluate(rule: self, matchResult: matchResult)
        }
        
        func success() ->MatchResult{
            matchResult = MatchResult.success(context: lexer.proceed())
            return matchResult
        }
        
        func consume()->MatchResult{
            matchResult = MatchResult.consume(context: lexer.proceed())
            
            return matchResult
        }
        
        func ignoreFailure()->MatchResult{
            matchResult = MatchResult.ignoreFailure
            let _ = lexer.proceed()
            
            return matchResult
        }
        
   

        
        switch self {
        case .terminalUntilOneOf(_, let terminatorCharacter,_):
            if endOfInput {
                throw GrammarError.matchFailed
            }
            do {
                try lexer.scanUpTo(oneOf: terminatorCharacter)
                
                return success()
            } catch {
                throw GrammarError.matchFailed
            }
        case .terminalUntil(_, let terminator,_):
            if endOfInput {
                throw GrammarError.matchFailed
            }
            do {
                try lexer.scanUpTo(terminal: terminator)
                return success()
            } catch {
                throw GrammarError.matchFailed
            }
        case .terminal(_, let terminalString,_):
            if endOfInput {
                throw GrammarError.matchFailed
            }
            do {
                try lexer.scan(terminal: terminalString)
                return success()
            } catch {
                throw GrammarError.matchFailed
            }
        case .terminalFrom(_, let characterSet,_):
            if endOfInput {
                throw GrammarError.matchFailed
            }
            do {
                try lexer.scan(oneOf: characterSet)
                return success()
            } catch {
                throw GrammarError.matchFailed
            }
        case .sequence(_, let sequence,_):
            for rule in sequence{
                do {
                    let _ = try rule.match(with: lexer, for: ir)
                } catch (let error){
                    throw error
                }
            }
            return success()
        case .oneOf(_, let choices,_):
            for rule in choices{
                do {
                    let _ = try rule.match(with: lexer, for: ir)
                    return success()
                } catch {

                }
            }
            // We expected a match of one of them 
            throw GrammarError.matchFailed
        case .repeated(_, let rule, let min, let limit,_):
            let minimum = min ?? 0
            let skippable = minimum == 0
            var matches = 0
            
            do {
                let unlimited = limit == nil
                while unlimited || matches < limit! {
                    switch try rule.match(with: lexer, for: ir){
                    // both of these actively matched
                    case .success, .consume:
                        matches += 1
                    //A repeated no matching, should treat this as a hard failure
                    case .ignoreFailure, .failure:
                        throw GrammarError.noTokenCreatedFromMatch
                    }
                }
            } catch (let error){
                //Should we just consume?
                if matches == 0 && skippable {
                    return ignoreFailure()
                }
                if matches < minimum {
                    throw error
                }
            }
            return success()
        case .optional(_, let rule,let annotations):
            //If it throws on non match, we don't care... if it returns nil... we don't care
            let optionalMatch = try ParserRule.repeated(produces:produces, rule,min: nil,limit: 1, annotations).match(with: lexer, for: ir)
            
            switch optionalMatch {
            case .success, .consume:
                matchResult = optionalMatch
                //We still must advance the lexer
                let _ = lexer.proceed()
                return optionalMatch
            case .ignoreFailure:
                //Optionals should be optional themselves, ignoring the failure is not an option
                //Perhaps should consider adding a new GrammarError to provide more accurate feedback
//                throw GrammarError.noTokenCreatedFromMatch
                return ignoreFailure()
            case .failure:
                //Not sure exactly what to do in this case
                throw GrammarError.notImplemented
            }
            
        case .consume(let rule,_):
            let _ = try rule.match(with: lexer, for: ir)

            return consume()
        case .lookahead(let rule,_):
            let _ = lexer.mark()
            do {
                let _ = try rule.match(with: lexer, for: LookAheadIR())
            } catch (let error) {
                lexer.rewind()
                throw error
            }
            lexer.rewind()
            return consume()
        case .not(_, let rule,_):
            do {
                let _ = try rule.match(with: lexer, for: ir)
            } catch {
                if !endOfInput {
                    try lexer.scanNext()                    
                } else {
                    //If I am looking ahead, being at the end in a not rule
                    //is success
                    if let _ = ir as? LookAheadIR{
                        return success()
                    } else {
                        //Fail, it's not not the token, and I'm not looking ahead
                        throw GrammarError.matchFailed
                    }
                }
                return success()
            }
            
            throw GrammarError.matchFailed
        case .custom(_, let rule, _, _):
            return try rule(lexer) ? success() : consume()
        }
        
    }
    
    public var produces: Token{
        switch self{
        case .terminal(let spec):
            return spec.0
        case .terminalFrom(let spec):
            return spec.0
        case .sequence(let spec):
            return spec.0
        case .oneOf(let spec):
            return spec.0
        case .repeated(let spec):
            return spec.0
        case .optional(let spec):
            return spec.0
        case .terminalUntil(let spec):
            return spec.0
        case .terminalUntilOneOf(let spec):
            return spec.0
        case .consume, .lookahead:
            return ConsumedToken.skip
        case .not(let spec):
            return spec.0
        case .custom(let spec):
            return spec.0
        }
    }
    
    public var annotations: RuleAnnotations{
        get {
            let definedAnnotations : RuleAnnotations?
            switch self {
            case .terminal(_, _, let annotations), .terminalFrom(_, _, let annotations), .terminalUntil(_, _, let annotations), .terminalUntilOneOf(_, _, let annotations), .consume(_, let annotations), .repeated(_, _, _, _, let annotations), .optional(_, _, let annotations), .sequence(_, _, let annotations), .oneOf(_, _, let annotations), .custom(_, _, _, let annotations), .lookahead(_, let annotations), .not(_, _, let annotations):
                definedAnnotations = annotations
            }
            
            return definedAnnotations ?? [:]
        }
        set {
            switch self{
            case .terminal(let token,let string, _):
                self = .terminal(produces: token,string ,newValue)
            case .terminalFrom(let token, let characterSet, _):
                self = .terminalFrom(produces: token, characterSet, newValue)
            case .terminalUntil(let token,let string, _):
                self = .terminalUntil(produces: token,string ,newValue)
            case .terminalUntilOneOf(let token, let characterSet, _):
                self = .terminalUntilOneOf(produces: token, characterSet, newValue)
            case .consume(let rule, _):
                self = .consume(rule, newValue)
            case .repeated(let token, let rule, let min, let limit, _):
                self = .repeated(produces: token, rule, min: min, limit: limit, newValue)
            case .optional(let token, let rule, _):
                self = .optional(produces: token, rule, newValue)
            case .sequence(let token, let rules, _):
                self = .sequence(produces: token, rules, newValue)
            case .oneOf(let token, let rules, _):
                self = .oneOf(produces: token, rules, newValue)
            case .custom(let token, let closure, let description, _):
                self = .custom(produces: token, closure, description, newValue)
            case .lookahead(let rule, _):
                self = .lookahead(rule, newValue)
            case .not(let token, let rule, _):
                self = .not(produces: token, rule, newValue)
            }
        }
    }
    
    public var description: String{
        let ruleType : String

        switch self{
        case .terminal(_, let string,_):
            ruleType = "\"\(string)\""
        case .terminalFrom:
            ruleType = ".characterSet"
        case .sequence(_, let sequence,_):
            ruleType = "("+sequence.map({"\($0)"}).joined(separator: " ")+")"
        case .oneOf(_, let choices,_):
            ruleType = "("+choices.map({"\($0)"}).joined(separator: "|")+")"
        case .repeated(_, let rule, let min, let limit,_):
            if min ?? 0 == 0 {
                ruleType = "\(rule)*"
            } else if limit == nil{
                ruleType = "\(rule)+"
            } else {
                ruleType = "\(rule)\(min ?? 0)...\(limit ?? 1)"
            }
        case .optional(_, let rule,_):
            ruleType = "\(rule)?"
        case .terminalUntil(_, let string,_):
            ruleType = "(\"\(string)\"!)*"
        case .terminalUntilOneOf:
            ruleType = "(\".characterSet\"!)*"
        case .consume(let rule):
            ruleType = "\(rule)-"
        case .lookahead(let rule):
            ruleType = ">>(\(rule))"
        case .not(let rule):
            ruleType = "\(rule)-"
        case .custom(_, _, let description, _):
            ruleType = description
        }
        
        if !produces.transient {
            return "\(produces) = \(annotations.stlrDescription) \(ruleType)"
        }
        
        return "\(annotations.stlrDescription) \(ruleType)"
    }
    
    /// Matches a terminal input sequence
    case terminal(produces: Token, String, RuleAnnotations?)

    /// Captures terminals until it hits the supplied string
    case terminalUntil(produces: Token, String, RuleAnnotations?)

    /// Captures terminals  until it hits a character of the supplied set
    case terminalUntilOneOf(produces: Token, CharacterSet, RuleAnnotations?)
    
    /// Matches one of a character set
    case terminalFrom(produces:Token, CharacterSet, RuleAnnotations?)
 
    /// Matches a sequence of rules
    case sequence(produces:Token, [Rule] , RuleAnnotations?)
    
    /// Matches one of a series of alternatives
    case oneOf(produces:Token, [Rule], RuleAnnotations?)
    
    /// Matches another rule with the specified bounds
    case repeated(produces:Token, Rule,min:Int?,limit:Int?, RuleAnnotations?)
    
    /// Matches 0 or 1 of the given rule
    case optional(produces:Token, Rule, RuleAnnotations?)
    
    /// Requires that the rule is matched, but the generated token will be consumed 
    /// and not passed to the IntermediateRepresentation
    case consume(Rule, RuleAnnotations?)
    
    /// Determines if the rule would match, but produces no tokens
    case lookahead(Rule, RuleAnnotations?)
    
    case not(produces: Token, Rule, RuleAnnotations?)
    
    case custom(produces: Token, CustomRuleClosure,String, RuleAnnotations?)
}

final private class LookAheadIR : IntermediateRepresentation{
    final fileprivate func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        return nil
    }
    
    final fileprivate func didEvaluate(rule: Rule, matchResult: MatchResult) {
    }
    
    final fileprivate func willBuildFrom(source: String, with: Language) {
    }
    
    final fileprivate func didBuild() {
    }
    
    func resetState() {
    }
}
