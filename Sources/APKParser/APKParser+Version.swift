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
    
    /// Replaces the version name of the APK.
    ///
    /// This method modifies the `versionName` in the `apktool.yml` file.
    ///
    /// - Note: If the replacement fails, the error is logged to the console, and the operation is silently ignored.
    ///
    /// - Parameter versionName: The new version name (e.g., "1.2.0"). If `nil`, no changes are made.
    /// - Returns: The `APKParser` instance for method chaining.
    @discardableResult
    public func replace(versionName: String?) -> Self {
        guard let versionName = versionName else {
            return self
        }
        do {
            let builder = try YAMLBuilder(apktoolYamlURL)
            builder.yaml.versionInfo.versionName = versionName
            try builder.build(to: apktoolYamlURL)
        } catch {
            debugPrint("[APKParser Replace VersionName ERROR] \(error.localizedDescription)")
        }
        return self
    }
    
    /// Replaces the version code of the APK.
    ///
    /// This method modifies the `versionCode` in the `apktool.yml` file.
    ///
    /// - Note: If the replacement fails, the error is logged to the console, and the operation is silently ignored.
    ///
    /// - Parameter versionCode: The new version code (e.g., "102"). If `nil`, no changes are made.
    /// - Returns: The `APKParser` instance for method chaining.
    @discardableResult
    public func replace(versionCode: String?) -> Self {
        guard let versionCode = versionCode else {
            return self
        }
        do {
            let builder = try YAMLBuilder(apktoolYamlURL)
            builder.yaml.versionInfo.versionCode = versionCode
            try builder.build(to: apktoolYamlURL)
        } catch {
            debugPrint("[APKParser Replace VersionCode ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
