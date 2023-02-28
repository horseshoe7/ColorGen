import Foundation

class AppleCodeBuilder: CodeBuilding {
    
    let outputPath: String
    let moduleName: String
    let publicACL: Bool
    
    private let className: String
    private let frameworkName: String
    
    init(outputPath: String, moduleName: String, publicAccess: Bool) {
        self.moduleName = moduleName
        self.outputPath = outputPath
        self.publicACL = publicAccess
        
        self.frameworkName = "UIKit"
        self.className = "UIColor"
    }
    
    func build(_ colorList: [ColorGenColor], with name: String) throws {
        
        try buildAssetsCatalog(colorList, name)
        try buildAccompanyingCode(colorList, name)
    }
    
    private func buildAssetsCatalog(_ colorList: [ColorGenColor], _ name: String) throws {
        
        let outputFilename = "\(name)\(kAssetsCatalogFileExtension)"
        let outputCatalogPath = ((self.outputPath as NSString).expandingTildeInPath as NSString).appendingPathComponent(outputFilename)
        
        let fm = FileManager.default
        if fm.fileExists(atPath: outputCatalogPath) {
            try fm.removeItem(atPath: outputCatalogPath)
        }
        
        try fm.createDirectory(atPath: outputCatalogPath, withIntermediateDirectories: true, attributes: nil)
        
        let contentsJsonPath = (outputCatalogPath as NSString).appendingPathComponent(kAssetsContentsFilename)
        if fm.fileExists(atPath: contentsJsonPath) {
            try fm.removeItem(atPath: contentsJsonPath)
        }
        
        /// have to write the basics here
        try kAssetsContentsJson.write(toFile: contentsJsonPath, atomically: true, encoding: .utf8)
     
        for color in colorList {
            
            // a method that substitutes the hexColor into the contents
            func makeSubstitutions(_ hexColor: String, into contents: inout String, isDarkMode: Bool) {
                
                let colorString = hexColor.replacingOccurrences(of: "#", with: "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                let redComponent = (colorString as NSString).substring(with: NSMakeRange(0, 2))
                let greenComponent = (colorString as NSString).substring(with: NSMakeRange(2, 2))
                let blueComponent = (colorString as NSString).substring(with: NSMakeRange(4, 2))
                var alphaComponent = "1.0"
                
                if colorString.count == 8 {
                    alphaComponent = (colorString as NSString).substring(with: NSMakeRange(6, 2))
                    alphaComponent = String(format: "%f", alphaComponent.hexAsNormalizedFloatValue())
                }
                
                contents = contents
                    .replacingOccurrences(of: isDarkMode ? redKeyDark : redKey, with: redComponent)
                    .replacingOccurrences(of: isDarkMode ? greenKeyDark : greenKey, with: greenComponent)
                    .replacingOccurrences(of: isDarkMode ? blueKeyDark : blueKey, with: blueComponent)
                    .replacingOccurrences(of: isDarkMode ? alphaKeyDark : alphaKey, with: alphaComponent)
            }
            
            let needsDarkMode = color.alternateValue != nil
            // choose correct template
            let template = needsDarkMode ? kColorContentsJsonTemplateWithDarkMode : kColorContentsJsonTemplate
            
            // initial value
            var fileContents = template
            
            // substitute main color
            makeSubstitutions(color.value, into: &fileContents, isDarkMode: false)
            
            // sub alternate color, if present
            if let altColorString = color.alternateValue {
                makeSubstitutions(altColorString, into: &fileContents, isDarkMode: true)
            }
            
            // now write the contents of each color to its own location.
            
            let folderName = color.name.appending(kAssetsColorSetFileExtension)
            let folderPath = (outputCatalogPath as NSString).appendingPathComponent(folderName)
        
            if fm.fileExists(atPath: folderPath) {
                try fm.removeItem(atPath: folderPath)
                try fm.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            } else {
                try fm.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            // write the contents of that color
            let colorContentsPath = (folderPath as NSString).appendingPathComponent(kAssetsContentsFilename)
            try fileContents.write(toFile: colorContentsPath, atomically: true, encoding: .utf8)
        }
    }
    
    
    private func buildAccompanyingCode(_ colorList: [ColorGenColor], _ name: String) throws {
        
        let outputFilename = "\(name).swift"
        let outputFilePath = ((self.outputPath as NSString).expandingTildeInPath as NSString).appendingPathComponent(outputFilename)
        
        // check for existence, remove if so, then create folder
        let fm = FileManager.default
        if fm.fileExists(atPath: outputFilePath) {
            try fm.removeItem(atPath: outputFilePath)
        }
        
        let colorStringConstants = buildNamedColorConstants(with: colorList)
        let colorValueConstants = buildNamedColorsList(with: colorList, moduleName: self.moduleName)
        
        let swiftFileContent = kNamedColorsEnumSwiftTemplate
            .replacingOccurrences(of: kTemplateKeyFrameworkName, with: self.frameworkName)
            .replacingOccurrences(of: kTemplateKeyEnumName, with: name)
            .replacingOccurrences(of: kTemplateKeyStaticColornames, with: colorStringConstants)
            .replacingOccurrences(of: kTemplateKeyStaticConstants, with: colorValueConstants)
            .replacingOccurrences(of: kTemplateKeyACL, with: self.publicACL ? "public " : "")
        
        try swiftFileContent.write(toFile: outputFilePath, atomically: true, encoding: .utf8)
    }
    
    private func buildNamedColorConstants(with colorList: [ColorGenColor]) -> String {
        
        let signatureKey = "<*constant_name*>"
        let valueKey     = "<*constant_string*>"
        
        let colorStringTemplate = "\t\t<*acl*>static let <*constant_name*>: String = \"<*constant_string*>\""
        
        return colorList.map { color -> String in
         
            let constantValue = color.name
            let constantName = color.name.lowercasingFirstLetter()
            
            return colorStringTemplate
                .replacingOccurrences(of: signatureKey, with: constantName)
                .replacingOccurrences(of: valueKey, with: constantValue)
            
        }.reduce(into: "") { partialResult, next in
            partialResult.append("\(next)\n")
        }
    }
    
    private func buildNamedColorsList(with colorList: [ColorGenColor], moduleName: String) -> String {
        
        let classNameKey = "<*class_name*>"
        let signatureKey = "<*color_name*>"
        let valueKey     = "<*constant_string*>"
        let commentsKey  = "<*color_comments*>"
        let moduleNameKey   = "<*module_name*>"
        
        let colorStringTemplate =
"""
    <*color_comments*>
    <*acl*>static let <*color_name*>: <*class_name*> = <*class_name*>(named: "<*constant_string*>", in: .<*module_name*>, compatibleWith: UITraitCollection(displayGamut: .SRGB))!)!

"""

        var firstColor = true // defined hex colors
        var definedColorsFinished = false
        var firstReferenceColor = false // aliases
        
        return colorList.map { color -> String in
            
            var comments: String?
            if firstColor {
                comments = "    //-------- Defined Colors with Provided Hex Values\n\n"
                firstColor = false
            }
            
            // this works because the assumption is that colorList has been sorted first by non-aliases then aliases.
            if(color.isAlias && !definedColorsFinished) {
                definedColorsFinished = true
                firstReferenceColor = true
            }
            
            if firstReferenceColor {
                comments = "\n\n    //--------- Color Aliases who are references to defined colors above:\n\n"
                firstReferenceColor = false
            }
            
            let constantValue = color.name
            let constantName = color.name.lowercasingFirstLetter()
            
            let commentsValue: String
            if color.comments?.count ?? 0 > 0 {
                commentsValue = "/// \(color.value) - \(color.comments!)"
            } else {
                commentsValue = "/// \(color.value)"
            }
            
            let outputLine = colorStringTemplate
                .replacingOccurrences(of: classNameKey, with: self.className)
                .replacingOccurrences(of: signatureKey, with: constantName)
                .replacingOccurrences(of: valueKey, with: constantValue)
                .replacingOccurrences(of: commentsKey, with: commentsValue)
                .replacingOccurrences(of: moduleNameKey, with: moduleName)
            
            if let comments = comments {
                return comments.appending(outputLine)
            } else {
                return outputLine
            }
        }
        .reduce(into: "") { partialResult, next in
            partialResult.append("\(next)\n")
        }
    }
}

// MARK: - Template Related - Swift Code


fileprivate let kTemplateKeyFileName                      = "<*file_name*>"
fileprivate let kTemplateKeyStaticConstants               = "<*static_constants*>"
fileprivate let kTemplateKeyEnumName                      = "<*root_name*>"
fileprivate let kTemplateKeyStaticColornames              = "<*static_colornames*>"
fileprivate let kTemplateKeyFrameworkName                 = "<*import_framework_name*>"
fileprivate let kTemplateKeyACL                           = "<*acl*>"

fileprivate let kNamedColorsEnumSwiftTemplate = """
//
//  <*root_name*>.swift
//  This file was autogenerated by ColorPaletteGenerator.
//  Do not modify as it can easily be overwritten.

import <*import_framework_name*>

<*acl*>enum <*root_name*> {

<*static_constants*>

    //--------- Constants used for named colors (you will likely never need them but here for completeness)
    <*acl*>enum Name {

<*static_colornames*>
    }
}
"""

// MARK: - Template Related - Assets Catalog

fileprivate let kAssetsCatalogFileExtension = ".xcassets"
fileprivate let kAssetsColorSetFileExtension = ".colorset"
fileprivate let kAssetsContentsFilename = "Contents.json"

fileprivate let redKey       = "<*red*>"  // expects 2 characters
fileprivate let greenKey     = "<*green*>"
fileprivate let blueKey      = "<*blue*>"
fileprivate let alphaKey     = "<*alpha*>" // expects a decimal as string

fileprivate let redKeyDark   = "<*red_dark*>"  // expects 2 characters
fileprivate let greenKeyDark = "<*green_dark*>"
fileprivate let blueKeyDark  = "<*blue_dark*>"
fileprivate let alphaKeyDark = "<*alpha_dark*>" // expects a decimal as string


fileprivate let kAssetsContentsJson = """
{
    "info" : {
        "version" : 1,
        "author" : "xcode"
    }
}
"""


fileprivate let kColorContentsJsonTemplate = """
{
    "info" : {
        "version" : 1,
        "author" : "xcode"
    },
    "colors" : [
        {
            "idiom" : "universal",
            "color" : {
                "color-space" : "srgb",
                "components" : {
                    "red" : "0x<*red*>",
                    "alpha" : "<*alpha*>",
                    "blue" : "0x<*blue*>",
                    "green" : "0x<*green*>"
                }
            }
        }
    ]
}
"""

fileprivate let kColorContentsJsonTemplateWithDarkMode = """
{
    "info" : {
        "version" : 1,
        "author" : "xcode"
    },
    "colors" : [
        {
            "idiom" : "universal",
            "color" : {
                "color-space" : "srgb",
                "components" : {
                    "red" : "0x<*red*>",
                    "alpha" : "<*alpha*>",
                    "blue" : "0x<*blue*>",
                    "green" : "0x<*green*>"
                }
            }
        },
        {
            "appearances" : [
                {
                    "appearance" : "luminosity",
                    "value" : "dark"
                }
            ],
            "idiom" : "universal",
            "color" : {
                "color-space" : "srgb",
                "components" : {
                    "red" : "0x<*red_dark*>",
                    "alpha" : "<*alpha_dark*>",
                    "blue" : "0x<*blue_dark*>",
                    "green" : "0x<*green_dark*>"
                }
            }
        }
    ]
}
"""


// MARK: - Helpers

fileprivate extension String {
    func hexAsNormalizedFloatValue() -> Float {
        
        guard self.count == 2 else { return 1.0 }
        
        let hexValue = "0x\(self)"
        let scanner = Scanner(string: hexValue)
        var result: Float = 1.0
        scanner.scanHexFloat(&result)
        return Float(result)/Float(255)
    }
}
