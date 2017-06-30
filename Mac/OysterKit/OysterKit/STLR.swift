//
// STLR Generated Swift File
//
// Generated: 2016-08-26 06:53:35 +0000
//
import Foundation

//
// STLR Parser
//
public enum STLR : Int, Token {
    
    // Convenience alias
    private typealias T = STLR
    
    case _transient, singleLineComment, multilineComment, comment, whitespace, ows, quantifier, negated, transient, lookahead, stringQuote, escapedCharacter, stringCharacter, terminalBody, stringBody, string, terminalString, characterSetName, characterSet, rangeOperator, characterRange, number, boolean, literal, annotation, annotations, customLabel, definedLabel, label, terminal, group, identifier, element, assignmentOperators, or, then, choice, notNewRule, sequence, expression, lhs, rule, moduleName, moduleImport, grammar
    
    func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
        switch self {
        case ._transient:
            return CharacterSet(charactersIn: "").terminal(token: T._transient)
        // singleLineComment
        case .singleLineComment:
            return [
                "//".terminal(token: T._transient),
                CharacterSet.newlines.terminal(token: T._transient).not(producing: T._transient).repeated(min: 0, producing: T._transient),
                CharacterSet.newlines.terminal(token: T._transient),
                ].sequence(token: T.singleLineComment, annotations: annotations.isEmpty ? [ : ] : annotations)
        // multilineComment
        case .multilineComment:
            guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    "/*".terminal(token: T._transient),
                    [
                        T.multilineComment._rule(),
                        "*/".terminal(token: T._transient).not(producing: T._transient),
                        ].oneOf(token: T._transient).repeated(min: 0, producing: T._transient),
                    "*/".terminal(token: T._transient),
                    ].sequence(token: T.multilineComment, annotations: annotations.isEmpty ? [ : ] : annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // comment
        case .comment:
            return [
                T.singleLineComment._rule(),
                T.multilineComment._rule(),
                ].oneOf(token: T.comment)
        // whitespace
        case .whitespace:
            return [
                T.comment._rule(),
                CharacterSet.whitespacesAndNewlines.terminal(token: T._transient),
                ].oneOf(token: T.whitespace)
        // ows
        case .ows:
            return T.whitespace._rule().repeated(min: 0, producing: T.ows)
        // quantifier
        case .quantifier:
            return CharacterSet(charactersIn: "*+?-").terminal(token: T.quantifier)
        // negated
        case .negated:
            return "!".terminal(token: T.negated)
        // transient
        case .transient:
            return "-".terminal(token: T.transient)
        // lookahead
        case .lookahead:
            return ">>".terminal(token: T.lookahead)
        // stringQuote
        case .stringQuote:
            return "\"".terminal(token: T.stringQuote)
        // escapedCharacter
        case .escapedCharacter:
            return [
                "\\".terminal(token: T._transient),
                CharacterSet(charactersIn: "\"rnt\\").terminal(token: T._transient),
                ].sequence(token: T.escapedCharacter, annotations: annotations.isEmpty ? [ : ] : annotations)
        // stringCharacter
        case .stringCharacter:
            return [
                T.escapedCharacter._rule(),
                [
                    T.stringQuote._rule(),
                    CharacterSet.newlines.terminal(token: T._transient),
                    ].oneOf(token: T._transient).not(producing: T._transient),
                ].oneOf(token: T.stringCharacter)
        // terminalBody
        case .terminalBody:
            return T.stringCharacter._rule().repeated(min: 1, producing: T.terminalBody)
        // stringBody
        case .stringBody:
            return T.stringCharacter._rule().repeated(min: 0, producing: T.stringBody)
        // string
        case .string:
            return [
                "\"".terminal(token: T._transient),
                T.stringBody._rule(),
                "\"".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote")]),
                ].sequence(token: T.string, annotations: annotations.isEmpty ? [ : ] : annotations)
        // terminalString
        case .terminalString:
            return [
                "\"".terminal(token: T._transient),
                T.terminalBody._rule([RuleAnnotation.error : RuleAnnotationValue.string("Terminals must have at least one character")]),
                "\"".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote")]),
                ].sequence(token: T.terminalString, annotations: annotations.isEmpty ? [ : ] : annotations)
        // characterSetName
        case .characterSetName:
            return ScannerRule.oneOf(token: T.characterSetName, ["letters", "uppercaseLetters", "lowercaseLetters", "alphaNumerics", "decimalDigits", "whitespacesAndNewlines", "whitespaces", "newlines"],[ : ].merge(with: annotations))
        // characterSet
        case .characterSet:
            return [
                ".".terminal(token: T._transient),
                T.characterSetName._rule([RuleAnnotation.error : RuleAnnotationValue.string("Unknown character set")]),
                ].sequence(token: T.characterSet, annotations: annotations.isEmpty ? [ : ] : annotations)
        // rangeOperator
        case .rangeOperator:
            return [
                ".".terminal(token: T._transient),
                "..".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected ... in character range")]),
                ].sequence(token: T.rangeOperator, annotations: annotations.isEmpty ? [ : ] : annotations)
        // characterRange
        case .characterRange:
            return [
                T.terminalString._rule(),
                T.rangeOperator._rule(),
                T.terminalString._rule([RuleAnnotation.error : RuleAnnotationValue.string("Range must be terminated")]),
                ].sequence(token: T.characterRange, annotations: annotations.isEmpty ? [ : ] : annotations)
        // number
        case .number:
            return [
                CharacterSet(charactersIn: "-+").terminal(token: T._transient).optional(producing: T._transient),
                CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                ].sequence(token: T.number, annotations: annotations.isEmpty ? [ : ] : annotations)
        // boolean
        case .boolean:
            return ScannerRule.oneOf(token: T.boolean, ["true", "false"],[ : ])
        // literal
        case .literal:
            return [
                T.string._rule(),
                T.number._rule(),
                T.boolean._rule(),
                ].oneOf(token: T.literal)
        // annotation
        case .annotation:
            return [
                "@".terminal(token: T._transient),
                T.label._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected an annotation label")]),
                [
                    "(".terminal(token: T._transient),
                    T.literal._rule([RuleAnnotation.error : RuleAnnotationValue.string("A value must be specified or the () omitted")]),
                    ")".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing ')'")]),
                    ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).optional(producing: T._transient),
                ].sequence(token: T.annotation, annotations: annotations.isEmpty ? [ : ] : annotations)
        // annotations
        case .annotations:
            return [
                T.annotation._rule(),
                T.ows._rule(),
                ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).repeated(min: 1, producing: T.annotations)
        // customLabel
        case .customLabel:
            return [
                CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
                CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.customLabel, annotations: annotations.isEmpty ? [ : ] : annotations)
        // definedLabel
        case .definedLabel:
            return ScannerRule.oneOf(token: T.definedLabel, ["token", "error", "void", "transient"],[ : ])
        // label
        case .label:
            return [
                T.definedLabel._rule(),
                T.customLabel._rule(),
                ].oneOf(token: T.label)
        // terminal
        case .terminal:
            return [
                T.characterSet._rule(),
                T.characterRange._rule(),
                T.terminalString._rule(),
                ].oneOf(token: T.terminal)
        // group
        case .group:
            guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    "(".terminal(token: T._transient),
                    T.whitespace._rule().repeated(min: 0, producing: T._transient),
                    T.expression._rule(),
                    T.whitespace._rule().repeated(min: 0, producing: T._transient),
                    ")".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected ')'")]),
                    ].sequence(token: T.group, annotations: annotations.isEmpty ? [ : ] : annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // identifier
        case .identifier:
            return [
                CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
                CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.identifier, annotations: annotations.isEmpty ? [ : ] : annotations)
        // element
        case .element:
            guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.annotations._rule().optional(producing: T._transient),
                    [
                        T.lookahead._rule(),
                        T.transient._rule(),
                        ].oneOf(token: T._transient).optional(producing: T._transient),
                    T.negated._rule().optional(producing: T._transient),
                    [
                        T.group._rule(),
                        T.terminal._rule(),
                        T.identifier._rule(),
                        ].oneOf(token: T._transient),
                    T.quantifier._rule().optional(producing: T._transient),
                    ].sequence(token: T.element, annotations: annotations.isEmpty ? [ : ] : annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // assignmentOperators
        case .assignmentOperators:
            return ScannerRule.oneOf(token: T.assignmentOperators, ["=", "+=", "|="],[ : ])
        // or
        case .or:
            return [
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                "|".terminal(token: T._transient),
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                ].sequence(token: T.or, annotations: annotations.isEmpty ? [ : ] : annotations)
        // then
        case .then:
            return [
                [
                    T.whitespace._rule().repeated(min: 0, producing: T._transient),
                    "+".terminal(token: T._transient),
                    T.whitespace._rule().repeated(min: 0, producing: T._transient),
                    ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations),
                T.whitespace._rule().repeated(min: 1, producing: T._transient),
                ].oneOf(token: T.then)
        // choice
        case .choice:
            guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.element._rule(),
                    [
                        T.or._rule(),
                        T.element._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected terminal, identifier, or group")]),
                        ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).repeated(min: 1, producing: T._transient),
                    ].sequence(token: T.choice, annotations: annotations.isEmpty ? [ : ] : annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // notNewRule
        case .notNewRule:
            return [
                T.annotations._rule().optional(producing: T._transient),
                T.identifier._rule(),
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                T.assignmentOperators._rule(),
                ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).not(producing: T.notNewRule)
        // sequence
        case .sequence:
            guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.element._rule(),
                    [
                        T.then._rule(),
                        T.notNewRule._rule().lookahead(),
                        T.element._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected terminal, identifier, or group")]),
                        ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).repeated(min: 1, producing: T._transient),
                    ].sequence(token: T.sequence, annotations: annotations.isEmpty ? [ : ] : annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // expression
        case .expression:
            guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.choice._rule(),
                    T.sequence._rule(),
                    T.element._rule(),
                    ].oneOf(token: T.expression)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // lhs
        case .lhs:
            return [
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                T.annotations._rule().optional(producing: T._transient),
                T.transient._rule().optional(producing: T._transient),
                T.identifier._rule(),
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                T.assignmentOperators._rule(),
                ].sequence(token: T.lhs, annotations: annotations.isEmpty ? [ : ] : annotations)
        // rule
        case .rule:
            return [
                T.lhs._rule(),
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                T.expression._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected expression")]),
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                ].sequence(token: T.rule, annotations: annotations.isEmpty ? [ : ] : annotations)
        // moduleName
        case .moduleName:
            return [
                CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
                CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.moduleName, annotations: annotations.isEmpty ? [ : ] : annotations)
        // moduleImport
        case .moduleImport:
            return [
                T.whitespace._rule().repeated(min: 0, producing: T._transient),
                "import".terminal(token: T._transient),
                CharacterSet.whitespaces.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                T.moduleName._rule(),
                T.whitespace._rule().repeated(min: 1, producing: T._transient),
                ].sequence(token: T.moduleImport, annotations: annotations.isEmpty ? [ : ] : annotations)
        // grammar
        case .grammar:
            return [
                T.moduleImport._rule().repeated(min: 0, producing: T._transient),
                T.rule._rule().repeated(min: 1, producing: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected at least one rule")]),
                ].sequence(token: T.grammar, annotations: annotations.isEmpty ? [ : ] : annotations)
        }
    }
    
    // Color Definitions
    fileprivate var color : NSColor? {
        switch self {
        case .comment:	return #colorLiteral(red:0.11457, green:0.506016, blue:0.128891, alpha: 1)
        case .quantifier:	return #colorLiteral(red:1.0, green:0.578105, blue:0.0, alpha: 1)
        case .lookahead:	return #colorLiteral(red:1.0, green:0.578105, blue:0.0, alpha: 1)
        case .string:	return #colorLiteral(red:0.815686, green:0.129412, blue:0.12549, alpha: 1)
        case .terminalString:	return #colorLiteral(red:0.815686, green:0.129412, blue:0.12549, alpha: 1)
        case .characterSet:	return #colorLiteral(red:0.513726, green:0.215686, blue:0.843137, alpha: 1)
        case .characterRange:	return #colorLiteral(red:0.815686, green:0.129412, blue:0.12549, alpha: 1)
        case .literal:	return #colorLiteral(red:0.815686, green:0.129412, blue:0.12549, alpha: 1)
        case .annotations:	return #colorLiteral(red:0.11457, green:0.506016, blue:0.128891, alpha: 1)
        case .terminal:	return #colorLiteral(red:0.11457, green:0.506016, blue:0.128891, alpha: 1)
        case .identifier:	return #colorLiteral(red:0.370555, green:0.370565, blue:0.37056, alpha: 1)
        case .moduleName:	return #colorLiteral(red:0.370555, green:0.370565, blue:0.37056, alpha: 1)
        default:	return nil
        }
    }
    
    
    // Color Dictionary
    static var tokenNameColorIndex = ["comment" : T.comment.color!, "quantifier" : T.quantifier.color!, "lookahead" : T.lookahead.color!, "string" : T.string.color!, "terminalString" : T.terminalString.color!, "characterSet" : T.characterSet.color!, "characterRange" : T.characterRange.color!, "literal" : T.literal.color!, "annotations" : T.annotations.color!, "terminal" : T.terminal.color!, "identifier" : T.identifier.color!, "moduleName" : T.moduleName.color!]
    
    // Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : Rule ]()
    
    // Create a language that can be used for parsing etc
    public static var generatedLanguage : Parser {
        return Parser(grammar: [T.grammar._rule()])
    }
    
    // Convient way to apply your grammar to a string
    public static func parse(source: String) -> DefaultHeterogeneousAST {
        return STLR.generatedLanguage.build(source: source)
    }
}
