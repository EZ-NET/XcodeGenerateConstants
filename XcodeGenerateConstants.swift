#!/usr/bin/swift


import Foundation

func main() throws {
    
    let _arguments = ProcessInfo.processInfo.arguments
    let startIndex = _arguments.index(of: "--")!.advanced(by: 1)
    let arguments = Array(_arguments.suffix(from: startIndex))

    guard arguments.count == 2 else {
        
        throw GenerateError.invalidArguments(reason: arguments.joined(separator: " "))
    }

    let target = arguments[0]
    let sourcePath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/XcodeGenerateConstants")
    let targetPath = URL(fileURLWithPath: arguments[1])
    
    try Generator(target, sourcePath: sourcePath, targetPath: targetPath).generate()
}

enum GenerateError : Error {

    case invalidArguments(reason: String)
    case readError(path: URL)
    case invalidContents(path: URL)
}

extension GenerateError : CustomStringConvertible {

	var description:String {
		
		switch self {
			
		case .invalidArguments(let reason):
			return "Invalid Arguments. \(reason)"
				
		case .readError(let path):
			return "Failed to read path '\(path)'."
			
		case .invalidContents(let path):
			return "Invalid contents in path '\(path)'."
		}
	}
}

enum GenerateType {
    
    case Swift
}

struct Definition : TextOutputStreamable {
    
    var key:String
    var value:String
    
    init(_ key:String, value:String) {
        
        self.key = key
        self.value = value
    }
    
    func toCode() -> String {
    
        func quote(_ value:String) -> String {
            
            return "\"" + value.replacingOccurrences(of: "\"", with: "\\") + "\""
        }
        
        func getDefinition(key:String, value:String) -> String {
            
            return "var \(key):String { return \(quote(value)) }"
        }
    
        return getDefinition(key: key, value: value)
    }
    
    func write<Target : TextOutputStream>(to target: inout Target) {
        
        target.write(toCode())
    }
}

final class Stream : TextOutputStream {
    
    private var name:String
    private var path:URL
    private var options:[String]?
    private var buffer:Array<String>

    init(name:String, path:URL) {
        
        self.name = name
        self.path = path
        
        self.buffer = Array<String>()
    }
    
    convenience init(name:String, path:URL, options: String...) {

        self.init(name: name, path: path)
        self.options = options
    }
    
    
    func write(_ string: String) {
        
        buffer.append(string)
    }
    
    func flush() throws {
     
        try generateConstants(type: .Swift).write(to: path, atomically: true, encoding: .utf8)
    }
    
    private func generateConstants(type: GenerateType) -> String {
    
        switch type {
            
        case .Swift:
            return generateSwiftConstants()
        }
    }
    
    private func generateSwiftConstants() -> String {
        
        func headCode() -> [String] {
            
            var definition = "struct \(name) {"
            
            func getDefinitionSuffix() -> String? {
                
                guard let conforms = options else {
                    
                    return nil
                }
                
                return " : ".appending(conforms.joined(separator: ", "))
            }
            
            return [
                
                definition.appending(getDefinitionSuffix() ?? ""),
                ""
            ]
        }
        
        func footCode() -> [String] {
            
            return [ "}" ]
        }
        
        func bodyCode() -> [String] {
            
            return buffer.map { "\t\($0)" }
        }
        
        let code = headCode() + bodyCode() + footCode()
        
        return code.joined(separator: "\n")
    }
}

final class Generator {
    
    private(set) var target:String
    private(set) var sourcePath:URL
    private(set) var targetPath:URL
    
    init(_ target:String, sourcePath:URL, targetPath:URL) {
        
        self.target = target
        self.sourcePath = sourcePath
        self.targetPath = targetPath
    }
    
    func generate() throws {
        
        let stream = Stream(name: target, path: targetPath.appendingPathComponent("\(target).swift"))
        let plist = sourcePath.appendingPathComponent("\(target).plist")
        
        guard let data = NSDictionary(contentsOf: plist) else {
            
            throw GenerateError.readError(path: plist)
        }
        
        guard let contents = data as? Dictionary<String, String> else {
            
            throw GenerateError.invalidContents(path: plist)
        }
        
        contents.map(Definition.init).map(Definition.toCode).forEach {
            
            stream.write($0())
        }
        
        try stream.flush()
    }
}

do {
	try main()
}
catch {

	print("ERROR: \(error)")
	exit(1)
}
