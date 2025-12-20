import XCTest
@testable import APKParser
#if canImport(FoundationXML)
import FoundationXML
#endif

// A mock component to test the architecture
struct MockPermissionComponent: APKComponent {
    let permission: String
    
    func apply(_ context: APKContext) throws {
        // Add a <uses-permission> tag to the manifest
        // Note: In a real scenario, ManifestBuilder might expose a cleaner API for this.
        // Here we use the raw XML API.
        
        let root = context.manifestBuilder.xml.rootElement()
        let element = XMLElement(name: "uses-permission")
        let attr = XMLNode.attribute(withName: "android:name", stringValue: permission) as! XMLNode
        element.addAttribute(attr)
        root?.addChild(element)
        
        // Also modify a string just to prove we can access multiple builders
        _ = context.stringsBuilder.replace(name: "app_name", value: "Component Modified App")
    }
}

final class ComponentTests: XCTestCase {
    
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
        
        // Create dummy files
        createDummyManifest()
        createDummyYAML()
        createDummyStrings()
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempAppDir)
        super.tearDown()
    }
    
    private func createDummyManifest() {
        let content = """
        <manifest package="com.example.test" xmlns:android="http://schemas.android.com/apk/res/android">
            <application></application>
        </manifest>
        """
        try? content.write(to: tempManifestURL, atomically: true, encoding: .utf8)
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
    
    private func createDummyStrings() {
        let content = """
        <resources>
            <string name="app_name">Original Name</string>
        </resources>
        """
        try? content.write(to: tempStringsURL, atomically: true, encoding: .utf8)
    }
    
    func testApplyComponent() throws {
        // Since we can't easily instantiate APKParser without a real APK (due to init logic),
        // we will manually simulate what APKParser.apply does.
        // This validates the Context and Component logic, but not the integration with APKParser itself.
        // However, APKParser.apply implementation is very straightforward (init builders -> create context -> run component -> save).
        
        // 1. Init Builders
        let manifestBuilder = try ManifestBuilder(tempManifestURL)
        let yamlBuilder = try YAMLBuilder(tempYAMLURL)
        let stringsBuilder = try StringsBuilder(tempStringsURL)
        
        // 2. Create Context
        let context = APKContext(
            manifestBuilder: manifestBuilder,
            yamlBuilder: yamlBuilder,
            stringsBuilder: stringsBuilder,
            appDirectory: tempAppDir,
            resDirectory: tempResDir
        )
        
        // 3. Apply Component
        let component = MockPermissionComponent(permission: "android.permission.INTERNET")
        try component.apply(context)
        
        // 4. Save
        try manifestBuilder.build(to: tempManifestURL)
        try stringsBuilder.build(to: tempStringsURL)
        
        // 5. Verify
        // Check Manifest
        let newManifest = try ManifestBuilder(tempManifestURL)
        let permissions = newManifest.xml.rootElement()?.elements(forName: "uses-permission") ?? []
        XCTAssertEqual(permissions.count, 1)
        XCTAssertEqual(permissions.first?.attribute(forName: "android:name")?.stringValue, "android.permission.INTERNET")
        
        // Check Strings
        let newStrings = try StringsBuilder(tempStringsURL)
        let appName = newStrings.xml.rootElement()?.elements(forName: "string").first?.stringValue
        XCTAssertEqual(appName, "Component Modified App")
    }
}
