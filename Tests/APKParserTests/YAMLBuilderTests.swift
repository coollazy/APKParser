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
        builder.versionName = "2.0.0"
        
        // Save
        try builder.build(to: tempFileURL)
        
        // Verify
        let newBuilder = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(newBuilder.renameManifestPackage, "com.new.package")
        XCTAssertEqual(newBuilder.versionCode, "11")
        XCTAssertEqual(newBuilder.versionName, "2.0.0")
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
        
        XCTAssertEqual(builder.versionCode, "123")
        XCTAssertEqual(builder.versionName, "1.0")
        
        builder.versionCode = "321"
        try builder.build(to: tempFileURL)
        
        builder.versionName = "1.1"
        try builder.build(to: tempFileURL)
        
        let builder2 = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(builder2.versionCode, "321")
        XCTAssertEqual(builder2.versionName, "1.1")
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
        
        let builder2 = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(builder2.versionCode, "456")
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
