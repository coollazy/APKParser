import Foundation

/// A component for configuring Google SDKs (e.g., Maps, Sign-In).
///
/// This component can update the Google Maps API Key in `AndroidManifest.xml`
/// and the Google App ID in `strings.xml`.
public struct GoogleComponent: APKComponent {
    
    /// The API Key for Google Maps SDK.
    /// This corresponds to the meta-data `com.google.android.geo.API_KEY` in `AndroidManifest.xml`.
    public let apiKey: String?
    
    /// The Google App ID (often used for Sign-In or Firebase).
    /// This updates the `google_app_id` and `default_web_client_id` in `strings.xml`.
    public let appID: String?
    
    public init(apiKey: String? = nil, appID: String? = nil) {
        self.apiKey = apiKey
        self.appID = appID
    }
    
    public func apply(_ context: APKContext) throws {
        // 1. Update AndroidManifest.xml
        if let apiKey = apiKey {
            _ = context.manifestBuilder.replaceApplicationMetaData(
                name: "com.google.android.geo.API_KEY",
                value: apiKey
            )
        }
        
        // 2. Update strings.xml
        if let appID = appID {
            // These are standard string names used by Google Services plugin/SDK
            _ = context.stringsBuilder.replace(name: "google_app_id", value: appID)
            _ = context.stringsBuilder.replace(name: "default_web_client_id", value: appID)
            _ = context.stringsBuilder.replace(name: "google_server_client_id_web", value: appID) // Added for broader compatibility
        }
    }
}
