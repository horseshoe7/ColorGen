import XCTest
import class Foundation.Bundle
@testable import ColorPaletteGenerator

enum FileError: Error {
    case couldNotLoad
}

final class ColorPaletteGeneratorTests: XCTestCase {

    var parser: ColorParser!
    
    override func setUpWithError() throws {
        
        try self.initializeParser()
    }
    
    private func initializeParser(aliasesOnly: Bool = false) throws {
        
        let bundle = Bundle.module
        guard let inputFile = bundle.path(forResource: "Test", ofType: "palette") else {
            throw FileError.couldNotLoad
        }
        
        self.parser = ColorParser(inputPath: inputFile, aliasesOnly: aliasesOnly)
    }
    
    func testCommentLine() throws {
        let sut = "// This is to indicate to the dev what he should know."
        let expectedResult: ColorGenColor? = nil
        let result = try self.parser.parseColor(from: sut, definedColors: nil)
        XCTAssertEqual(expectedResult, result)
    }
    
    func testBasicLine() throws {
        
        let sut = "#A0B1C2 BlueGrey This is some comment now."
        let expectedResult = ColorGenColor(
            name: "BlueGrey",
            value: "#A0B1C2",
            alternateValue: nil,
            isAlias: false,
            comments: "This is some comment now."
        )
        
        let result = try self.parser.parseColor(from: sut, definedColors: nil)
        XCTAssertEqual(expectedResult, result)
    }
    
    func testBasicAliasLine() throws {
        
        let sut = "$BlueGrey StandardBackgroundColor This is some other comment now."
        
        let existingColor = ColorGenColor(
            name: "BlueGrey",
            value: "#A0B1C2",
            alternateValue: nil,
            isAlias: false,
            comments: "This is some comment now."
        )
        
        let expectedResult = ColorGenColor(
            name: "StandardBackgroundColor",
            value: "#A0B1C2",
            alternateValue: nil,
            isAlias: true,
            comments: "This is some other comment now."
        )
        
        let result = try self.parser.parseColor(from: sut, definedColors: [existingColor])
        XCTAssertEqual(expectedResult, result)
    }
    
    func testDarkModeLine() throws {

        let sut = "#A0B1C2 #D1E2F3 BlueGrey This is some comment now with dark mode."
        
        let expectedResult = ColorGenColor(
            name: "BlueGrey",
            value: "#A0B1C2",
            alternateValue: "#D1E2F3",
            isAlias: false,
            comments: "This is some comment now with dark mode."
        )
        
        let result = try self.parser.parseColor(from: sut, definedColors: nil)
        XCTAssertEqual(expectedResult, result)
    }
    
    func testAliasToDarkModeColor() throws {
        
        let existingColor = ColorGenColor(
            name: "BlueGrey",
            value: "#A0B1C2",
            alternateValue: "#D1E2F3",
            isAlias: false,
            comments: "This is some comment now with dark mode."
        )
        
        let sut = "$BlueGrey StandardBackgroundColor This is some comment now for alias with dark mode."
        
        let expectedResult = ColorGenColor(
            name: "StandardBackgroundColor",
            value: "#A0B1C2",
            alternateValue: "#D1E2F3",
            isAlias: true,
            comments: "This is some comment now for alias with dark mode."
        )
        
        let result = try self.parser.parseColor(from: sut, definedColors: [existingColor])
        XCTAssertEqual(expectedResult, result)
    }
    
    func testParsesAllColors() throws {
        try initializeParser(aliasesOnly: false)
        let parsedColors = try self.parser.parse()
        XCTAssertEqual(parsedColors.count, 5, "There were a total of 5 colors defined in the input file, so they should have been parsed")
    }
    
    func testParsesAliasesOnly() throws {
        try initializeParser(aliasesOnly: true)
        let parsedColors = try self.parser.parse()
        XCTAssertEqual(parsedColors.count, 2, "There were a total of 2 color aliases defined in the input file, so they should have been parsed")
    }
}


/*
 Xcode Boilerplate:
 
 func testExample() throws {
     // This is an example of a functional test case.
     // Use XCTAssert and related functions to verify your tests produce the correct
     // results.

     // Some of the APIs that we use below are available in macOS 10.13 and above.
     guard #available(macOS 10.13, *) else {
         return
     }

     // Mac Catalyst won't have `Process`, but it is supported for executables.
     #if !targetEnvironment(macCatalyst)

     let fooBinary = productsDirectory.appendingPathComponent("ColorPaletteGenerator")

     let process = Process()
     process.executableURL = fooBinary

     let pipe = Pipe()
     process.standardOutput = pipe

     try process.run()
     process.waitUntilExit()

     let data = pipe.fileHandleForReading.readDataToEndOfFile()
     let output = String(data: data, encoding: .utf8)

     XCTAssertEqual(output, "Hello, world!\n")
     #endif
 }

 /// Returns path to the built products directory.
 var productsDirectory: URL {
   #if os(macOS)
     for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
         return bundle.bundleURL.deletingLastPathComponent()
     }
     fatalError("couldn't find the products directory")
   #else
     return Bundle.main.bundleURL
   #endif
 }
 
 
 */
