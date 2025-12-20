import Foundation

extension APKParser {
    /// Replaces the package name of the application.
    ///
    /// This method performs two operations:
    /// 1. Updates the `package` attribute in `AndroidManifest.xml`.
    /// 2. Updates the `renameManifestPackage` field in `apktool.yml` to ensure `apktool` handles the resource ID updates correctly during build.
    ///
    /// - Note: If the replacement fails, the error is logged to the console, and the operation is silently ignored.
    ///
    /// - Parameter packageName: The new package name (e.g., "com.example.newapp"). If `nil`, no changes are made.
    /// - Returns: The `APKParser` instance for method chaining.
    @discardableResult
    public func replace(packageName: String?) -> Self {
        guard let packageName = packageName else {
            return self
        }
        
        do {
            try ManifestBuilder(androidManifestURL)
                .replace(packageName: packageName)
                .build(to: androidManifestURL)
            
            let content = try String(contentsOf: apktoolYamlURL)
            let newContent = content.replacingOccurrences(of: "renameManifestPackage: null", with: "renameManifestPackage: \(packageName)")
            try newContent.write(to: apktoolYamlURL, atomically: true, encoding: .utf8)
        }
        catch {
            debugPrint("[APKParser Replace Package Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
