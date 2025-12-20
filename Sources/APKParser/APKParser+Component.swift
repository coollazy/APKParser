import Foundation

extension APKParser {
    
    /// Applies a component to the APK.
    ///
    /// This method creates an `APKContext` with the necessary builders, executes the component's `apply` method,
    /// and then automatically saves (builds) any changes made to `AndroidManifest.xml`, `apktool.yml`, and `strings.xml`.
    ///
    /// - Parameter component: The component to apply.
    /// - Returns: The `APKParser` instance for method chaining.
    /// - Throws: An error if the component fails or if file operations fail.
    @discardableResult
    public func apply(_ component: APKComponent) throws -> Self {
        
        // 1. Initialize Builders
        // These builders load the current state of the files from disk.
        let manifestBuilder = try ManifestBuilder(androidManifestURL)
        let yamlBuilder = try YAMLBuilder(apktoolYamlURL)
        let stringsBuilder = try StringsBuilder(stringsURL)
        
        // 2. Create Context
        let context = APKContext(
            manifestBuilder: manifestBuilder,
            yamlBuilder: yamlBuilder,
            stringsBuilder: stringsBuilder,
            appDirectory: appDirectory,
            resDirectory: resDirectory
        )
        
        // 3. Apply Component Logic
        // The component modifies the builders in-memory.
        try component.apply(context)
        
        // 4. Save Changes
        // Write the modified state back to the files.
        try manifestBuilder.build(to: androidManifestURL)
        try yamlBuilder.build(to: apktoolYamlURL)
        try stringsBuilder.build(to: stringsURL)
        
        return self
    }
}
