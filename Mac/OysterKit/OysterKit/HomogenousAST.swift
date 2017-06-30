//
//  HomogenousAST.swift
//  OysterKit
//
//  Created by Nigel Hughes on 26/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public protocol ASTNodeConstructor{
    associatedtype  NodeType : Node
    
    init()
    
    func begin(with source:String)
    
    func match(token:Token, context: LexicalContext, children: [NodeType])->NodeType?
    func ignoreableFailure(token:Token)
    func failed(token:Token)
    
    func complete(parsingErrors: [Error])->[Error]
}

final class DefaultConstructor<N:Node> : ASTNodeConstructor{
    typealias NodeType = N
    
    init(){
        
    }
    
    final func match(token: Token, context: LexicalContext, children: [N]) -> N? {
        guard !token.transient else {
            return nil
        }
        
        switch children.count{
        case 0:
            return N(for: token, at: context.range)
        case 1:
            return N(for: token, at: children[0].range)
        default:
            return N(for: token, at: children.combinedRange)
        }
        
    }
    
    final func ignoreableFailure(token: Token){
    }
    
    final internal func failed(token: Token){
    }
    
    final internal func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
    
    final internal func begin(with source: String) {
        
    }
}

final public class DefaultHomogenousAST<NodeType:Node> : HomogenousAST<NodeType, DefaultConstructor<NodeType>>{
    required public init() {
        super.init()
    }
}

public class HomogenousAST<NodeType : Node, Constructor : ASTNodeConstructor> : IntermediateRepresentation where Constructor.NodeType == NodeType{
    private var     scalars   : String.UnicodeScalarView!
    private var     nodeStack = NodeStack<NodeType>()
    private var     _errors     = [Error]()
    public  let     constructor : Constructor
    
    public  var     errors : [Error] {
        return _errors
    }
    
    var     children  : [NodeType]{
        return nodeStack.top?.nodes ?? []
    }
    
    public var tokens : [NodeType]{
        return children
    }
    
    public required init(){
        constructor = Constructor()
    }
    
    public init(constructor:Constructor) {
        self.constructor = constructor
    }
    
    final public func resetState() {
        nodeStack.reset()
        _errors.removeAll()
    }
    
    final public func willBuildFrom(source: String, with: Language) {
        scalars = source.unicodeScalars
        resetState()
    }
    
    final public func didBuild() {
        _errors = constructor.complete(parsingErrors: _errors)
    }
    
    final public func willEvaluate(rule: Rule, at position:String.UnicodeScalarView.Index)->MatchResult?{
        nodeStack.push()
        return nil
    }
    
    
    final public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        let children = nodeStack.pop()
        
        switch matchResult {
        case .success(let context):
            //If the rule is void return nothing
            if rule.void {
                return
            }
            
            // If it's transient, or the constructor produces no nodes then the current top should adopt the children
            guard let node = rule.transient ? nil : constructor.match(token: rule.produces, context: context, children: children.nodes) else {
                nodeStack.top?.adopt(children.nodes)
                return
            }
            
            nodeStack.top?.append(node)
        case .ignoreFailure:
            constructor.ignoreableFailure(token: rule.produces)
            nodeStack.top?.adopt(children.nodes)
        case .failure(let index):
            //If we have an error on the rule
            if let error = rule.error {
                let errorEnd = scalars.index(after:index)
                let parsingError = LanguageError.parsingError(at: index..<errorEnd, message: error)

                let existing = _errors.flatMap({ (error)->Error? in
                    if let error = error as? LanguageError {
                        if error == parsingError {
                            return error
                        }
                    }
                    return nil
                })
                
                if existing.count == 0{
                    _errors.append(parsingError)
                }
                
            }
            constructor.failed(token: rule.produces)
        case .consume:
            break
        }
    }
    
    private func describe(entry:NodeStackEntry<NodeType>)->String{
        var result = ""
        
        result += entry.nodes.map({ (entry)->String in
            return "entry.description"
        }).joined(separator: ", ")
        
        return "[\(result)]"
    }
    
    public var description: String{
        var result = ""
        for entry in nodeStack.all {
            result += describe(entry: entry)
        }
        
        return result
    }
    
    
}
