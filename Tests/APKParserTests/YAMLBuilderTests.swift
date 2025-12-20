import XCTest
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
    
    func testParseAndModifyYAML() throws {
        let yamlContent = """
        packageInfo:
          renameManifestPackage: null
        versionInfo:
          versionCode: '1'
          versionName: 1.0.0
        """
        try createYAMLFile(content: yamlContent)
        
        let builder = try YAMLBuilder(tempFileURL)
        
        XCTAssertNil(builder.yaml.packageInfo.renameManifestPackage)
        XCTAssertEqual(builder.yaml.versionInfo.versionCode, "1")
        XCTAssertEqual(builder.yaml.versionInfo.versionName, "1.0.0")
        
        // Modify
        builder.yaml.packageInfo.renameManifestPackage = "com.new.package"
        builder.yaml.versionInfo.versionCode = "2"
        builder.yaml.versionInfo.versionName = "1.0.1"
        
        // Build to new file
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_out.yml")
        try builder.build(to: outputURL)
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        // Read back to verify
        let newBuilder = try YAMLBuilder(outputURL)
        XCTAssertEqual(newBuilder.yaml.packageInfo.renameManifestPackage, "com.new.package")
        XCTAssertEqual(newBuilder.yaml.versionInfo.versionCode, "2")
        XCTAssertEqual(newBuilder.yaml.versionInfo.versionName, "1.0.1")
    }
    
    func testModifyVersionIndependently() throws {
        let yamlContent = """
        packageInfo:
          renameManifestPackage: null
        versionInfo:
          versionCode: '10'
          versionName: 1.0.0
        """
        try createYAMLFile(content: yamlContent)
        
        // Mimic replace(versionName:)
        let builder1 = try YAMLBuilder(tempFileURL)
        builder1.yaml.versionInfo.versionName = "2.0.0"
        try builder1.build(to: tempFileURL)
        
        // Mimic replace(versionCode:)
        let builder2 = try YAMLBuilder(tempFileURL)
        builder2.yaml.versionInfo.versionCode = "20"
        try builder2.build(to: tempFileURL)
        
        // Verify
        let finalBuilder = try YAMLBuilder(tempFileURL)
        XCTAssertEqual(finalBuilder.yaml.versionInfo.versionName, "2.0.0")
        XCTAssertEqual(finalBuilder.yaml.versionInfo.versionCode, "20")
    }
    
    func testParseInvalidYAML() {
        let yamlContent = "invalid: yaml: content: ["
        try? createYAMLFile(content: yamlContent)
        
        XCTAssertThrowsError(try YAMLBuilder(tempFileURL))
    }
}
