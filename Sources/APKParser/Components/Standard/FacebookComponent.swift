import Foundation

/// A component for configuring Facebook SDK.
///
/// This component can update the Facebook App ID and Client Token in `AndroidManifest.xml` and `strings.xml`.
public struct FacebookComponent: APKComponent {
    
    /// The Facebook App ID.
    /// This updates `com.facebook.sdk.ApplicationId` in `AndroidManifest.xml`
    /// and `facebook_app_id` in `strings.xml`.
    public let appID: String?
    
    /// The Facebook Client Token.
    /// This updates `com.facebook.sdk.ClientToken` in `AndroidManifest.xml`
    /// and `facebook_client_token` in `strings.xml`.
    public let clientToken: String?
    
    /// The display name for the Facebook app configuration.
    /// This updates the `facebook_app_name` in `strings.xml`.
    public let displayName: String?
    
    public init(appID: String? = nil, clientToken: String? = nil, displayName: String? = nil) {
        self.appID = appID
        self.clientToken = clientToken
        self.displayName = displayName
    }
    
    public func apply(_ context: APKContext) throws {
        // 1. Update AndroidManifest.xml (Meta-data)
        // Note: The value for ApplicationId in manifest usually points to a string resource (@string/facebook_app_id),
        // but some setups might put the raw value directly. We support replacing the meta-data value if it exists.
        // However, the standard way is to update the string resource it points to.
        // If the meta-data value is "@string/facebook_app_id", updating strings.xml is sufficient.
        // If the meta-data value is a hardcoded ID, we replace it here.
        // We will try to replace both to be safe, or just focus on strings if that's the convention.
        
        // Facebook SDK best practice is to put values in strings.xml and reference them in Manifest.
        // So modifying strings.xml is the primary action.
        
        if let appID = appID {
            // Update string resource
            _ = context.stringsBuilder.replace(name: "facebook_app_id", value: appID)
            
            // Also try to replace meta-data if it was hardcoded (less common but possible)
            context.manifestBuilder.replaceApplicationMetaData(
                name: "com.facebook.sdk.ApplicationId",
                value: appID
            )
        }
        
        if let clientToken = clientToken {
            _ = context.stringsBuilder.replace(name: "facebook_client_token", value: clientToken)
            
            context.manifestBuilder.replaceApplicationMetaData(
                name: "com.facebook.sdk.ClientToken",
                value: clientToken
            )
        }
        
        if let displayName = displayName {
            _ = context.stringsBuilder.replace(name: "facebook_app_name", value: displayName)
        }
    }
}
