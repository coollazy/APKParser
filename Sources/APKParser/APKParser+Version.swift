import Foundation

extension APKParser {
    
    /// The version name of the application.
    ///
    /// - Returns: The version name as a `String` if available, otherwise `nil`.
    public func version() -> String? {
        let builder = try? YAMLBuilder(apktoolYamlURL)
        return builder?.versionName
    }
    
    /// The version code of the application.
    ///
    /// - Returns: The version code as a `String` if available, otherwise `nil`.
    public func versionCode() -> String? {
        let builder = try? YAMLBuilder(apktoolYamlURL)
        return builder?.versionCode
    }
    
    /// The combined version string in the format "VersionName.VersionCode".
    ///
    /// - Returns: The combined version string, or `nil` if reading fails or fields are missing.
    /// - Throws: An error if the `apktool.yml` file cannot be read.
    public func versionWithCode() throws -> String? {
        let builder = try YAMLBuilder(apktoolYamlURL)
        guard let name = builder.versionName,
              let code = builder.versionCode else {
            return nil
        }
        return "\(name).\(code)"
    }
    
    /// Replaces the version code of the application in `apktool.yml`.
    ///
    /// If the provided `versionCode` is `nil`, no operation is performed.
    /// - Parameter versionCode: The new version code as a `String`.
    /// - Returns: The `APKParser` instance for method chaining.
    @discardableResult
    public func replace(versionCode: String?) -> Self {
        guard let versionCode = versionCode else {
            return self
        }
        
        do {
            let builder = try YAMLBuilder(apktoolYamlURL)
            builder.versionCode = versionCode
            try builder.build(to: apktoolYamlURL)
        } catch {
            debugPrint("[APKParser Replace Version Code ERROR] \(error.localizedDescription)")
        }
        return self
    }
    
    /// Replaces the version name of the application in `apktool.yml`.
    ///
    /// If the provided `versionName` is `nil`, no operation is performed.
    /// - Parameter versionName: The new version name as a `String`.
    /// - Returns: The `APKParser` instance for method chaining.
    @discardableResult
    public func replace(versionName: String?) -> Self {
        guard let versionName = versionName else {
            return self
        }
        
        do {
            let builder = try YAMLBuilder(apktoolYamlURL)
            builder.versionName = versionName
            try builder.build(to: apktoolYamlURL)
        } catch {
            debugPrint("[APKParser Replace Version Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
