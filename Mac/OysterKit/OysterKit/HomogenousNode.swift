//
//  HomogenousNode.swift
//  OysterKit
//
//  Created by Nigel Hughes on 26/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public struct HomogenousNode : Node {
    public      let token       : Token
    public      let range       : Range<String.UnicodeScalarView.Index>
    
    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>) {
        self.token = token
        self.range = range
    }
    
    public var description: String{
        return "\(token)"
    }
    
}

public extension Node{
    public func matchedString(_ scalars:String.UnicodeScalarView)->String{
        return "\(scalars[range])"
    }
    
    public func matchedString(_ string:String)->String{
        return matchedString(string.unicodeScalars)
    }
}

