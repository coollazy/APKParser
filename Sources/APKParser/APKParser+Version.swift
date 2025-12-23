import Foundation

extension APKParser {
    /// Retrieves the version name of the APK.
    ///
    /// This method parses the `apktool.yml` file to extract the `versionName` defined in the APK.
    ///
    /// - Returns: The version name as a `String` if available, or `nil` if parsing fails.
    public func version() -> String? {
        let builder = try? YAMLBuilder(apktoolYamlURL)
        return builder?.yaml.versionInfo.versionName
    }
    
    /// Retrieves the version code of the APK.
    ///
    /// This method parses the `apktool.yml` file to extract the `versionCode` defined in the APK.
    ///
    /// - Returns: The version code as a `String` if available, or `nil` if parsing fails.
    public func versionCode() -> String? {
        let builder = try? YAMLBuilder(apktoolYamlURL)
        return builder?.yaml.versionInfo.versionCode
    }
    
    /// Retrieves a combined string of version name and version code.
    ///
    /// - Returns: A string in the format `"{versionName}.{versionCode}"` (e.g., "1.0.0.100").
    /// - Throws: An error if the `apktool.yml` file cannot be parsed.
    public func versionWithCode() throws -> String? {
        let builder = try YAMLBuilder(apktoolYamlURL)
        return "\(builder.yaml.versionInfo.versionName).\(builder.yaml.versionInfo.versionCode)"
    }
}
