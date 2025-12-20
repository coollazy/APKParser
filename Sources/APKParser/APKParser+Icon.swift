import Foundation

extension APKParser {
    /// Replaces the application's launcher icon.
    ///
    /// This method identifies the icon name from `AndroidManifest.xml` and replaces the corresponding image files
    /// in the `res` directories (e.g., `mipmap-hdpi`, `mipmap-xhdpi`, etc.) with the provided image.
    /// The input image is automatically resized to generate icons for different densities.
    ///
    /// - Parameter iconURL: The file URL of the new icon image (must be a PNG). If `nil`, no changes are made.
    /// - Returns: The `APKParser` instance for method chaining.
    /// - Throws:
    ///   - `APKParserError.invalidIconFormat`: If the image is not a valid PNG.
    ///   - `APKParserError.invalidIconSize`: If the image dimensions are not 1024x1024.
    ///   - `APKParserError.iconImageNotFound`: If the source image file cannot be read.
    ///   - Other errors if file system operations fail.
    @discardableResult
    public func replace(iconURL: URL?) throws -> Self {
        guard let iconURL = iconURL else {
            return self
        }
        
        do {
            let manifestBuilder = try ManifestBuilder(androidManifestURL)
            
            try IconBuilder(sourceURL: iconURL, iconType: .rectangle(iconName: manifestBuilder.iconName))
                .build(toResDirectory: resDirectory)
        }
        catch let error as IconBuilderError {
            switch error {
            case .invalidImageFormat:
                throw APKParserError.invalidIconFormat
            case .invalidImageSize:
                throw APKParserError.invalidIconSize
            default:
                throw APKParserError.iconImageNotFound
            }
        }
        catch {
            throw error
        }
        
        return self
    }
    
    /// Replaces the application's round launcher icon.
    ///
    /// Similar to `replace(iconURL:)`, this method replaces the round icon resource defined in `AndroidManifest.xml`.
    ///
    /// - Parameter roundIconURL: The file URL of the new round icon image (must be a PNG). If `nil`, no changes are made.
    /// - Returns: The `APKParser` instance for method chaining.
    /// - Throws:
    ///   - `APKParserError.invalidIconFormat`: If the image is not a valid PNG.
    ///   - `APKParserError.invalidIconSize`: If the image dimensions are not 1024x1024.
    ///   - `APKParserError.iconImageNotFound`: If the source image file cannot be read.
    ///   - Other errors if file system operations fail.
    @discardableResult
    public func replace(roundIconURL: URL?) throws -> Self {
        guard let roundIconURL = roundIconURL else {
            return self
        }
        
        do {
            let manifestBuilder = try ManifestBuilder(androidManifestURL)
            
            try IconBuilder(sourceURL: roundIconURL, iconType: .round(iconName: manifestBuilder.iconRoundName))
                .build(toResDirectory: resDirectory)
        }
        catch let error as IconBuilderError {
            switch error {
            case .invalidImageFormat:
                throw APKParserError.invalidIconFormat
            case .invalidImageSize:
                throw APKParserError.invalidIconSize
            default:
                throw APKParserError.iconImageNotFound
            }
        }
        catch {
            throw error
        }
        
        return self
    }
}
