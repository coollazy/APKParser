import Foundation

public class XMLBuilder {
    public let xml: XMLDocument

    public init(_ url: URL) throws {
        let content = try String(contentsOf: url)
        guard let data = content.data(using: .utf8) else {
            throw XMLBuilderError.convertError
        }
        self.xml = try XMLDocument(data: data)
    }

    public func build(to url: URL) throws {
        let content = xml.xmlString(options: .nodePrettyPrint)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

public enum XMLBuilderError: Error {
    case convertError
}
