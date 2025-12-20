import XCTest
@testable import APKParser

final class ManifestBuilderTests: XCTestCase {
    
    var tempFileURL: URL!
    
    override func setUp() {
        super.setUp()
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xml")
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }
    
    private func createXMLFile(content: String) throws {
        try content.write(to: tempFileURL, atomically: true, encoding: .utf8)
    }
    
    func testReplacePackageName() throws {
        let xmlContent = """
        <manifest package="com.old.app" xmlns:android="http://schemas.android.com/apk/res/android">
            <application android:name="com.old.app.Application">
                <activity android:name="com.old.app.MainActivity" />
                <provider android:authorities="com.old.app.provider" />
            </application>
        </manifest>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try ManifestBuilder(tempFileURL)
        _ = builder.replace(packageName: "com.new.app")
        
        let root = builder.xml.rootElement()
        XCTAssertEqual(root?.attribute(forName: "package")?.stringValue, "com.new.app")
        
        let app = root?.elements(forName: "application").first
        XCTAssertEqual(app?.attribute(forName: "android:name")?.stringValue, "com.new.app.Application")
        
        let activity = app?.elements(forName: "activity").first
        XCTAssertEqual(activity?.attribute(forName: "android:name")?.stringValue, "com.new.app.MainActivity")
        
        let provider = app?.elements(forName: "provider").first
        XCTAssertEqual(provider?.attribute(forName: "android:authorities")?.stringValue, "com.new.app.provider")
    }
    
    func testReplacePackageNameWithPartialMatches() throws {
        // Ensures that it doesn't replace substrings incorrectly if not intended,
        // but the current implementation essentially does a string replace of the old package string.
        // Let's verify that behavior.
        
        let xmlContent = """
        <manifest package="com.old" xmlns:android="http://schemas.android.com/apk/res/android">
            <application android:name="com.old.ui.MyActivity" />
        </manifest>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try ManifestBuilder(tempFileURL)
        _ = builder.replace(packageName: "com.new")
        
        let app = builder.xml.rootElement()?.elements(forName: "application").first
        XCTAssertEqual(app?.attribute(forName: "android:name")?.stringValue, "com.new.ui.MyActivity")
    }
    
    func testReplaceApplicationMetaData() throws {
        let xmlContent = """
        <manifest package="com.example" xmlns:android="http://schemas.android.com/apk/res/android">
            <application>
                <meta-data android:name="com.google.android.gms.version" android:value="@integer/google_play_services_version" />
                <meta-data android:name="API_KEY" android:value="OLD_KEY" />
            </application>
        </manifest>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try ManifestBuilder(tempFileURL)
        _ = builder.replaceApplicationMetaData(name: "API_KEY", value: "NEW_KEY")
        
        // Helper to find the element
        let app = builder.xml.rootElement()?.elements(forName: "application").first
        let metas = app?.elements(forName: "meta-data") ?? []
        let apiKeyMeta = metas.first { $0.attribute(forName: "android:name")?.stringValue == "API_KEY" }
        
        XCTAssertEqual(apiKeyMeta?.attribute(forName: "android:value")?.stringValue, "NEW_KEY")
        
        // Verify other meta-data is untouched
        let gmsMeta = metas.first { $0.attribute(forName: "android:name")?.stringValue == "com.google.android.gms.version" }
        XCTAssertEqual(gmsMeta?.attribute(forName: "android:value")?.stringValue, "@integer/google_play_services_version")
    }
    
    func testIconNameExtraction() throws {
        let xmlContent = """
        <manifest package="com.example" xmlns:android="http://schemas.android.com/apk/res/android">
            <application android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher_round">
            </application>
        </manifest>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try ManifestBuilder(tempFileURL)
        
        XCTAssertEqual(builder.iconName, "ic_launcher.png")
        XCTAssertEqual(builder.iconRoundName, "ic_launcher_round.png")
    }
    
    func testIconNameExtractionFailure() throws {
        let xmlContent = """
        <manifest package="com.example">
            <application>
            </application>
        </manifest>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try ManifestBuilder(tempFileURL)
        
        XCTAssertNil(builder.iconName)
        XCTAssertNil(builder.iconRoundName)
    }

    func testReplacePackageNameWithNil() throws {
        let xmlContent = """
        <manifest package="com.old.app">
        </manifest>
        """
        try createXMLFile(content: xmlContent)
        
        let builder = try ManifestBuilder(tempFileURL)
        _ = builder.replace(packageName: nil)
        
        XCTAssertEqual(builder.xml.rootElement()?.attribute(forName: "package")?.stringValue, "com.old.app")
    }
}
