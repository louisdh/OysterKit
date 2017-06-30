//
//  IntermediateRepresentation.swift
//  OysterKit
//
//  Created by Nigel Hughes on 15/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public protocol Node : CustomStringConvertible{
    var token               : Token { get }
    var range               : Range<String.UnicodeScalarView.Index> { get }
    
    init(`for` token:Token, at range:Range<String.UnicodeScalarView.Index>)
}

public protocol IRIndependantNode : Node {
    mutating func setup<N:Node>(`in` context:LexicalContext, with children:[N])
}

public protocol IntermediateRepresentation : class {
    init()

    func willEvaluate(rule:Rule, at position:String.UnicodeScalarView.Index)->MatchResult?
    func didEvaluate(rule:Rule, matchResult:MatchResult)
    
    func willBuildFrom(source:String, with: Language)
    func didBuild()
    
    func resetState()
}
