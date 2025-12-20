import XCTest
@testable import APKParser
#if canImport(FoundationXML)
import FoundationXML
#endif

final class ComponentIntegrationTests: XCTestCase {
    
    var tempManifestURL: URL!
    var tempStringsURL: URL!
    var tempYAMLURL: URL!
    var tempAppDir: URL!
    var tempResDir: URL!
    
    override func setUp() {
        super.setUp()
        // Create a fake app directory structure
        tempAppDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempAppDir, withIntermediateDirectories: true)
        
        tempResDir = tempAppDir.appendingPathComponent("res")
        let valuesDir = tempResDir.appendingPathComponent("values")
        try? FileManager.default.createDirectory(at: valuesDir, withIntermediateDirectories: true)
        
        
        tempManifestURL = tempAppDir.appendingPathComponent("AndroidManifest.xml")
        tempYAMLURL = tempAppDir.appendingPathComponent("apktool.yml")
        tempStringsURL = valuesDir.appendingPathComponent("strings.xml")
        
        // Create dummy files (ensure strings.xml always exists for builder initialization)
        createDummyYAML()
        try? "<resources></resources>".write(to: tempStringsURL, atomically: true, encoding: .utf8)
    }
    
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempAppDir)
        super.tearDown()
    }
    
    private func createDummyYAML() {
        let content = """
        packageInfo:
          renameManifestPackage: null
        versionInfo:
          versionCode: '1'
          versionName: 1.0.0
        """
        try? content.write(to: tempYAMLURL, atomically: true, encoding: .utf8)
    }
    
    // MARK: - GoogleComponent Tests
    
    func testGoogleComponent() throws {
        // Setup XML
        let manifestContent = """
        <manifest package="com.example.test" xmlns:android="http://schemas.android.com/apk/res/android">
            <application>
                <meta-data android:name="com.google.android.geo.API_KEY" android:value="OLD_API_KEY" />
            </application>
        </manifest>
        """
        try manifestContent.write(to: tempManifestURL, atomically: true, encoding: .utf8)
        
        let stringsContent = """
        <resources>
            <string name="google_app_id">OLD_APP_ID</string>
            <string name="default_web_client_id">OLD_CLIENT_ID</string>
            <string name="google_server_client_id_web">OLD_WEB_ID</string>
        </resources>
        """
        try stringsContent.write(to: tempStringsURL, atomically: true, encoding: .utf8)
        
        // Apply Component
        let manifestBuilder = try ManifestBuilder(tempManifestURL)
        let yamlBuilder = try YAMLBuilder(tempYAMLURL)
        let stringsBuilder = try StringsBuilder(tempStringsURL)
        let context = APKContext(
            manifestBuilder: manifestBuilder,
            yamlBuilder: yamlBuilder,
            stringsBuilder: stringsBuilder,
            appDirectory: tempAppDir,
            resDirectory: tempResDir
        )
        
        let googleComponent = GoogleComponent(apiKey: "NEW_API_KEY", appID: "NEW_APP_ID")
        try googleComponent.apply(context)
        
        try manifestBuilder.build(to: tempManifestURL)
        try stringsBuilder.build(to: tempStringsURL)
        
        // Verify Manifest
        let newManifest = try ManifestBuilder(tempManifestURL)
        let meta = newManifest.xml.rootElement()?.elements(forName: "application").first?.elements(forName: "meta-data").first
        XCTAssertEqual(meta?.attribute(forName: "android:value")?.stringValue, "NEW_API_KEY")
        
        // Verify Strings
        let newStrings = try StringsBuilder(tempStringsURL)
        func getString(_ name: String) -> String? {
            return newStrings.xml.rootElement()?.elements(forName: "string").first { $0.attribute(forName: "name")?.stringValue == name }?.stringValue
        }
        XCTAssertEqual(getString("google_app_id"), "NEW_APP_ID")
        XCTAssertEqual(getString("default_web_client_id"), "NEW_APP_ID")
        XCTAssertEqual(getString("google_server_client_id_web"), "NEW_APP_ID")
    }
    
    // MARK: - FacebookComponent Tests
    
    func testFacebookComponent() throws {
        // Setup XML
        // Note: Facebook App ID in meta-data might be hardcoded or a reference. We test replacement of a hardcoded value.
        let manifestContent = """
        <manifest package="com.example.test" xmlns:android="http://schemas.android.com/apk/res/android">
            <application>
                <meta-data android:name="com.facebook.sdk.ApplicationId" android:value="OLD_FB_ID" />
                <meta-data android:name="com.facebook.sdk.ClientToken" android:value="OLD_TOKEN" />
            </application>
        </manifest>
        """
        try manifestContent.write(to: tempManifestURL, atomically: true, encoding: .utf8)
        
        let stringsContent = """
        <resources>
            <string name="facebook_app_id">OLD_FB_ID</string>
            <string name="facebook_client_token">OLD_TOKEN</string>
            <string name="facebook_app_name">Old FB App</string>
        </resources>
        """
        try stringsContent.write(to: tempStringsURL, atomically: true, encoding: .utf8)
        
        // Apply Component
        let manifestBuilder = try ManifestBuilder(tempManifestURL)
        let yamlBuilder = try YAMLBuilder(tempYAMLURL)
        let stringsBuilder = try StringsBuilder(tempStringsURL)
        let context = APKContext(
            manifestBuilder: manifestBuilder,
            yamlBuilder: yamlBuilder,
            stringsBuilder: stringsBuilder,
            appDirectory: tempAppDir,
            resDirectory: tempResDir
        )
        
        let fbComponent = FacebookComponent(appID: "NEW_FB_ID", clientToken: "NEW_TOKEN", displayName: "New FB App")
        try fbComponent.apply(context)
        
        try manifestBuilder.build(to: tempManifestURL)
        try stringsBuilder.build(to: tempStringsURL)
        
        // Verify Manifest
        let newManifest = try ManifestBuilder(tempManifestURL)
        let app = newManifest.xml.rootElement()?.elements(forName: "application").first
        let metaAppID = app?.elements(forName: "meta-data").first { $0.attribute(forName: "android:name")?.stringValue == "com.facebook.sdk.ApplicationId" }
        let metaToken = app?.elements(forName: "meta-data").first { $0.attribute(forName: "android:name")?.stringValue == "com.facebook.sdk.ClientToken" }
        
        XCTAssertEqual(metaAppID?.attribute(forName: "android:value")?.stringValue, "NEW_FB_ID")
        XCTAssertEqual(metaToken?.attribute(forName: "android:value")?.stringValue, "NEW_TOKEN")
        
        // Verify Strings
        let newStrings = try StringsBuilder(tempStringsURL)
        func getString(_ name: String) -> String? {
            return newStrings.xml.rootElement()?.elements(forName: "string").first { $0.attribute(forName: "name")?.stringValue == name }?.stringValue
        }
        XCTAssertEqual(getString("facebook_app_id"), "NEW_FB_ID")
        XCTAssertEqual(getString("facebook_client_token"), "NEW_TOKEN")
        XCTAssertEqual(getString("facebook_app_name"), "New FB App")
    }
    
    // MARK: - LinkDeepComponent Tests
    
    func testLinkDeepComponent() throws {
        // Setup XML
        // Include placeholders to be replaced
        let manifestContent = """
        <manifest package="com.example.test" xmlns:android="http://schemas.android.com/apk/res/android">
            <application>
                <meta-data android:name="LINK_DEEP_APP_KEY" android:value="${LINK_DEEP_APP_KEY}" />
                <activity android:name=".MainActivity">
                    <intent-filter>
                        <action android:name="android.intent.action.VIEW" />
                        <category android:name="android.intent.category.DEFAULT" />
                        <category android:name="android.intent.category.BROWSABLE" />
                        <data android:scheme="${LINK_DEEP_APP_KEY}" />
                        <data android:scheme="${LINK_DEEP_GROUP_SCHEME}" />
                    </intent-filter>
                </activity>
            </application>
        </manifest>
        """
        try manifestContent.write(to: tempManifestURL, atomically: true, encoding: .utf8)
        
        // Apply Component
        let manifestBuilder = try ManifestBuilder(tempManifestURL)
        let yamlBuilder = try YAMLBuilder(tempYAMLURL)
        let stringsBuilder = try StringsBuilder(tempStringsURL) // Using existing one even if not modified
        try? "<resources></resources>".write(to: tempStringsURL, atomically: true, encoding: .utf8)
        
        let context = APKContext(
            manifestBuilder: manifestBuilder,
            yamlBuilder: yamlBuilder,
            stringsBuilder: stringsBuilder,
            appDirectory: tempAppDir,
            resDirectory: tempResDir
        )
        
        let linkDeepComponent = LinkDeepComponent(appKey: "my_new_app_key", groupScheme: "my_new_group_scheme")
        try linkDeepComponent.apply(context)
        
        try manifestBuilder.build(to: tempManifestURL)
        
        // Verify Manifest
        let newManifest = try ManifestBuilder(tempManifestURL)
        let app = newManifest.xml.rootElement()?.elements(forName: "application").first
        
        // Check Meta-data
        let meta = app?.elements(forName: "meta-data").first { $0.attribute(forName: "android:name")?.stringValue == "LINK_DEEP_APP_KEY" }
        XCTAssertEqual(meta?.attribute(forName: "android:value")?.stringValue, "my_new_app_key")
        
        // Check Schemes
        let intentFilter = app?.elements(forName: "activity").first?.elements(forName: "intent-filter").first
        let datas = intentFilter?.elements(forName: "data") ?? []
        
        // Find scheme matching the new key
        let scheme1 = datas.first { $0.attribute(forName: "android:scheme")?.stringValue == "my_new_app_key" }
        XCTAssertNotNil(scheme1)
        
        let scheme2 = datas.first { $0.attribute(forName: "android:scheme")?.stringValue == "my_new_group_scheme" }
        XCTAssertNotNil(scheme2)
        
        // Verify placeholders are gone
        let placeholder1 = datas.first { $0.attribute(forName: "android:scheme")?.stringValue == "${LINK_DEEP_APP_KEY}" }
        XCTAssertNil(placeholder1)
    }
}

