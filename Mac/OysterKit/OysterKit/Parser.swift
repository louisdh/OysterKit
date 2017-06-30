//
//  Compiler.swift
//  OysterKit
//
//  Created by Nigel Hughes on 21/07/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

open class Parser : Language{
    public let grammar : [Rule]
    
    public init(grammar:[Rule]){
        self.grammar = grammar
    }
    
}
