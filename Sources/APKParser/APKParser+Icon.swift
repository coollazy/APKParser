import Foundation

extension APKParser {
    @discardableResult
    public func replace(iconURL: URL?) throws -> Self {
        guard let iconURL = iconURL else {
            return self
        }
        
        do {
            let manifestBuilder = try ManifestBuilder(androidManifestURL)
            
            try APKIconBuilder(sourceURL: iconURL, iconType: .rectangle(iconName: manifestBuilder.iconName))
                .build(toResDirectory: resDirectory)
        }
        catch let error as APKIconBuilderError {
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
    
    @discardableResult
    public func replace(roundIconURL: URL?) throws -> Self {
        guard let roundIconURL = roundIconURL else {
            return self
        }
        
        do {
            let manifestBuilder = try ManifestBuilder(androidManifestURL)
            
            try APKIconBuilder(sourceURL: roundIconURL, iconType: .round(iconName: manifestBuilder.iconRoundName))
                .build(toResDirectory: resDirectory)
        }
        catch let error as APKIconBuilderError {
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
