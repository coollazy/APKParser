import XCTest
import Yams
@testable import APKParser

final class YAMLBuilderTests: XCTestCase {
    
    var tempFileURL: URL!
    
    override func setUp() {
        super.setUp()
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".yml")
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }
    
    private func createYAMLFile(content: String) throws {
        try content.write(to: tempFileURL, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Basic Read/Write
    
    func testBasicReadWrite() throws {
        let yamlContent = """
        packageInfo:
          renameManifestPackage: null
        versionInfo:
          versionCode: '10'
          versionName: 1.0.0
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        
        XCTAssertNil(builder.renameManifestPackage)
        XCTAssertEqual(builder.versionCode, "10")
        XCTAssertEqual(builder.versionName, "1.0.0")
        
        // Modify
        builder.renameManifestPackage = "com.new.package"
        builder.versionCode = "11"
        
        // Save
        try builder.build(to: tempFileURL)
        
        // Verify
        let newBuilder = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(newBuilder.renameManifestPackage, "com.new.package")
        XCTAssertEqual(newBuilder.versionCode, "11")
    }
    
    // MARK: - Type Coercion (Int <-> String)
    
    func testIntegerVersionCodeReading() throws {
        // apktool often outputs versionCode as an integer (no quotes)
        let yamlContent = """
        versionInfo:
          versionCode: 123
          versionName: 1.0
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        
        // 1. Verify we can read Int as String
        XCTAssertEqual(builder.versionCode, "123")
        
        // 2. Write back WITHOUT modifying versionCode
        builder.versionName = "1.1"
        try builder.build(to: tempFileURL)
        
        // 3. Verify the file content still has versionCode as Int (123) not String ("123")
        // Because we used Node, untouched nodes should preserve their tag/type.
        let outputContent = try String(contentsOf: tempFileURL)
        // Regex to check for `versionCode: 123` (no quotes)
        // Note: Yams serialization might change spacing, but it shouldn't add quotes if it's still an Int Node.
        // However, Yams *might* reserialize everything. If the Node was parsed as Int, it serializes as Int.
        XCTAssertTrue(outputContent.contains("versionCode: 123"), "Should preserve Integer formatting if untouched")
        XCTAssertFalse(outputContent.contains("versionCode: '123'"), "Should not add quotes to Integer if untouched")
    }
    
    func testIntegerVersionCodeModification() throws {
        let yamlContent = """
        versionInfo:
          versionCode: 123
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        
        // Modify to a new value (String setter)
        builder.versionCode = "456"
        try builder.build(to: tempFileURL)
        
        let outputContent = try String(contentsOf: tempFileURL)
        // Since we set it via String, it might be serialized as String or Int depending on Yams inference.
        // Yams Node(string) usually serializes as string.
        // Check if it's "456" or '456' or just 456 (if Yams detects it looks like int).
        // Actually, our implementation uses Node(v) which creates a Scalar string.
        // So we expect it to be a string in YAML now.
        // But let's verify checking the builder read back.
        let newBuilder = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(newBuilder.versionCode, "456")
    }
    
    // MARK: - Null Handling
    
    func testExplicitNullHandling() throws {
        let yamlContent = """
        packageInfo:
          renameManifestPackage: null
        """
        try createYAMLFile(content: yamlContent)
        let builder = try YAMLBuilder(tempFileURL)
        XCTAssertNil(builder.renameManifestPackage, "Explicit null should be nil")
        
        // Set to a string
        builder.renameManifestPackage = "com.test"
        try builder.build(to: tempFileURL)
        
        // Set back to nil
        let builder2 = try YAMLBuilder(tempFileURL)
        builder2.renameManifestPackage = nil
        try builder2.build(to: tempFileURL)
        
        // Verify output contains explicit null
        let content = try String(contentsOf: tempFileURL)
        XCTAssertTrue(content.contains("renameManifestPackage: null"), "Should write explicit null")
    }
    
    func testMissingKeyHandling() throws {
        let yamlContent = """
        packageInfo: {}
        """
        try createYAMLFile(content: yamlContent)
        let builder = try YAMLBuilder(tempFileURL)
        XCTAssertNil(builder.renameManifestPackage, "Missing key should be nil")
        
        // Set to value
        builder.renameManifestPackage = "com.added"
        try builder.build(to: tempFileURL)
        
        let builder2 = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(builder2.renameManifestPackage, "com.added")
    }
    
    // MARK: - Complex Structure Preservation
    
    func testComplexStructurePreservation() throws {
        // A comprehensive apktool.yml example
        let yamlContent = """
        version: 2.9.3
        apkFileName: test.apk
        isFrameworkApk: false
        usesFramework:
          ids:
          - 1
          tag: null
        sdkInfo:
          minSdkVersion: '29'
          targetSdkVersion: '33'
        packageInfo:
          forcedPackageId: '127'
          renameManifestPackage: null
        versionInfo:
          versionCode: '1'
          versionName: 1.0.0
        doNotCompress:
        - resources.arsc
        - png
        - jpg
        unknownSection:
          nested:
            - item1
            - item2
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        
        // Modify ONLY versionCode
        builder.versionCode = "2"
        try builder.build(to: tempFileURL)
        
        let content = try String(contentsOf: tempFileURL)
        
        // Assertions:
        XCTAssertTrue(content.contains("minSdkVersion: '29'"), "sdkInfo should be preserved")
        XCTAssertTrue(content.contains("doNotCompress:"), "List structure should be preserved")
        XCTAssertTrue(content.contains("- resources.arsc"), "List items should be preserved")
        XCTAssertTrue(content.contains("unknownSection:"), "Unknown sections should be preserved")
        XCTAssertTrue(content.contains("nested:"), "Nested unknown sections should be preserved")
        XCTAssertTrue(content.contains("versionCode: '2'") || content.contains("versionCode: 2") || content.contains("versionCode: \"2\""), "Modified field should be updated")
    }
    
    // MARK: - Lazy Initialization
    
    func testLazyInitialization() throws {
        // File with NO packageInfo or versionInfo
        let yamlContent = """
        sdkInfo:
          minSdkVersion: 21
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        XCTAssertNil(builder.versionCode)
        
        // Setting property should create the missing parent nodes (versionInfo)
        builder.versionCode = "99"
        builder.renameManifestPackage = "com.lazy"
        
        try builder.build(to: tempFileURL)
        
        let content = try String(contentsOf: tempFileURL)
        XCTAssertTrue(content.contains("versionInfo:"), "Should create versionInfo node")
        XCTAssertTrue(content.contains("packageInfo:"), "Should create packageInfo node")
        XCTAssertTrue(content.contains("versionCode:"), "Should contain value")
        XCTAssertTrue(content.contains("renameManifestPackage:"), "Should contain value")
    }
    
    // MARK: - Special Characters
    
    func testSpecialCharacters() throws {
        let yamlContent = """
        versionInfo:
          versionName: "Original Name"
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        let complexName = "Ver 2.0 (Beta) - Final"
        builder.versionName = complexName
        
        try builder.build(to: tempFileURL)
        
        let newBuilder = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(newBuilder.versionName, complexName)
        
        let content = try String(contentsOf: tempFileURL)
        // Yams should quote string with special chars/spaces if needed
        // We just verify it contains the text
        XCTAssertTrue(content.contains(complexName))
    }
    
    func testParseInvalidYAML() {
        let yamlContent = "invalid: [ unclosed sequence"
        try? createYAMLFile(content: yamlContent)
        
        XCTAssertThrowsError(try YAMLBuilder(tempFileURL))
    }
}
