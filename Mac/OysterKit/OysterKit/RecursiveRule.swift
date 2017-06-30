//
//  RecursiveRule.swift
//  OysterKit
//
//  Created by Nigel Hughes on 15/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public class RecursiveRule : Rule{
    private var initBlock : (()->Rule)?
    
    public init(){
        
    }
    
    public init(initializeWith lazyBlock:(()->Rule)?){
        self.initBlock = lazyBlock
    }
    
    private var _matcher     : ((_ lexer : LexicalAnalyzer, _ ir:IntermediateRepresentation) throws -> MatchResult)?
    private var _produces    : Token!
    private var _annotations : RuleAnnotations?
    
    private final func lazyInit(_ initBlock: ()->Rule){
        let rule = initBlock()
        _matcher     = rule.match
        _produces    = rule.produces
        self.initBlock = nil
    }
    
    public var surrogateRule : Rule? {
        get{
            return nil
        }
        set {
            guard let  newRule = newValue else {
                return
            }
            initBlock = nil
            _matcher = newRule.match
            _produces = newRule.produces
        }
    }
    
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        if let initBlock = initBlock {
            lazyInit(initBlock)
        }
        
        return try _matcher?(lexer, ir) ?? MatchResult.failure(atIndex: lexer.index)
    }
    
    public var produces: Token {
        if let initBlock = initBlock {
            lazyInit(initBlock)
        }
        
        return _produces
    }
    
    public var annotations: RuleAnnotations{
        get {
            return _annotations ?? [:]
        }
        set{
            _annotations = newValue
        }
    }
    
    
}
