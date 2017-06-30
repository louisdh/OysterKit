//
//  GrammarTest.swift
//  OysterKit
//
//  Created by Nigel Hughes on 19/07/2016.
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit

extension String {
    mutating func add(line: String){
        self = self + line + "\n"
    }
}

class GrammarTest: XCTestCase {

    var source = ""
    
    override func setUp() {
        super.setUp()
        source = ""
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testString(){
        let testData = [
            (" ",true,1),
            ("\\\"",true,2),
            ("\"something longer",false,17),
            ]
        
        
        
        for test in testData{
            let parser = TestParser(source: "\"\(test.0)\"", grammar: [STLR.terminalString._rule()])
            
            guard let result = parser.makeIterator().next() else {
                XCTAssert(!test.1, "Tokenization failed when it should have succeeded for \(test.0)")
                continue
            }
            
            XCTAssert(test.1, "Tokenization succeeded when it should have failed for: "+test.0)
            XCTAssert(result.token == STLR.terminalString, "Incorrect token type \(result.token)")
        }
    }

    func testIdentifier(){
        let testIds = [
            ("x",true),
            ("xX",true),
            ("x2",true),
            ("2",false),
            ("x_2",true),
            ("_2",true),
        ]
        
        for test in testIds{
            let parser = TestParser(source: test.0, grammar: [STLR.identifier._rule()])
            
            guard let result = parser.makeIterator().next() else {
                XCTAssert(!test.1, "Tokenization failed when it should have succeeded for \(test.0)")
                continue
            }
            
            XCTAssert(test.1, "Tokenization succeeded when it should have failed")
            XCTAssert(result.token == STLR.identifier, "Incorrect token type \(result.token)")
            
//            XCTAssert(result[test.0] == test.0, "Incorrect token value \(result[source])")
            
        }
    }
    
    func testRuleWithTerminal(){
        source.add(line: "x = \"x\"")
        
        let stlr = STLRParser(source: source)
        
        let ast = stlr.ast
        
        XCTAssert(ast.rules.count == 1, "Found \(ast.rules.count) rules when there should be 1")
        
        if ast.rules.count < 1 {
            return
        }
        
        XCTAssert(ast.rules[0].identifier?.name ?? "fail" == "x")
    }

    func checkGeneratedLanguage(language:Language?, on source:String, expecting: [Int]) throws {
        guard let language = language else {
            throw CheckError.checkFailed(reason: "Language did not compile")
        }
        
        let stream : AnySequence<HomogenousNode> = language.stream(source: source)
        
        let iterator = stream.makeIterator()
        
        var acquiredTokens = [Token]()
        var count = 0
        while let node = iterator.next() {
            acquiredTokens.append(node.token)
            if expecting.count > count {
                if node.token.rawValue != expecting[count] {
                    throw CheckError.checkFailed(reason: "Token at position \(count) was \(node.token)[\(node.token.rawValue)] but expected \(expecting[count])")
                }
            } else {
                throw CheckError.checkFailed(reason: "Moved past of the end of the expected list")
            }
            count += 1
        }

        if count != expecting.count {
            throw CheckError.checkFailed(reason: "Incorrect tokens count \(expecting.count) but got \(count) in \(acquiredTokens)")
        }
    }
    
    enum CheckError : Error, CustomStringConvertible {
        case checkFailed(reason: String)

        var description: String{
            switch  self {
            case .checkFailed(let reason):
                return reason
            }
        }
    }
    
    func generateAndCheck(grammar:String, parsing testString:String, expecting: [String]) throws {
        let language = STLRParser(source: grammar)
        let ast = language.ast
        
        guard let parser = ast.runtimeLanguage else {
            throw CheckError.checkFailed(reason: "Could not generate runtime language")
        }
        
        var count = 0
        
        for node in parser.stream(source: testString) as AnySequence<HomogenousNode> {
            if count >= expecting.count{
                throw CheckError.checkFailed(reason: "Too many tokens")
            }
            
            if expecting[count] != "\(node.token)" {
                throw CheckError.checkFailed(reason: "At position \(count) expected \(expecting[count]) but got \(node.token)")
            }
            
            count += 1
        }
    }
    
    func testInlineError(){
        source.add(line: "xy = \"x\" @error(\"expected y\")@custom\"y\"")
        
        let parser = STLRParser(source: source)
        
        guard parser.ast.rules.count == 1 else {
            XCTFail("Expected just one rule but got \(parser.ast.rules.count): \(parser.ast.rules)")
            return
        }
        
        guard let language = parser.ast.runtimeLanguage else {
            XCTFail("Could not generate runtime language")
            return
        }
        
        let ir = language.build(source: "xx") as DefaultHomogenousAST<HomogenousNode>
        
        guard ir.errors.count == 1 else {
            XCTFail("Expected a single error but got \(ir.errors)")
            return
        }
        
        let errorText = "\(ir.errors[0])"
        
        XCTAssert(errorText.hasPrefix("expected y"), "Unexpected error \(errorText)")
    }
    
    func testRecursiveRule(){
        source.add(line: "xy = x \"y\"")
        source.add(line: "justX = x")
        source.add(line: "x = \"x\"")
        
        let stlr = STLRParser(source: source)
        
        let ast = stlr.ast
        
        XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 1")
        XCTAssert(ast.rules[0].identifier?.name ?? "fail" == "xy")
        XCTAssert(ast.rules[1].identifier?.name ?? "fail" == "justX")
        XCTAssert(ast.rules[2].identifier?.name ?? "fail" == "x")
        
        do {
            try checkGeneratedLanguage(language: ast.runtimeLanguage, on: "xyx", expecting: [1,3])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    func testSimpleLookahead(){
        source.add(line: "x  = \"x\" >>!\"y\" ")
        source.add(line: "xy = \"x\" \"y\" ")
        
        let stlr = STLRParser(source: source)
        
        let ast = stlr.ast
        guard ast.rules.count == 2 else {
            XCTFail("Found \(ast.rules.count) rules when there should be 2")
            return
        }
        
        XCTAssert(ast.rules[0].identifier?.name ?? "fail" == "x")
        XCTAssert(ast.rules[1].identifier?.name ?? "fail" == "xy")
        
        do {
            try checkGeneratedLanguage(language: ast.runtimeLanguage, on: "xxyx", expecting: [1,2,1])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    func testQuantifiersNotAddedToIdentifierNames(){
        source.add(line: "ws = .whitespaces")
        source.add(line: "whitespace = ws+")
        source.add(line: "word = .letters+")
        
        let stlr = STLRParser(source: source)
        
        let ast = stlr.ast
        
        XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 1")
        XCTAssert(ast.rules[0].identifier?.name ?? "fail" == "ws")
        XCTAssert(ast.rules[1].identifier?.name ?? "fail" == "whitespace")
        XCTAssert(ast.rules[2].identifier?.name ?? "fail" == "word")
        
        do {
            try checkGeneratedLanguage(language: ast.runtimeLanguage, on: "hello world", expecting: [3,2,3])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    func testRuleWithIdentifier(){
        source.add(line: "x = y ;")
        
        let stlr = STLRParser(source: source)
        
        let ast = stlr.ast
        
        XCTAssert(ast.rules.count == 1, "Found \(ast.rules.count) rules when there should be 1")
        
        if ast.rules.count < 1 {
            return
        }
        
        XCTAssert(ast.rules[0].identifier?.name ?? "fail" == "x")
    }
    

    

    
    func testShallowFolding(){
        let source = "space = .whitespaces \nspaces = space+\n"
        
        let testString = "    "
        
        do {
            try generateAndCheck(grammar: source, parsing: testString, expecting: ["spaces"])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    func testWords(){
        let source = "capitalLetter = \"A\"...\"Z\"\nlowercaseLetter = \"a\"...\"z\"\nlowercaseWord = lowercaseLetter+\ncapitalizedWord = capitalLetter lowercaseLetter*\nword = capitalizedWord | lowercaseWord\nspace = .whitespaces \nspaces = space+\n"
        
        let testString = "Hello  world"
        
        do {
            try generateAndCheck(grammar: source, parsing: testString, expecting: ["word","spaces","word"])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    
    func testTerminal() {
        source.add(line: "x = \"x\"")
        source.add(line: "y = \"y\"")
        source.add(line: "z=\"z\"")

        let stlr = STLRParser(source: source)

        let ast = stlr.ast

        XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 3")
        
        if ast.rules.count < 3 {
            return
        }

        XCTAssert(ast.rules[0].identifier?.name ?? "fail" == "x")
        XCTAssert(ast.rules[1].identifier?.name ?? "fail" == "y")
        XCTAssert(ast.rules[2].identifier?.name ?? "fail" == "z")
    }
    
    func testCompoundDeclarations(){
        source.add(line: "xy = \"x\"")
        source.add(line: "xy = \"y\"")
        
        let parser = STLRParser(source: source)
        
        guard let compiledLanguage = parser.ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        let test = "xxxxyyyxyxy"
        let result : DefaultHomogenousAST<HomogenousNode> = compiledLanguage.build(source: test)
        
        guard result.errors.isEmpty else {
            XCTFail("Unexpected error \(result.errors)")
            return
        }
        
        XCTAssert(result.children.count == test.characters.count, "Expected \(test.characters.count) tokens but got \(result.children.count)")
    }
    
    func testUnknownCharacterSet(){
        source.add(line: "hello = \"hello\" .whiteSpacesAndNewlines")
        
        let parser = STLRParser(source: source)
        
        guard parser.ast.errors.count == 2 else {
            XCTFail("Expected one error but got \(parser.errors)")
            return
        }
        
        XCTAssert("\(parser.ast.errors[0])".hasPrefix("Unknown character set"),"Incorrect error \(parser.ast.errors[0])")
        XCTAssert("\(parser.ast.errors[1])".hasPrefix("Expected at least one rule"),"Incorrect error \(parser.ast.errors[0])")
    }
    
    func testUnterminatedString(){
        source.add(line: "hello = \"hello")
        
        let parser = STLRParser(source: source)
        
        guard parser.errors.count == 3 else {
            XCTFail("Expected one error but got \(parser.errors)")
            return
        }
        XCTAssert("\(parser.ast.errors[0])".hasPrefix("Missing terminating quote"),"Incorrect error \(parser.ast.errors[0])")
        XCTAssert("\(parser.ast.errors[1])".hasPrefix("Expected at least one rule"),"Incorrect error \(parser.ast.errors[0])")
        XCTAssert("\(parser.ast.errors[2])".hasPrefix("hello is never defined"),"Incorrect error \(parser.ast.errors[0])")
    }
    
    
    func testAnnotationsOnIdentifiers(){
        source.add(line: "x = \"x\"")
        source.add(line: "xyz = @error(\"Expected X\")\nx \"y\" \"z\"")
        
        let parser = STLRParser(source: source)
        
        guard let compiledLanguage = parser.ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        let result : DefaultHomogenousAST<HomogenousNode> = compiledLanguage.build(source: "yz")
        
        guard let error = result.errors.first else {
            XCTFail("Expected an error \(parser.ast.rules[1])")
            return
        }
        
        
        XCTAssert("\(error)".hasPrefix("Expected X"),"Incorrect error \(error)")
    }
    
    func testAnnotationsOnGroups(){
        source.add(line: "x = \"x\"")
        source.add(line: "xyz = @error(\"Expected xy\")(@error(\"Expected x\")x \"y\") \"z\"")
        
        let parser = STLRParser(source: source)
        
        guard let compiledLanguage = parser.ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        let result : DefaultHomogenousAST<HomogenousNode> = compiledLanguage.build(source: "xz")
        
        guard let error = result.errors.first else {
            XCTFail("Expected an error \(parser.ast.rules[rangeChecked: 1]?.description ?? "but the rule is missing")")
            return
        }
        
        
        XCTAssert("\(error)".hasPrefix("Expected xy"),"Incorrect error \(error)")
    }
}
