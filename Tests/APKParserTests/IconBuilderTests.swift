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
    
    func testInitSuccess() throws {
        // Use pre-generated 1024x1024 image from Resources
        guard let imageURL = Bundle.module.url(forResource: "new_icon", withExtension: "png") else {
            XCTFail("new_icon.png not found in bundle")
            return
        }
        
        XCTAssertNoThrow(try IconBuilder(sourceURL: imageURL, iconType: .rectangle(iconName: nil)))
    }
    
    func testInitInvalidSize() throws {
        // Use pre-generated 500x500 image from Resources
        guard let imageURL = Bundle.module.url(forResource: "small_icon", withExtension: "png") else {
            XCTFail("small_icon.png not found in bundle")
            return
        }
        
        XCTAssertThrowsError(try IconBuilder(sourceURL: imageURL, iconType: .rectangle(iconName: nil))) { error in
            XCTAssertEqual(error as? IconBuilderError, IconBuilderError.invalidImageSize)
        }
    }
    
    func testBuildReplacement() throws {
        // 1. Prepare Source Image
        guard let sourceImageURL = Bundle.module.url(forResource: "new_icon", withExtension: "png") else {
             XCTFail("new_icon.png not found in bundle")
             return
        }
        
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
        guard let sourceImageURL = Bundle.module.url(forResource: "new_icon", withExtension: "png") else {
             XCTFail("new_icon.png not found in bundle")
             return
        }
        
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
    
    func testInitInvalidFileFormat() throws {
        let textFileURL = tempDir.appendingPathComponent("fake_image.png")
        try "This is text, not an image".write(to: textFileURL, atomically: true, encoding: .utf8)
        
        XCTAssertThrowsError(try IconBuilder(sourceURL: textFileURL, iconType: .rectangle(iconName: nil))) { error in
            XCTAssertEqual(error as? IconBuilderError, IconBuilderError.invalidImageFormat)
        }
    }
}
