//
//  HeterogenousAST.swift
//  OysterKit
//
//  Created by Nigel Hughes on 16/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public final class DefaultHeterogenousConstructor : ASTNodeConstructor{
    public typealias NodeType =  HeterogeneousNode
    
    public init(){
        
    }
    
    public func begin(with source: String) {
        
    }
    
    final public func match(token: Token, context: LexicalContext, children: [HeterogeneousNode]) -> HeterogeneousNode? {
        guard !token.transient else {
            return nil
        }
        
        switch children.count{
        case 0:
            return HeterogeneousNode(for: token, at: context.range, value: nil)
        case 1:
            return HeterogeneousNode(for: token, at: children[0].range, value: children[0].value)
        default:
            return HeterogeneousNode(for: token, at: children.combinedRange, value: children)
        }
        
    }

    public func ignoreableFailure(token: Token) {
        
    }
    
    public func failed(token: Token) {
        
    }
    
    public func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
}

public typealias DefaultHeterogeneousAST = HeterogenousAST<HeterogeneousNode,DefaultHeterogenousConstructor>

public final class HeterogenousAST<NodeType : ValuedNode, Constructor : ASTNodeConstructor> : HomogenousAST<NodeType,Constructor> where Constructor.NodeType == NodeType{
    
}


