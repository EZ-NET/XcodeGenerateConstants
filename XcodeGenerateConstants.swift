#!/usr/bin/swift


import Foundation

func main() throws {
    
    let _arguments = NSProcessInfo.processInfo().arguments
    let startIndex = _arguments.indexOf("--")!.successor()
    let arguments = Array(_arguments.suffixFrom(startIndex))

    guard arguments.count == 2 else {
        
        throw GenerateError.InvalidArguments(reason: arguments.joinWithSeparator(" "))
    }

    let target = arguments[0]
    let sourcePath = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Library/XcodeGenerateConstants")
    let targetPath = NSURL(fileURLWithPath: arguments[1])
    
    try Generator(target, sourcePath: sourcePath, targetPath: targetPath).generate()
}

enum GenerateError : ErrorType {

    case InvalidArguments(reason: String)
    case ReadError(path: NSURL)
    case InvalidContents(path: NSURL)
}

extension GenerateError : CustomStringConvertible {

	var description:String {
		
		switch self {
			
		case .InvalidArguments(let reason):
			return "Invalid Arguments. \(reason)"
				
		case .ReadError(let path):
			return "Failed to read path '\(path)'."
			
		case .InvalidContents(let path):
			return "Invalid contents in path '\(path)'."
		}
	}
}

enum GenerateType {
    
    case Swift
}

struct Definition : Streamable {
    
    var key:String
    var value:String
    
    init(_ key:String, value:String) {
        
        self.key = key
        self.value = value
    }
    
    func toCode() -> String {
    
        func quote(value:String) -> String {
            
            return "\"" + value.stringByReplacingOccurrencesOfString("\"", withString: "\\") + "\""
        }
        
        func getDefinition(key:String, value:String) -> String {
            
            return "var \(key):String { return \(quote(value)) }"
        }
    
        return getDefinition(self.key, value: self.value)
    }
    
    func writeTo<Target : OutputStreamType>(inout target: Target) {
        
        target.write(self.toCode())
    }
}

final class Stream : OutputStreamType {
    
    private var name:String
    private var path:NSURL
    private var options:[String]?
    private var buffer:Array<String>

    init(name:String, path:NSURL) {
        
        self.name = name
        self.path = path
        
        self.buffer = Array<String>()
    }
    
    convenience init(name:String, path:NSURL, options: String...) {

        self.init(name: name, path: path)
        self.options = options
    }
    
    
    func write(string: String) {
        
        buffer.append(string)
    }
    
    func flush() throws {
     
        try generateConstantsWithType(.Swift).writeToURL(self.path, atomically: true, encoding: NSUTF8StringEncoding)
    }
    
    private func generateConstantsWithType(type: GenerateType) -> String {
    
        switch type {
            
        case .Swift:
            return self.generateSwiftConstants()
        }
    }
    
    private func generateSwiftConstants() -> String {
        
        func headCode() -> [String] {
            
            var definition = "struct \(self.name) {"
            
            func getDefinitionSuffix() -> String? {
                
                guard let conforms = self.options else {
                    
                    return nil
                }
                
                return " : ".stringByAppendingString(conforms.joinWithSeparator(", "))
            }
            
            return [
                
                definition.stringByAppendingString(getDefinitionSuffix() ?? ""),
                ""
            ]
        }
        
        func footCode() -> [String] {
            
            return [ "}" ]
        }
        
        func bodyCode() -> [String] {
            
            return self.buffer.map { "\t\($0)" }
        }
        
        let code = headCode() + bodyCode() + footCode()
        
        return code.joinWithSeparator("\n")
    }
}

final class Generator {
    
    private(set) var target:String
    private(set) var sourcePath:NSURL
    private(set) var targetPath:NSURL
    
    init(_ target:String, sourcePath:NSURL, targetPath:NSURL) {
        
        self.target = target
        self.sourcePath = sourcePath
        self.targetPath = targetPath
    }
    
    func generate() throws {
        
        let stream = Stream(name: self.target, path: self.targetPath.URLByAppendingPathComponent("\(self.target).swift"))
        let plist = self.sourcePath.URLByAppendingPathComponent("\(self.target).plist")
        
        guard let data = NSDictionary(contentsOfURL: plist) else {
            
            throw GenerateError.ReadError(path: plist)
        }
        
        guard let contents = data as? Dictionary<String, String> else {
            
            throw GenerateError.InvalidContents(path: plist)
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
