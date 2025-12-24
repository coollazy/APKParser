import XCTest
@testable import APKParser
@testable import Command

final class APKParserDisplayNameTests: XCTestCase {
    var realAPKURL: URL!
    var tempOutputAPKURL: URL!
    var parser: APKParser!

    override func setUp() {
        super.setUp()
        realAPKURL = Bundle.module.url(forResource: "test", withExtension: "apk")
        XCTAssertNotNil(realAPKURL, "test.apk resource not found in test bundle.")
        tempOutputAPKURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_output.apk")
        
        // Initialize parser for each test to ensure a clean state
        parser = try? APKParser(apkURL: realAPKURL)
        XCTAssertNotNil(parser, "Failed to initialize APKParser for test.apk")
    }

    override func tearDown() {
        if let url = tempOutputAPKURL {
            try? FileManager.default.removeItem(at: url)
        }
        // Clean up parser's working directory
        try? FileManager.default.removeItem(at: parser.appDirectory.deletingLastPathComponent())
        parser = nil
        super.tearDown()
    }
    
    // Helper to get ManifestBuilder for current parser state
    private func getManifestBuilder() throws -> ManifestBuilder {
        return try ManifestBuilder(parser.androidManifestURL)
    }
    
    // Helper to get StringsBuilder for current parser state
    private func getStringsBuilder() throws -> StringsBuilder {
        return try StringsBuilder(parser.stringsURL)
    }

    // MARK: - displayName() Getter Tests

    func testDisplayNameGetterManifestReference() throws {
        // Assume test.apk's manifest uses @string/app_name (common case)
        // And strings.xml has app_name defined.
        let originalDisplayName = try XCTUnwrap(parser.displayName(), "Original displayName should not be nil")
        XCTAssertEqual(originalDisplayName, "EmptyApp") // Based on test.apk content
    }

    func testDisplayNameGetterManifestHardcoded() throws {
        // Temporarily modify manifest to have a hardcoded label
        let manifestBuilder = try getManifestBuilder()
        manifestBuilder.applicationLabel = "Hardcoded App Name"
        try manifestBuilder.build(to: parser.androidManifestURL)
        
        XCTAssertEqual(try parser.displayName(), "Hardcoded App Name")
    }

    func testDisplayNameGetterManifestReferenceMissingString() throws {
        // Temporarily modify manifest to reference a non-existent string
        let manifestBuilder = try getManifestBuilder()
        manifestBuilder.applicationLabel = "@string/non_existent_app_name"
        try manifestBuilder.build(to: parser.androidManifestURL)
        
        XCTAssertNil(try parser.displayName(), "Should return nil if string resource is missing")
    }
    
    func testDisplayNameGetterManifestNoLabel() throws {
        // Temporarily remove android:label from manifest
        let manifestBuilder = try getManifestBuilder()
        manifestBuilder.applicationLabel = nil
        try manifestBuilder.build(to: parser.androidManifestURL)
        
        XCTAssertNil(try parser.displayName(), "Should return nil if android:label is missing")
    }

    // MARK: - replace(displayName:) Setter Tests

    func testReplaceDisplayNameModifiesManifestReference() throws {
        // Original: android:label="@string/app_name"
        let newDisplayName = "Modified Empty App"
        parser.replace(displayName: newDisplayName)
        
        // Verify strings.xml was updated
        let stringsBuilder = try getStringsBuilder()
        let updatedAppName = stringsBuilder.xml.rootElement()?.elements(forName: "string").first {
            $0.attribute(forName: "name")?.stringValue == "app_name"
        }?.stringValue
        XCTAssertEqual(updatedAppName, newDisplayName, "strings.xml app_name should be updated")
        
        // Verify Manifest still points to @string/app_name
        let manifestBuilder = try getManifestBuilder()
        XCTAssertEqual(manifestBuilder.applicationLabel, "@string/app_name")
        
        // Verify getter reflects change
        XCTAssertEqual(try parser.displayName(), newDisplayName)
        
        // Build and verify
        try parser.build(toPath: tempOutputAPKURL)
        let modifiedParser = try APKParser(apkURL: tempOutputAPKURL)
        XCTAssertEqual(try modifiedParser.displayName(), newDisplayName)
    }

    func testReplaceDisplayNameModifiesHardcodedLabelInManifest() throws {
        // Set manifest to a hardcoded label first
        let manifestBuilder = try getManifestBuilder()
        manifestBuilder.applicationLabel = "Initial Hardcoded Name"
        try manifestBuilder.build(to: parser.androidManifestURL)
        
        let newDisplayName = "Updated Hardcoded Name"
        parser.replace(displayName: newDisplayName)
        
        // Verify Manifest was updated directly
        let updatedManifestBuilder = try getManifestBuilder()
        XCTAssertEqual(updatedManifestBuilder.applicationLabel, newDisplayName)
        
        // Verify strings.xml was NOT touched
        let stringsBuilder = try getStringsBuilder()
        let originalAppName = stringsBuilder.xml.rootElement()?.elements(forName: "string").first {
            $0.attribute(forName: "name")?.stringValue == "app_name"
        }?.stringValue
        XCTAssertEqual(originalAppName, "EmptyApp", "strings.xml should not be touched")
        
        // Verify getter reflects change
        XCTAssertEqual(try parser.displayName(), newDisplayName)
        
        // Build and verify
        try parser.build(toPath: tempOutputAPKURL)
        let modifiedParser = try APKParser(apkURL: tempOutputAPKURL)
        XCTAssertEqual(try modifiedParser.displayName(), newDisplayName)
    }

    func testReplaceDisplayNameAddsLabelIfMissing() throws {
        // Remove label from manifest initially
        let manifestBuilder = try getManifestBuilder()
        manifestBuilder.applicationLabel = nil
        try manifestBuilder.build(to: parser.androidManifestURL)
        
        XCTAssertNil(try parser.displayName(), "Label should be nil initially")
        
        let newDisplayName = "Added Name"
        parser.replace(displayName: newDisplayName)
        
        // Verify Manifest has the new hardcoded label
        let updatedManifestBuilder = try getManifestBuilder()
        XCTAssertEqual(updatedManifestBuilder.applicationLabel, newDisplayName)
        
        // Verify getter reflects change
        XCTAssertEqual(try parser.displayName(), newDisplayName)
        
        // Build and verify
        try parser.build(toPath: tempOutputAPKURL)
        let modifiedParser = try APKParser(apkURL: tempOutputAPKURL)
        XCTAssertEqual(try modifiedParser.displayName(), newDisplayName)
    }

    func testReplaceDisplayNameNoOpOnNilInput() throws {
        let originalDisplayName = try XCTUnwrap(parser.displayName())
        
        parser.replace(displayName: nil)
        
        // Verify nothing changed
        XCTAssertEqual(try parser.displayName(), originalDisplayName)
        // You could also verify file contents for deeper check
    }

    func testReplaceDisplayNameNoOpIfSameName() throws {
        let originalDisplayName = try XCTUnwrap(parser.displayName())
        
        parser.replace(displayName: originalDisplayName)
        
        // Verify nothing changed
        XCTAssertEqual(try parser.displayName(), originalDisplayName)
        // You could also verify file contents for deeper check
    }
}
