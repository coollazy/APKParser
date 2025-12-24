import XCTest
@testable import APKParser
@testable import Command

final class APKParserFailureTests: XCTestCase {
    
    var tempAPKURL: URL!
    
    override func setUp() {
        super.setUp()
        tempAPKURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".apk")
        FileManager.default.createFile(atPath: tempAPKURL.path, contents: Data(), attributes: nil)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempAPKURL)
        super.tearDown()
    }
    
    func testInitThrowsOnCommandFailure() {
        let mockRunner = MockCommandRunner()
        mockRunner.errorToThrow = NSError(domain: "CommandError", code: 1, userInfo: nil)
        
        XCTAssertThrowsError(try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner))
    }
    
    func testBuildThrowsOnCommandFailure() throws {
        let mockRunner = MockCommandRunner()
        let parser = try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner)
        
        mockRunner.errorToThrow = NSError(domain: "CommandError", code: 1, userInfo: nil)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.apk")
        
        XCTAssertThrowsError(try parser.build(toPath: outputURL))
    }
    
    func testReplaceDisplayNameWithMissingFiles() throws {
        let mockRunner = MockCommandRunner()
        let parser = try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner)
        
        // Ensure files don't exist (parser.appDirectory is just a path at this point since mock apktool didn't actually decode anything)
        try? FileManager.default.removeItem(at: parser.stringsURL)
        
        // Should not throw, just log error and return self
        // Since we can't easily capture debugPrint in standard XCTest, we ensure it doesn't crash
        XCTAssertNoThrow(parser.replace(displayName: "New Name"))
        
        // Verify it didn't magically create the file
        XCTAssertFalse(FileManager.default.fileExists(atPath: parser.stringsURL.path))
    }
    
    func testReplacePackageNameWithMissingManifest() throws {
        let mockRunner = MockCommandRunner()
        let parser = try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner)
        
        try? FileManager.default.removeItem(at: parser.androidManifestURL)
        
        XCTAssertNoThrow(parser.replace(packageName: "com.new.pkg"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: parser.androidManifestURL.path))
    }
    
    func testReplacePackageNameWithMalformedYAML() throws {
        let mockRunner = MockCommandRunner()
        let parser = try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner)
        
        // Create the directory structure manually since mock apktool didn't
        try FileManager.default.createDirectory(at: parser.appDirectory, withIntermediateDirectories: true)
        
        // Write malformed YAML (truly invalid syntax)
        let malformedContent = "invalid: [ unclosed sequence"
        try malformedContent.write(to: parser.apktoolYamlURL, atomically: true, encoding: .utf8)
        
        // Create valid Manifest so that part passes
        let manifestContent = "<manifest package=\"com.old\"></manifest>"
        try manifestContent.write(to: parser.androidManifestURL, atomically: true, encoding: .utf8)
        
        // Attempt replace
        parser.replace(packageName: "com.new")
        
        // Verify manifest was updated (first part of operation)
        let newManifest = try String(contentsOf: parser.androidManifestURL)
        XCTAssertTrue(newManifest.contains("com.new"))
        
        // Verify YAML content is unchanged (because parsing failed)
        let yamlContent = try String(contentsOf: parser.apktoolYamlURL)
        XCTAssertEqual(yamlContent, malformedContent)
    }
}
