import Foundation

/// A component for configuring the LinkDeep SDK.
///
/// This component replaces the `LINK_DEEP_APP_KEY` meta-data in `AndroidManifest.xml`
/// and updates the corresponding schemes in `intent-filter` data tags.
public struct LinkDeepComponent: APKComponent {
    
    /// The App Key for the LinkDeep SDK.
    /// This replaces `LINK_DEEP_APP_KEY` meta-data and scheme.
    public let appKey: String?
    
    /// The Group Scheme for the LinkDeep SDK.
    /// This replaces `LINK_DEEP_GROUP_SCHEME` scheme.
    public let groupScheme: String?
    
    public init(appKey: String? = nil, groupScheme: String? = nil) {
        self.appKey = appKey
        self.groupScheme = groupScheme
    }
    
    public func apply(_ context: APKContext) throws {
        // 1. Update AndroidManifest.xml meta-data for LINK_DEEP_APP_KEY
        if let appKey = appKey {
            _ = context.manifestBuilder.replaceApplicationMetaData(
                name: "LINK_DEEP_APP_KEY",
                value: appKey
            )
        }
        
        // 2. Update schemes in intent-filters
        // Assume the original APK has placeholders or an old value we can replace.
        // We do NOT add new schemes if they don't exist, as per user instruction.
        if let appKey = appKey {
            // Replace the appKey scheme
            context.manifestBuilder.replaceScheme(
                oldScheme: "${LINK_DEEP_APP_KEY}", // Placeholder from build.gradle
                newScheme: appKey
            )
        }
        
        if let groupScheme = groupScheme {
            // Replace the groupScheme
            context.manifestBuilder.replaceScheme(
                oldScheme: "${LINK_DEEP_GROUP_SCHEME}", // Placeholder from build.gradle
                newScheme: groupScheme
            )
        }
    }
}
