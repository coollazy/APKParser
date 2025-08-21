import Foundation

public enum APKIconBuilderError: Error, CustomStringConvertible, LocalizedError {
    case invalidImageFormat
    case invalidImageSize
    case downloadImageFailed
    
    public var description: String {
        switch self {
        case .invalidImageFormat:
            return NSLocalizedString("IPAIconBuilder invalid image format !!", comment: "")
        case .invalidImageSize:
            return NSLocalizedString("IPAIconBuilder invalid image size !! Should be 1024 * 1024", comment: "")
        case .downloadImageFailed:
            return NSLocalizedString("IPAIconBuilder download image from remote failed !!", comment: "")
        }
    }
    
    public var errorDescription: String? {
        description
    }
}
