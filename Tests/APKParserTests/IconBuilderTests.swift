import XCTest
@testable import APKParser

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
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Use ImageMagick 'convert' which is installed in both macOS and Linux CI environments
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["convert", "-size", "\(width)x\(height)", "xc:red", url.path]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Failed to run convert: \(error)")
            return false
        }
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
