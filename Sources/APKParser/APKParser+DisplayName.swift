import Foundation

extension APKParser {
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
