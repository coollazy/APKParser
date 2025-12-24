import XCTest
@testable import APKParser
@testable import Command
#if canImport(FoundationXML)
import FoundationXML
#endif

final class ComponentIntegrationTests: XCTestCase {
    
    // MARK: - Dummy Environment Properties
    var tempManifestURL: URL!
    var tempStringsURL: URL!
    var tempYAMLURL: URL!
    var tempAppDir: URL!
    var tempResDir: URL!
    var tempAssetsDir: URL!
    
    // MARK: - Real APK Properties
    var realAPKURL: URL!
    var tempOutputAPKURL: URL!

    override func setUp() {
        super.setUp()
        // 1. Setup Dummy Environment
        tempAppDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempAppDir, withIntermediateDirectories: true)
        
        tempResDir = tempAppDir.appendingPathComponent("res")
        let valuesDir = tempResDir.appendingPathComponent("values")
        try? FileManager.default.createDirectory(at: valuesDir, withIntermediateDirectories: true)
        
        tempAssetsDir = tempAppDir.appendingPathComponent("assets")
        try? FileManager.default.createDirectory(at: tempAssetsDir, withIntermediateDirectories: true)
        
        tempManifestURL = tempAppDir.appendingPathComponent("AndroidManifest.xml")
        tempYAMLURL = tempAppDir.appendingPathComponent("apktool.yml")
        tempStringsURL = valuesDir.appendingPathComponent("strings.xml")
        
        createDummyYAML()
        try? "<resources></resources>".write(to: tempStringsURL, atomically: true, encoding: .utf8)
        
        // 2. Setup Real APK Environment
        realAPKURL = Bundle.module.url(forResource: "test", withExtension: "apk")
        // Initialize tempOutputAPKURL to ensure it's not nil
        tempOutputAPKURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_output.apk")
    }
    
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempAppDir)
        if let url = tempOutputAPKURL {
            try? FileManager.default.removeItem(at: url)
        }
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
    
    // MARK: - Unit Tests (Dummy Files)
    
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
            resDirectory: tempResDir,
            assetsDirectory: tempAssetsDir
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
    
    func testFacebookComponent() throws {
        // Setup XML
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
            resDirectory: tempResDir,
            assetsDirectory: tempAssetsDir
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
    
    func testLinkDeepComponent() throws {
        // Setup XML
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
        let stringsBuilder = try StringsBuilder(tempStringsURL)
        
        let context = APKContext(
            manifestBuilder: manifestBuilder,
            yamlBuilder: yamlBuilder,
            stringsBuilder: stringsBuilder,
            appDirectory: tempAppDir,
            resDirectory: tempResDir,
            assetsDirectory: tempAssetsDir
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
        
        let scheme1 = datas.first { $0.attribute(forName: "android:scheme")?.stringValue == "my_new_app_key" }
        XCTAssertNotNil(scheme1)
        
        let scheme2 = datas.first { $0.attribute(forName: "android:scheme")?.stringValue == "my_new_group_scheme" }
        XCTAssertNotNil(scheme2)
        
        let placeholder1 = datas.first { $0.attribute(forName: "android:scheme")?.stringValue == "${LINK_DEEP_APP_KEY}" }
        XCTAssertNil(placeholder1)
    }
    
    // MARK: - Integration Tests (Real APK)
    
    func testGoogleComponentBuildRealAPK() throws {
        guard let realAPKURL = realAPKURL else {
             XCTFail("Skipping test because test.apk is missing")
             return
        }
        
        let parser = try APKParser(apkURL: realAPKURL)
        
        // Apply GoogleComponent
        let googleComponent = GoogleComponent(apiKey: "REAL_TEST_API_KEY", appID: "REAL_TEST_APP_ID")
        try parser.apply(googleComponent)
        
        // Build
        do {
            try parser.build(toPath: tempOutputAPKURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: tempOutputAPKURL.path))
        } catch {
            print("GoogleComponent Build Failed: \(error)")
            if let nsError = error as? NSError {
                 print("Error info: \(nsError.userInfo)")
            }
            XCTFail("Failed to build APK after applying GoogleComponent")
        }
    }
    
    func testFacebookComponentBuildRealAPK() throws {
        guard let realAPKURL = realAPKURL else {
             XCTFail("Skipping test because test.apk is missing")
             return
        }
        
        let parser = try APKParser(apkURL: realAPKURL)
        
        // Apply FacebookComponent
        let fbComponent = FacebookComponent(appID: "123456789", clientToken: "token_123", displayName: "My FB App")
        try parser.apply(fbComponent)
        
        // Build
        do {
            try parser.build(toPath: tempOutputAPKURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: tempOutputAPKURL.path))
        } catch {
            print("FacebookComponent Build Failed: \(error)")
            if let nsError = error as? NSError {
                 print("Error info: \(nsError.userInfo)")
            }
            XCTFail("Failed to build APK after applying FacebookComponent")
        }
    }
    
    func testLinkDeepComponentBuildRealAPK() throws {
        guard let realAPKURL = realAPKURL else {
             XCTFail("Skipping test because test.apk is missing")
             return
        }
        
        let parser = try APKParser(apkURL: realAPKURL)
        
        // Apply LinkDeepComponent
        // Note: For LinkDeepComponent to actually replace something, the placeholders must exist in the original manifest.
        // Even if they don't, ensuring the build succeeds verifies that the parsing/saving process is safe.
        let linkComponent = LinkDeepComponent(appKey: "my_deep_key", groupScheme: "my_group_scheme")
        try parser.apply(linkComponent)
        
        // Build
        do {
            try parser.build(toPath: tempOutputAPKURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: tempOutputAPKURL.path))
        } catch {
            print("LinkDeepComponent Build Failed: \(error)")
            if let nsError = error as? NSError {
                 print("Error info: \(nsError.userInfo)")
            }
            XCTFail("Failed to build APK after applying LinkDeepComponent")
        }
    }
}

