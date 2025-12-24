import Foundation
import Yams

public class YAMLBuilder {
    public var node: Node

    public init(_ url: URL) throws {
        let content = try String(contentsOf: url)
        guard let node = try Yams.compose(yaml: content) else {
            throw YAMLBuilderError.parseFailed
        }
        self.node = node
    }
    
    public init(node: Node) {
        self.node = node
    }

    public func build(to url: URL) throws {
        let content = try Yams.serialize(node: node)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

public enum YAMLBuilderError: Error {
    case parseFailed
    case encodeFailed
}

// MARK: - Property Accessors
extension YAMLBuilder {
    
    /// Accesses `packageInfo.renameManifestPackage`.
    public var renameManifestPackage: String? {
        get {
            let val = node["packageInfo"]?["renameManifestPackage"]
            if val?.tag == Tag(.null) { return nil }
            return val?.string
        }
        set {
            if node["packageInfo"] == nil {
                node["packageInfo"] = try? Node([String: String]())
            }
            
            if let v = newValue {
                node["packageInfo"]?["renameManifestPackage"] = Node(v)
            } else {
                // Create a scalar node "null" with the null tag
                node["packageInfo"]?["renameManifestPackage"] = Node("null", Tag(.null))
            }
        }
    }
    
    /// Accesses `versionInfo.versionCode`.
    public var versionCode: String? {
        get {
            let val = node["versionInfo"]?["versionCode"]
            if let intVal = val?.int {
                return String(intVal)
            }
            return val?.string
        }
        set {
            if node["versionInfo"] == nil {
                node["versionInfo"] = try? Node([String: String]())
            }
            node["versionInfo"]?["versionCode"] = newValue.map { Node($0) }
        }
    }
    
    /// Accesses `versionInfo.versionName`.
    public var versionName: String? {
        get {
            return node["versionInfo"]?["versionName"]?.string
        }
        set {
            if node["versionInfo"] == nil {
                node["versionInfo"] = try? Node([String: String]())
            }
            node["versionInfo"]?["versionName"] = newValue.map { Node($0) }
        }
    }
}
