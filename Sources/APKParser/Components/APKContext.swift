import Foundation

/// A context object that provides access to the APK's resources and configuration builders.
///
/// Components use this context to modify the `AndroidManifest.xml`, `strings.xml`, `apktool.yml`,
/// or to access the unpacked application directory directly.
public struct APKContext {
    
    /// The builder for modifying `AndroidManifest.xml`.
    /// Use this to add permissions, activities, meta-data, etc.
    public let manifestBuilder: ManifestBuilder
    
    /// The builder for modifying `apktool.yml`.
    /// Use this to change version information or other apktool configurations.
    public let yamlBuilder: YAMLBuilder
    
    /// The builder for modifying `res/values/strings.xml`.
    /// Use this to change the application name or other localized strings.
    public let stringsBuilder: StringsBuilder
    
    /// The root directory of the unpacked APK.
    public let appDirectory: URL
    
    /// The `res` directory containing application resources (drawables, layouts, values, etc.).
    public let resDirectory: URL
    
    /// The `assets` directory containing application assets.
    public let assetsDirectory: URL
    
    internal init(
        manifestBuilder: ManifestBuilder,
        yamlBuilder: YAMLBuilder,
        stringsBuilder: StringsBuilder,
        appDirectory: URL,
        resDirectory: URL,
        assetsDirectory: URL
    ) {
        self.manifestBuilder = manifestBuilder
        self.yamlBuilder = yamlBuilder
        self.stringsBuilder = stringsBuilder
        self.appDirectory = appDirectory
        self.resDirectory = resDirectory
        self.assetsDirectory = assetsDirectory
    }
}
