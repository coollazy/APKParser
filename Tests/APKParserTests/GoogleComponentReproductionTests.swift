import XCTest
@testable import APKParser
@testable import Command

final class GoogleComponentReproductionTests: XCTestCase {
    var realAPKURL: URL!
    var tempOutputAPKURL: URL!

    override func setUp() {
        super.setUp()
        // Locate test.apk from test bundle resources
        realAPKURL = Bundle.module.url(forResource: "test", withExtension: "apk")
        XCTAssertNotNil(realAPKURL, "test.apk resource not found in test bundle.")
        
        tempOutputAPKURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_output.apk")
    }

    override func tearDown() {
        if let url = tempOutputAPKURL {
            try? FileManager.default.removeItem(at: url)
        }
        super.tearDown()
    }

    func testApplyGoogleComponentAndBuild() throws {
        print("Starting testApplyGoogleComponentAndBuild...")
        guard let realAPKURL = realAPKURL else {
             XCTFail("Skipping test because test.apk is missing")
             return
        }
        
        // 1. Initialize Parser
        let parser = try APKParser(apkURL: realAPKURL)

        // 2. Apply GoogleComponent
        // Using arbitrary valid-looking values to simulate real usage
        let googleComponent = GoogleComponent(
            apiKey: "AIzaSyDummymKeyForTesting",
            appID: "1234567890" 
        )
        
        print("Applying GoogleComponent...")
        try parser.apply(googleComponent)
        
        // 3. Build
        print("Building APK with GoogleComponent applied...")
        do {
            try parser.build(toPath: tempOutputAPKURL)
            print("Build successful!")
            XCTAssertTrue(FileManager.default.fileExists(atPath: tempOutputAPKURL.path))
        } catch {
            print("Build FAILED with error: \(error)")
            let nsError = error as NSError
            print("Error info: \(nsError.userInfo)")
            XCTFail("Build failed when GoogleComponent is applied. See console output for details.")
        }
    }
}
