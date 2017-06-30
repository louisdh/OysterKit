//
//  String Extensions.swift
//  OysterKit
//
//  Created by Nigel Hughes on 24/08/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation


public extension String.UnicodeScalarView{

    public func length(of range:Range<String.UnicodeScalarView.Index>)->Int{
        let range = range.clamped(to: startIndex..<endIndex)
        
        return distance(from: range.lowerBound, to: range.upperBound)
    }
    
}
