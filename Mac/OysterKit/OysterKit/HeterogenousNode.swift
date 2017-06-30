//
//  Heterogenous Node.swift
//  OysterKit
//
//  Created by Nigel Hughes on 26/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public protocol ValuedNode : Node {
    init(`for` token:Token, at range:Range<String.UnicodeScalarView.Index>, value :Any?)

    var value : Any? { get }
}

public extension ValuedNode{
    
    public var description: String{
        return "\(token):\(value)"
    }
    
    public func cast<N>()->N?{
        return value as? N
    }
    
    public subscript(_ token:Token)->Self?{
        if let children : [Self] = cast() {
            return children[token]?.cast()
        }
        
        return nil
    }
    
    public subscript(_ index:Int)->Self?{
        if let children : [Self] = cast(){
            if children.count > index && index >= 0{
                return children[index]
            }
            
            return nil
        }
        
        if index == 0 {
            return value as? Self
        }
        
        return nil
    }

}



public extension Collection where Iterator.Element : ValuedNode {
    public subscript(token:Token)->ValuedNode?{
        let allMatches = flatMap({ (match)->ValuedNode? in
            return match.token == token ? match : nil
        })
        
        switch allMatches.count {
        case 0:
            return nil
        case 1:
            return allMatches[0]
        default:
            let finalRange = reduce(first!.range, { (rangeSoFar, nextChild) -> Range<String.UnicodeScalarView.Index> in
                let lowerBound = rangeSoFar.lowerBound < nextChild.range.lowerBound ? rangeSoFar.lowerBound : nextChild.range.lowerBound
                let upperBound = rangeSoFar.upperBound > nextChild.range.upperBound ? rangeSoFar.upperBound : nextChild.range.upperBound
                
                return lowerBound..<upperBound
            })
            
            return Iterator.Element(for: token, at: finalRange, value: allMatches)
        }
    }
    
    public func child<N>(token:Token)->N?{
        for child in self{
            if child.token == token {
                return child.cast()
            }
        }
        
        return nil
    }
}

public struct HeterogeneousNode : ValuedNode {
    public      let token       : Token
    public      let range       : Range<String.UnicodeScalarView.Index>
    public      let value       : Any?
    
    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>) {
        self.token = token
        self.range = range
        self.value = nil
    }

    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, value:Any?) {
        self.token = token
        self.range = range
        self.value = value
    }
    
}
