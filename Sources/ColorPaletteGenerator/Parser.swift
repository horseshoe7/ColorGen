//
//  File.swift
//  
//
//  Created by Stephen OConnor on 01.12.21.
//

import Foundation

struct ColorGenColor {
    /// The name of the color
    let name: String
    /// e.g. #AAFF22  or #AAFF2211, includes the # and is in RRGGBB or RRGGBBAA form
    let value: String
    /// optional.  For example a dark-mode representation.
    var alternateValue: String?
    /// used internally
    let isAlias: Bool
    /// if there are any custom comments about the color
    let comments: String?
}

extension ColorGenColor: Equatable {
    static func ==(lhs: ColorGenColor, rhs: ColorGenColor) -> Bool {
        return lhs.name == rhs.name
    }
}


class ColorParser {
    
    enum ParsingError: Error {
        case noHexValueFound(details: String)
        case noColorNameFound(details: String)
        case invalidFormat(details: String)
    }
    
    
    let inputPath: String
    let exportAliasesOnly: Bool
    let publicAccess: Bool
    let printDetails: Bool
    init(inputPath: String, aliasesOnly: Bool, publicAccess: Bool, printDetails: Bool) {
        self.inputPath = inputPath
        self.exportAliasesOnly = aliasesOnly
        self.printDetails = printDetails
        self.publicAccess = publicAccess
    }
    
    func parse() throws -> [ColorGenColor] {
        
        let fileContents = try String(contentsOfFile: self.inputPath)
        
        let lines = fileContents.components(separatedBy: .newlines)
        
        let definedColors: [ColorGenColor] = lines.compactMap { [unowned self] line in
            do {
                return try self.parseColor(from: line)
                
            } catch let e as ParsingError {
                switch e {
                case .noHexValueFound(let details):
                    print(details)
                case .noColorNameFound(let details):
                    print(details)
                case .invalidFormat(let details):
                    print(details)
                }
                
                return nil
            } catch {
                print("Impossible outcome.")
                return nil
            }
            
        }.sorted(by: { $0.name < $1.name })
        
        let aliasColors: [ColorGenColor] = lines.compactMap { [unowned self] line in
            do {
                return try self.parseColor(from: line, definedColors: definedColors)
                
            } catch let e as ParsingError {
                switch e {
                case .noHexValueFound(let details):
                    print(details)
                case .noColorNameFound(let details):
                    print(details)
                case .invalidFormat(let details):
                    print(details)
                }
                
                return nil
            } catch {
                print("Impossible outcome.")
                return nil
            }
        }.sorted(by: { $0.name < $1.name })
        
        
        if self.exportAliasesOnly {
            return aliasColors
        } else {
            var output = definedColors
            for color in aliasColors {
                if !output.contains(color) {
                    output.append(color)
                }
            }
            return output
        }
    }
    
    /// The method that parses color information from a line in the .palette file.  If you are populating the alias colors, you provide the list of known defined colors for matching purposes.
    func parseColor(from line: String, definedColors: [ColorGenColor]? = nil) throws -> ColorGenColor? {
        
        guard line.count > 0 else { return nil } // empty line
        if line.hasPrefix("//") { return nil }  // skip comments
        
        // parse hex color definitions
        if line.hasPrefix("#"), definedColors == nil {
            
            // you can test this on regextester.com
            // will capture 3 digit, 6 digit, or 8 (RRGGBBAA) hex strings
            let captureValidHexString = "#([a-fA-F0-9]{3}){1,2}([a-fA-F0-9]{2})?"
            
            guard let regex = try? NSRegularExpression(pattern: captureValidHexString, options: [.caseInsensitive]) else {
                fatalError("FATAL ERROR:  You are using a Regex pattern that won't work!")
            }
            
            var colorValue: String?
            var alternateValue: String?
            var lastRange = NSMakeRange(NSNotFound, 0)
            
            regex.enumerateMatches(
                in: line,
                options: [],
                range: NSMakeRange(0, line.count)
            ) {
                (result, flags, stop) in
                
                // check that it found something
                guard let result = result else { return }
                
                if !flags.contains(.completed) {
                 
                    if colorValue == nil {
                        colorValue = (line as NSString).substring(with: result.range)
                        lastRange = result.range
                    } else {
                        alternateValue = (line as NSString).substring(with: result.range)
                        lastRange = result.range
                    }
                }
            }
            
            guard let parsedValue = colorValue else {
                throw ParsingError.noHexValueFound(details: "ERROR:  Could not parse a color from line in input file: \(line)")
            }
            
            let offset = lastRange.location + lastRange.length
            let textContentRange = NSMakeRange(offset, line.count - offset)
            let metadata = (line as NSString).substring(with: textContentRange).trimmingCharacters(in: .whitespaces)
            
            guard let colorName = metadata.components(separatedBy: .whitespaces).first else {
                throw ParsingError.noColorNameFound(details: "ERROR: Name could not be parsed from input line: \(line)")
            }
            
            
            var comments: String = (metadata as NSString).substring(from: colorName.count)
            if comments.count > 0 {
                comments = (comments as NSString).substring(from: 1)  // first character is likely a space.
            }
            
            if self.printDetails {
                print("Parsed Color with Name: \(colorName)")
            }
            
            return ColorGenColor(
                name: colorName,
                value: parsedValue,
                alternateValue: alternateValue,
                isAlias: false,
                comments: comments.count > 0 ? comments : nil
            )
        }
        
        if line.hasPrefix("$"), let definedColors = definedColors {
            
            let stripped = line.replacingOccurrences(of: "$", with: "")
            
            let elements = stripped.components(separatedBy: .whitespaces).filter({ $0.count > 0 })
            
            guard elements.count >= 2 else {
                throw ParsingError.invalidFormat(details: "There is something wrong with your formatting of color: \(line).  It should be $<ColorReferenceName> <NewName>")
            }
            
            let referenceColorName = elements[0]
            let aliasName = elements[1]
            
            var comments: String?
            if elements.count > 2 {
                comments = elements[2...].joined(separator: " ")
            }
            
            // now match it
            for definedColor in definedColors {
                if definedColor.name == referenceColorName {
                    
                    if self.printDetails {
                        print("Parsed Alias Color with Name: \(aliasName)")
                    }
                    
                    return ColorGenColor(
                        name: aliasName,
                        value: definedColor.value,
                        alternateValue: definedColor.alternateValue,
                        isAlias: true,
                        comments: comments
                    )
                }
            }
            
            if self.printDetails {
                print("Could not find reference color with name \(referenceColorName) to create alias \(aliasName)")
            }
        }
        
        return nil
    }
    
}

