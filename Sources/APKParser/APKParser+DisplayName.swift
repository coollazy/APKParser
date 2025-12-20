import Foundation

extension APKParser {
    /// Retrieves the display name of the application from `strings.xml`.
    ///
    /// This method looks for a `<string>` element with `name="app_name"` in the `strings.xml` file.
    ///
    /// - Returns: The display name as a `String` if found, otherwise `nil`.
    public func displayName() -> String? {
        guard let builder = try? StringsBuilder(stringsURL) else {
            return nil
        }
        let strings = builder.xml.rootElement()?.elements(forName: "string") ?? []
        return strings.first {
            $0.attribute(forName: "name")?.stringValue == "app_name"
        }?.stringValue
    }
    
    /// Replaces the display name of the application.
    ///
    /// This method modifies the `app_name` (or equivalent) in the `strings.xml` resource file.
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
            try StringsBuilder(stringsURL)
                .replace(displayName: displayName)
                .build(to: stringsURL)
        }
        catch {
            debugPrint("[APKParser Replace Display Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
