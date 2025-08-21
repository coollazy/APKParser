import Foundation

extension APKParser {
    public func version() -> String? {
        let builder = try? YAMLBuilder(apktoolYamlURL)
        return builder?.yaml.versionInfo.versionName
    }
    
    public func versionCode() -> String? {
        let builder = try? YAMLBuilder(apktoolYamlURL)
        return builder?.yaml.versionInfo.versionName
    }
    
    public func versionWithCode() throws -> String? {
        let builder = try YAMLBuilder(apktoolYamlURL)
        return "\(builder.yaml.versionInfo.versionName).\(builder.yaml.versionInfo.versionCode)"
    }
}
