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
    
    func testParseInvalidYAML() {
        let yamlContent = "invalid: yaml: content: ["
        try? createYAMLFile(content: yamlContent)
        
        XCTAssertThrowsError(try YAMLBuilder(tempFileURL))
    }
}
