import ArgumentParser
import Foundation


struct ColorGen: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "colorgen",
        abstract: "A tool that converts a human-readable .palette file into assets ready for use in your Xcode project",
        discussion: "Please see README.md for more information.",
        version: "0.0.1",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil
    )
    
    @Argument(help: "The namespace of your colors.  e.g. MyColors, AppColors, etc.")
    var name: String
    
    @Option(name: .shortAndLong, help: "The path to the input file.")
    var input: String?
    
    @Option(name: .shortAndLong, help: "The path to the output folder.")
    var output: String?
        
    @Flag(help: "Whether the generated colors will have public access control")
    var publicAccess = false
    
    @Flag(help: "Whether to generate for MacOS, i.e. export NSColor types and not UIColor types")
    var macos = false

    @Flag(help: "Whether to generate for Android, i.e. .xml format that Android requires")
    var android = false
    
    @Flag(help: "Whether to only generate the aliases, i.e. you might not want to include the principal definitions, if they have abstract names that should not be used by your codebase.")
    var aliasesOnly = false
    
    @Flag(help: "Otherwise known as a 'verbose' flag, it will print more information as it parses.")
    var showDetails = false
    
    mutating func run() throws {
        
        var input: String = ""
        var output: String = ""
        
        try validateArguments(input: &input, output: &output)
        
        try generateColors(namespace: name, input: input, output: output)
        
        print("Generated Colors Successfully")
        throw ExitCode.success
    }
    
    private func validateArguments(input: inout String, output: inout String) throws {
        
        guard let inputArg = self.input else {
            throw ValidationError("You need to provide an input argument or else this tool won't work!")
        }
        
        guard let outputArg = self.output else {
            throw ValidationError("You need to provide an output argument or else this tool won't work!")
        }

        let fm = FileManager.default
        
        // now determine if there is a file at that path
        
        guard fm.fileExists(atPath: inputArg) else {
            throw ValidationError("No file was found at \(inputArg)!")
        }
        
        // now determine if there is a folder at that path
        let url = URL(fileURLWithPath: outputArg, isDirectory: true)
        var isDir : ObjCBool = false
        if !fm.fileExists(atPath: url.path, isDirectory: &isDir) {
            
        }
        
        if fm.fileExists(atPath: url.path, isDirectory:&isDir) {
            if isDir.boolValue {
                // file exists and is a directory
                // ALL GOOD.
            } else {
                // file exists and is not a directory
                // invalid output path
                throw ValidationError("The provided output path is not a directory but needs to be!")
            }
        } else {
            // file does not exist
            try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
        input = inputArg
        output = outputArg
    }
    
    // When this method is invoked, the namespace is defined, there is a file at input, and output folder will exist.
    private func generateColors(namespace: String, input: String, output: String) throws {
        
        let parser = ColorParser(inputPath: input, aliasesOnly: self.aliasesOnly, publicAccess: self.publicAccess, printDetails: self.showDetails)
        
        do {
            let colorList = try parser.parse()
         
            let colorListName = namespace.capitalizingFirstLetter()  // the name of the struct that will be generated
            
            let builder: CodeBuilding
            if self.android {
                builder = AndroidCodeBuilder(outputPath: output)
            } else {
                builder = AppleCodeBuilder(outputPath: output, forMacOS: self.macos)
            }
            
            try builder.build(colorList, with: colorListName)
            
            
        } catch {
            print("GENERATING COLORS FAILED.")
            throw ExitCode.failure
        }
    }
}


