import Foundation

extension APKParser {
    /// Retrieves the display name of the application.
    ///
    /// This method first checks `AndroidManifest.xml` for the `android:label` attribute.
    /// If the label is a resource reference (e.g., `@string/app_name`), it resolves the value from `strings.xml`.
    /// Otherwise, it returns the raw string value from the manifest.
    ///
    /// - Returns: The display name as a `String` if found, otherwise `nil`.
    public func displayName() -> String? {
        // 1. Get label from Manifest
        guard let manifestBuilder = try? ManifestBuilder(androidManifestURL),
              let rawLabel = manifestBuilder.applicationLabel else {
            return nil
        }
        
        // 2. Check if it is a resource reference
        if rawLabel.hasPrefix("@string/") {
            let resourceName = String(rawLabel.dropFirst("@string/".count))
            guard let stringsBuilder = try? StringsBuilder(stringsURL) else {
                return nil
            }
            // Find the string in strings.xml
            let strings = stringsBuilder.xml.rootElement()?.elements(forName: "string") ?? []
            return strings.first {
                $0.attribute(forName: "name")?.stringValue == resourceName
            }?.stringValue
        }
        
        // 3. It's a hardcoded string
        return rawLabel
    }
    
    /// Replaces the display name of the application.
    ///
    /// This method intelligently handles the update:
    /// - If the current `android:label` in `AndroidManifest.xml` refers to a string resource (e.g., `@string/app_name`),
    ///   it updates the value in `strings.xml`.
    /// - If the current label is a hardcoded string or cannot be resolved, it updates the `android:label` attribute
    ///   in `AndroidManifest.xml` directly with the new name.
    ///
    /// - Note: If the replacement fails (e.g., file not found), the error is logged to the console, and the operation is silently ignored.
    ///
    /// - Parameter displayName: The new display name for the application. If `nil`, no changes are made.
    /// - Returns: The `APKParser` instance for method chaining.
    @discardableResult
    public func replace(displayName: String?) -> Self {
        guard let displayName = displayName else {
            return self
        }
        
        // If current display name is already the same, do nothing
        if self.displayName() == displayName {
            return self
        }
        
        do {
            let manifestBuilder = try ManifestBuilder(androidManifestURL)
            let currentLabel = manifestBuilder.applicationLabel
            
            if let currentLabel = currentLabel, currentLabel.hasPrefix("@string/") {
                // Case 1: It's a resource reference. Update strings.xml
                let resourceName = String(currentLabel.dropFirst("@string/".count))
                try StringsBuilder(stringsURL)
                    .replace(name: resourceName, value: displayName)
                    .build(to: stringsURL)
            } else {
                // Case 2: It's a hardcoded string or missing. Update Manifest directly.
                manifestBuilder.applicationLabel = displayName
                try manifestBuilder.build(to: androidManifestURL)
            }
        }
        catch {
            debugPrint("[APKParser Replace Display Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
