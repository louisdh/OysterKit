//
//  TestErrors.swift
//  OysterKit
//
//  Created by Nigel Hughes on 19/07/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
import OysterKit

class TestErrors: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStringRanges(){
        let string = "x"
        
        let startIndex = string.unicodeScalars.startIndex
        let endEnd = string.unicodeScalars.index(after: startIndex)
        
        let endEndEnd = string.unicodeScalars.index(after: endEnd)
        
        XCTAssert(string == "\(string.unicodeScalars[startIndex..<endEnd])")
        XCTAssert(string == "\(string.unicodeScalars[startIndex..<endEndEnd])")
    }

    func testDescriptions() {
        XCTAssert(GrammarError.notImplemented.description == "Operation not implemented")
        XCTAssert(GrammarError.noTokenCreatedFromMatch.description == "No token created from a match")
        XCTAssert(GrammarError.matchFailed.description == "Match failed")
    }
}
