import Foundation

/// A protocol that defines a component capable of modifying an APK.
///
/// Conform to this protocol to create reusable modules for integrating third-party SDKs
/// or applying common configurations (e.g., adding permissions, setting up meta-data).
public protocol APKComponent {
    
    /// Applies the component's logic to the given APK context.
    ///
    /// - Parameter context: The context containing builders and file paths for the APK.
    /// - Throws: An error if the modification fails.
    func apply(_ context: APKContext) throws
}
