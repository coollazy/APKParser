import XCTest
@testable import APKParser

final class StringsBuilderTests: XCTestCase {
    
    var tempFileURL: URL!
    
    override func setUp() {
        super.setUp()
        // Create a temporary file for each test
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xml")
    }
    
    override func tearDown() {
        // Clean up
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }
    
    private func createXMLFile(content: String) throws {
        try content.write(to: tempFileURL, atomically: true, encoding: .utf8)
    }
    
    func testReplaceExistingString() throws {
        let xmlContent = """
        <resources>
            <string name="app_name">My App</string>
            <string name="other_string">Other</string>
        </resources>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try StringsBuilder(tempFileURL)
        _ = builder.replace(name: "app_name", value: "New App Name")
        
        let nodes = try builder.xml.nodes(forXPath: "//string[@name='app_name']")
        XCTAssertEqual(nodes.first?.stringValue, "New App Name")
        
        // Ensure other nodes are untouched
        let otherNodes = try builder.xml.nodes(forXPath: "//string[@name='other_string']")
        XCTAssertEqual(otherNodes.first?.stringValue, "Other")
    }
    
    func testReplaceNonExistentString() throws {
        let xmlContent = """
        <resources>
            <string name="app_name">My App</string>
        </resources>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try StringsBuilder(tempFileURL)
        _ = builder.replace(name: "missing_key", value: "Should Not Exist")
        
        // Verify nothing was added or changed
        let nodes = try builder.xml.nodes(forXPath: "//string[@name='missing_key']")
        XCTAssertTrue(nodes.isEmpty)
        
        let appNameNodes = try builder.xml.nodes(forXPath: "//string[@name='app_name']")
        XCTAssertEqual(appNameNodes.first?.stringValue, "My App")
    }
    
    func testReplaceWithNilName() throws {
        let xmlContent = """
        <resources>
            <string name="app_name">My App</string>
        </resources>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try StringsBuilder(tempFileURL)
        _ = builder.replace(name: nil, value: "New Value")
        
        let nodes = try builder.xml.nodes(forXPath: "//string[@name='app_name']")
        XCTAssertEqual(nodes.first?.stringValue, "My App")
    }

    func testReplaceWithNilValue() throws {
         let xmlContent = """
        <resources>
            <string name="app_name">My App</string>
        </resources>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try StringsBuilder(tempFileURL)
        
        _ = builder.replace(name: "app_name", value: nil)
        
        let nodes = try builder.xml.nodes(forXPath: "//string[@name='app_name']")
        // If stringValue is set to nil, it typically removes the text content
        XCTAssertEqual(nodes.first?.stringValue, "")
    }
    
    func testBuildOutput() throws {
        let xmlContent = """
        <resources>
            <string name="app_name">My App</string>
        </resources>
        """
        try createXMLFile(content: xmlContent)
        let builder = try StringsBuilder(tempFileURL)
        _ = builder.replace(name: "app_name", value: "Built Name")
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_out.xml")
        try builder.build(to: outputURL)
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        let outputContent = try String(contentsOf: outputURL)
        XCTAssertTrue(outputContent.contains("Built Name"))
    }
    
    func testDisplayNameGetter() throws {
        let displayName = "Test App Name"
        let xmlContent = """
        <resources>
            <string name="app_name">\(displayName)</string>
            <string name="other_string">Other</string>
        </resources>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try StringsBuilder(tempFileURL)
        let retrievedDisplayName = builder.xml.rootElement()?.elements(forName: "string").first {
            $0.attribute(forName: "name")?.stringValue == "app_name"
        }?.stringValue
        
        XCTAssertEqual(retrievedDisplayName, displayName)
    }
}
