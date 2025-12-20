import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

public class StringsBuilder: XMLBuilder {
    public func replace(name: String?, value: String?) -> Self {
        guard let name = name else {
            return self
        }
        let strings = xml.rootElement()?.elements(forName: "string") ?? []
        let string = strings.first {
            $0.attribute(forName: "name")?.stringValue == name
        }
        guard let string = string else {
            return self
        }
        string.stringValue = value
        return self
    }
}
