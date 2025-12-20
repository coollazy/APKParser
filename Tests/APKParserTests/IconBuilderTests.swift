import XCTest
@testable import APKParser
import ImageIO
import UniformTypeIdentifiers

final class IconBuilderTests: XCTestCase {
    
    var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }
    
    private func createPNG(size: CGSize, url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return false }
        
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        // Fill with some red color to make it valid content
        for i in 0..<(width * height) {
            data[i * 4] = 255     // R
            data[i * 4 + 3] = 255 // A
        }
        
        guard let provider = CGDataProvider(data: Data(data) as CFData),
              let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bitsPerPixel: bytesPerPixel * 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: true,
                                    intent: .defaultIntent) else { return false }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        return CGImageDestinationFinalize(destination)
    }
    
    func testInitSuccess() throws {
        let imageURL = tempDir.appendingPathComponent("valid.png")
        _ = createPNG(size: CGSize(width: 1024, height: 1024), url: imageURL)
        
        XCTAssertNoThrow(try IconBuilder(sourceURL: imageURL, iconType: .rectangle(iconName: nil)))
    }
    
    func testInitInvalidSize() throws {
        let imageURL = tempDir.appendingPathComponent("small.png")
        _ = createPNG(size: CGSize(width: 500, height: 500), url: imageURL)
        
        XCTAssertThrowsError(try IconBuilder(sourceURL: imageURL, iconType: .rectangle(iconName: nil))) { error in
            XCTAssertEqual(error as? IconBuilderError, IconBuilderError.invalidImageSize)
        }
    }
    
    func testBuildReplacement() throws {
        // 1. Prepare Source Image
        let sourceImageURL = tempDir.appendingPathComponent("source.png")
        _ = createPNG(size: CGSize(width: 1024, height: 1024), url: sourceImageURL)
        
        // 2. Prepare Destination Structure
        let resDir = tempDir.appendingPathComponent("res")
        try FileManager.default.createDirectory(at: resDir, withIntermediateDirectories: true)
        
        let folders = ["mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi"]
        for folder in folders {
            let folderURL = resDir.appendingPathComponent(folder)
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            // Create a dummy file to be replaced
            let iconURL = folderURL.appendingPathComponent("ic_launcher.png")
            try "dummy content".write(to: iconURL, atomically: true, encoding: .utf8)
        }
        
        // 3. Build
        let builder = try IconBuilder(sourceURL: sourceImageURL, iconType: .rectangle(iconName: "ic_launcher.png"))
        try builder.build(toResDirectory: resDir)
        
        // 4. Verify
        for folder in folders {
            let iconURL = resDir.appendingPathComponent(folder).appendingPathComponent("ic_launcher.png")
            let attributes = try FileManager.default.attributesOfItem(atPath: iconURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            
            // "dummy content" is 13 bytes. A PNG should be much larger.
            XCTAssertGreaterThan(fileSize, 50, "File in \(folder) should have been replaced with a PNG")
        }
    }
    
    func testBuildNoReplacementIfFileDoesNotExist() throws {
        // 1. Prepare Source
        let sourceImageURL = tempDir.appendingPathComponent("source.png")
        _ = createPNG(size: CGSize(width: 1024, height: 1024), url: sourceImageURL)
        
        // 2. Prepare Empty Destination
        let resDir = tempDir.appendingPathComponent("res_empty")
        try FileManager.default.createDirectory(at: resDir, withIntermediateDirectories: true)
        let folderURL = resDir.appendingPathComponent("mipmap-mdpi")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        // ensure no file exists
        
        // 3. Build
        let builder = try IconBuilder(sourceURL: sourceImageURL, iconType: .rectangle(iconName: "ic_launcher.png"))
        try builder.build(toResDirectory: resDir)
        
        // 4. Verify
        let iconURL = folderURL.appendingPathComponent("ic_launcher.png")
        XCTAssertFalse(FileManager.default.fileExists(atPath: iconURL.path), "Should not create file if it didn't exist")
    }
}
