//
//  ColorGenTests.swift
//  
//
//  Created by Stephen OConnor on 08.06.23.
//

import XCTest
import class Foundation.Bundle
@testable import ColorPaletteGenerator

final class ColorGenTests: XCTestCase {

    var parser: ColorParser!
    
    override func setUpWithError() throws {
        try self.initializeParser()
    }
    
    private func initializeParser(aliasesOnly: Bool = false) throws {
        
        let bundle = Bundle.module
        guard let inputFile = bundle.path(forResource: "Test", ofType: "palette") else {
            throw FileError.couldNotLoad
        }
        
        self.parser = ColorParser(inputPath: inputFile, aliasesOnly: aliasesOnly, publicAccess: false, printDetails: true)
    }

    func testFunctionality() throws {
        
        do {
            let colorList = try parser.parse()
         
            let colorListName = "TestColors"
            
            let directory = FileManager.default.temporaryDirectory
            print(directory)
            
            let builder: CodeBuilding = AppleCodeBuilder(outputPath: directory.path, bundleName: "main", publicAccess: true, generateSwiftUIColors: true)
            
            try builder.build(colorList, with: colorListName)
            
            
        } catch {
            print("GENERATING COLORS FAILED.")
            throw error
        }
    }


}
