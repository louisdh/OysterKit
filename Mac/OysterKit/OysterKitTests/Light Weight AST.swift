//
//  Light Weight AST.swift
//  OysterKit
//
//  Created by Nigel Hughes on 15/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation
import OysterKit

final class LightWeightNode : Node, CustomStringConvertible{
    let token   : Token
    let _range   : Range<String.UnicodeScalarView.Index>
    let children: [LightWeightNode]?
    
    init(for token: Token, at range: Range<String.UnicodeScalarView.Index>) {
        fatalError("Should not be created by anything other than ColoringIR")
    }
    
    init(for token: Token, range: Range<String.UnicodeScalarView.Index>, children:[LightWeightNode]?){
        self.token = token
        self._range = range
        self.children = children
    }
    
    var range : Range<String.UnicodeScalarView.Index> {
        if let firstChild = children?.first, let lastChild = children?.last{
            return firstChild.range.lowerBound..<lastChild.range.upperBound
        } else {
            return _range
        }
    }
    
    final var description: String{
        return "\(token)"
    }

}

final class LightWeightAST : IntermediateRepresentation{
    private var     scalars   : String.UnicodeScalarView!
    private var     nodeStack = NodeStack<LightWeightNode>()
    
    var     children  : [LightWeightNode]{
        return nodeStack.top?.nodes ?? []
    }
    
    init() {
    }
    
    func resetState() {
        nodeStack.reset()
    }
    
    final func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        nodeStack.push()
        return nil
    }
    
    final func willBuildFrom(source: String, with: Language) {
        scalars = source.unicodeScalars
        nodeStack.reset()
    }
    
    final func didBuild() {
        
    }
    
    let ignoreNodes : Set<String> =  ["whitespace","comment","oneLineComment","oneLineCommentStart","restOfLine","character","newline","step","then","or"]
    
    final func didEvaluate(rule: Rule, matchResult: MatchResult) {
        let children = nodeStack.pop()
        
        switch matchResult {
        case .success(let context):
            if rule.produces.rawValue == 0 || ignoreNodes.contains("\(rule.produces)"){
                nodeStack.top?.adopt(children.nodes)
                return
            }
            
            let newNode : LightWeightNode
            if children.nodes.count > 0 {
                newNode = LightWeightNode(for: rule.produces, range: context.range, children: children.nodes)
            } else {
                newNode = LightWeightNode(for: rule.produces, range: context.range, children: nil)
            }
            
            nodeStack.top?.append(newNode)
        default: return
        }
    }
    
}
