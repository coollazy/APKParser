import Foundation
import Image

/**
 用來產生  Android APK 使用的圖檔
 */
public class APKIconBuilder {
    public let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("APKIconBuilder")
    
    private var sourceURL: URL
    private let iconType: Icon
    
    public init(sourceURL: URL, iconType: Icon) throws {
        self.sourceURL = sourceURL
        self.iconType = iconType
        
        if sourceURL.scheme != "file" {
            self.sourceURL = try download(url: sourceURL)
        }
        
        try isValidImage(imageURL: sourceURL)
    }
    
    private func isValidImage(imageURL: URL) throws {
        guard let image = try? Image(url: imageURL) else {
            throw APKIconBuilderError.invalidImageFormat
        }
        guard image.format == .png else {
            throw APKIconBuilderError.invalidImageFormat
        }
        guard image.size?.width == 1024, image.size?.height == 1024 else {
            throw APKIconBuilderError.invalidImageSize
        }
    }
    
    public func build(toResDirectory: URL) throws {
        let sourceImage = try Image(url: sourceURL)
        try Folder.allCases.forEach { folder in
            let resizeImage = try sourceImage.resize(to: folder.size)
            // 替換icon
            let iconURL = toResDirectory
                .appendingPathComponent(folder.path)
                .appendingPathComponent(iconType.fileName)
            if FileManager.default.fileExists(atPath: iconURL.path) == true {
                try FileManager.default.removeItem(at: iconURL)
                try resizeImage.data.write(to: iconURL)
            }
        }
    }
}

extension APKIconBuilder {
    private func download(url: URL) throws -> URL {
        let downloadURL = tempDirectory
            .appendingPathComponent("download-" + UUID().uuidString)
            .appendingPathComponent("icon.png")
        
        if FileManager.default.fileExists(atPath: downloadURL.deletingLastPathComponent().path) == false {
            try FileManager.default.createDirectory(at: downloadURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        }
        
        guard let data = try? Data(contentsOf: url) else {
            throw APKIconBuilderError.downloadImageFailed
        }
        try data.write(to: downloadURL)
        
        return downloadURL
    }
}

// MARK: - Android 專用的 icon 檔名，路徑跟尺寸
extension APKIconBuilder {
    public enum Icon {
        case rectangle(iconName: String?)
        case round(iconName: String?)
        
        var fileName: String {
            switch self {
            case .rectangle(let iconName):
                return iconName ?? "ic_launcher.png"
            case .round(let iconName):
                return iconName ?? "ic_launcher_round.png"
            }
        }
    }
    
    enum Folder: String, CaseIterable {
        case mdpi = "mdpi"
        case hdpi = "hdpi"
        case xhdpi = "xhdpi"
        case xxhdpi = "xxhdpi"
        case xxxhdpi = "xxxhdpi"
        
        var path: String {
            "mipmap-\(rawValue)"
        }
        
        var size: CGSize {
            let size1X = CGSize(width: 48, height: 48)
            switch self {
            case .mdpi:
                return size1X
            case .hdpi:
                return size1X * 1.5
            case .xhdpi:
                return size1X * 2
            case .xxhdpi:
                return size1X * 3
            case .xxxhdpi:
                return size1X * 4
            }
        }
    }
}
