import Foundation
import Yams

public class YAMLBuilder {
    public var yaml: APKToolYmlModel

    public init(_ url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = YAMLDecoder()
        self.yaml = try decoder.decode(APKToolYmlModel.self, from: data)
    }

    public func build(to url: URL) throws {
        let encoder = YAMLEncoder()
        do {
            let data = try encoder.encode(yaml).data(using: .utf8)
            try data?.write(to: url)
        } catch {
            throw YAMLBuilderError.encodeFailed
        }
    }
}

public enum YAMLBuilderError: Error {
    case encodeFailed
}
