import Foundation

public enum APKParserError: Error, CustomStringConvertible, LocalizedError {
    case templateAPKNotFound(String)
    case apkInvalid
    case invalidIconFormat
    case invalidIconSize
    case iconImageNotFound
    case replaceCocosFailed(String)
    case replaceCocosStartupImageFailed(String)
    
    
    public var description: String {
        switch self {
        case .templateAPKNotFound(let path):
            return NSLocalizedString("APKParser can't find template APK at path => \(path)", comment: "")
        case .apkInvalid:
            return NSLocalizedString("APKParser can't find any *.app in template APK !!", comment: "")
        case .invalidIconFormat:
            return NSLocalizedString("APKParser invalid image format !!", comment: "")
        case .invalidIconSize:
            return NSLocalizedString("APKParser invalid image size !! Should be 1024 * 1024", comment: "")
        case .iconImageNotFound:
            return NSLocalizedString("APKParser icon image not found !!", comment: "")
        case .replaceCocosFailed(let errorDescription):
            return NSLocalizedString("APKParser replace cocos resource failed !! \(errorDescription)", comment: "")
        case .replaceCocosStartupImageFailed(let errorDescription):
            return NSLocalizedString("APKParser replace cocos start up image failed !! \(errorDescription)", comment: "")
        }
    }
    
    public var errorDescription: String? {
        description
    }
}
