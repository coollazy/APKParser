//
//  APKParserIntegrationTests.swift
//  
//
//  Created by Gemini on 2025/12/23.
//

import XCTest
@testable import APKParser
@testable import Command // 如果集成测试中也需要 Command 模块
@testable import APKSigner // Import APKSigner for integration tests

final class APKParserIntegrationTests: XCTestCase {
    var realAPKURL: URL!
    var tempOutputAPKURL: URL! // 用于保存修改后生成的临时APK文件

    override func setUp() {
        super.setUp()
        // Dynamically locate test.apk from test bundle resources
        realAPKURL = Bundle.module.url(forResource: "test", withExtension: "apk")
        XCTAssertNotNil(realAPKURL, "test.apk resource not found in test bundle. Ensure it's in Tests/APKParserTests/Resources/ and declared in Package.swift.")
        
        if let url = realAPKURL {
             XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "test.apk file does not exist at path: \(url.path).")
        }

        // Initialize tempOutputAPKURL to ensure it's not nil, will be set in actual test
        tempOutputAPKURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_output.apk")
    }

    override func tearDown() {
        // Clean up the temporarily built APK if it was created
        if let url = tempOutputAPKURL {
            try? FileManager.default.removeItem(at: url)
        }
        // Note: APKParser instance itself will clean its appDirectory upon deinitialization
        super.tearDown()
    }

    func testParseAndBuildRealAPK() throws {
        // 1. 解析原始 test.apk
        let parser = try APKParser(apkURL: realAPKURL)


        // 2. 验证原始属性 (从 test.apk 实际读取，不再使用硬编码的"示例断言")
        // 这些值将作为修改前的“已知状态”
        guard let originalPackageName = parser.packageName() else { XCTFail("Original packageName is nil"); return }
        guard let originalDisplayName = parser.displayName() else { XCTFail("Original displayName is nil"); return }
        guard let originalVersionCode = parser.versionCode() else { XCTFail("Original versionCode is nil"); return }
        guard let originalVersionName = parser.version() else { XCTFail("Original versionName is nil"); return } // 使用 .version() 方法

        // 打印原始值，方便调试和确认
        print("--- Original test.apk properties ---")
        print("Package Name: \(originalPackageName)")
        print("Display Name: \(originalDisplayName)")
        print("Version Code: \(originalVersionCode)")
        print("Version Name: \(originalVersionName)")
        print("------------------------------------")

        // 3. 定义新的修改值
        let newPackageName = "com.example.modified.myapp"
        let newDisplayName = "Modified App Test"

        // 確保修改值與原始值不同，這樣才能驗證修改成功
        XCTAssertNotEqual(originalPackageName, newPackageName, "New package name must be different from original.")
        XCTAssertNotEqual(originalDisplayName, newDisplayName, "New display name must be different from original.")
        
        // 4. 执行修改
        parser.replace(packageName: newPackageName)
        parser.replace(displayName: newDisplayName)

        // 4. 重新打包
        do {
            try parser.build(toPath: tempOutputAPKURL)
        } catch {
            print("--- APKTool Build Error ---")
            print("Error details: \(error)") // Print the whole error object
            print("Localized Description: \(error.localizedDescription)")
            // 如果是 NSError，可以尝试打印 userInfo
            if let nsError = error as? NSError {
                print("Error UserInfo: \(nsError.userInfo)")
            }
            XCTFail("APK build failed with detailed error above.")
            return // Prevent further execution if build fails
        }

        // 6. 验证新打包的 APK
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempOutputAPKURL.path), "Modified APK was not built.")
        let modifiedParser = try APKParser(apkURL: tempOutputAPKURL)

        XCTAssertEqual(modifiedParser.packageName(), newPackageName, "Modified package name mismatch.")
        XCTAssertEqual(modifiedParser.displayName(), newDisplayName, "Modified display name mismatch.")

        // 確保原始 parser 實例的狀態反映最新的修改
        XCTAssertEqual(parser.packageName(), newPackageName, "Parser's package name should reflect the last change.")
        XCTAssertEqual(parser.displayName(), newDisplayName, "Parser's display name should reflect the last change.")
    }

    func testModifyDisplayNameOnly() throws {
        let parser = try APKParser(apkURL: realAPKURL)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_display.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        parser.replace(displayName: "New Display Name")
        do {
            try parser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Modified Display Name APK was not built.")
        } catch {
            XCTFail("Build failed for DisplayName modification: \(error)")
        }
    }

    func testModifyPackageNameOnly() throws {
        let parser = try APKParser(apkURL: realAPKURL)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_pkg.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        parser.replace(packageName: "com.example.modified.pkg")
        do {
            try parser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Modified PackageName APK was not built.")
        } catch {
            XCTFail("Build failed for PackageName modification: \(error)")
        }
    }

    func testReplaceVersionInfo() throws {
        let parser = try APKParser(apkURL: realAPKURL)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_version.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let originalVersionCode = try XCTUnwrap(parser.versionCode())
        let originalVersionName = try XCTUnwrap(parser.version())

        let newVersionCode = "99"
        let newVersionName = "9.9.9"

        XCTAssertNotEqual(originalVersionCode, newVersionCode)
        XCTAssertNotEqual(originalVersionName, newVersionName)

        // Test replace with nil
        parser.replace(versionCode: nil)
        parser.replace(versionName: nil)
        XCTAssertEqual(parser.versionCode(), originalVersionCode, "Replace with nil should be no-op")
        XCTAssertEqual(parser.version(), originalVersionName, "Replace with nil should be no-op")

        // Perform actual replacement
        parser.replace(versionCode: newVersionCode)
        parser.replace(versionName: newVersionName)

        // Verify parser's internal state
        XCTAssertEqual(parser.versionCode(), newVersionCode)
        XCTAssertEqual(parser.version(), newVersionName)

        // Build and verify the new APK
        do {
            try parser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Version modification APK was not built.")

            let modifiedParser = try APKParser(apkURL: outputURL)
            XCTAssertEqual(modifiedParser.versionCode(), newVersionCode)
            XCTAssertEqual(modifiedParser.version(), newVersionName)

        } catch {
            print("--- APKTool Build Error ---")
            print("Error details: \(error)")
            if let nsError = error as? NSError {
                print("Error UserInfo: \(nsError.userInfo)")
            }
            XCTFail("Build failed for version modification: \(error)")
        }
    }


    func testNoModificationBuildRealAPK() throws {
        // 1. 解析原始 test.apk
        let parser = try APKParser(apkURL: realAPKURL)

        // 2. 獲取原始屬性
        let originalPackageName = try XCTUnwrap(parser.packageName(), "Original packageName is nil")
        let originalDisplayName = try XCTUnwrap(parser.displayName(), "Original displayName is nil")
        let originalVersionCode = try XCTUnwrap(parser.versionCode(), "Original versionCode is nil")
        let originalVersionName = try XCTUnwrap(parser.version(), "Original versionName is nil")

        // 3. 直接重新打包，不做任何修改
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_no_mod.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        do {
            try parser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "No modification APK was not built.")
        } catch {
            XCTFail("Build failed for no modification: \(error)")
            return
        }

        // 4. 解析新打包的 APK 並驗證屬性
        let modifiedParser = try APKParser(apkURL: outputURL)

        XCTAssertEqual(modifiedParser.packageName(), originalPackageName, "Package name should remain unchanged.")
        XCTAssertEqual(modifiedParser.displayName(), originalDisplayName, "Display name should remain unchanged.")
        XCTAssertEqual(modifiedParser.versionCode(), originalVersionCode, "Version code should remain unchanged.")
        XCTAssertEqual(modifiedParser.version(), originalVersionName, "Version name should remain unchanged.")
    }
    func testReplaceIconRealAPK() throws {
        // Assume these icon files exist in the test bundle for replacement
        let newIconURL = try XCTUnwrap(Bundle.module.url(forResource: "new_icon", withExtension: "png"), "new_icon.png resource not found.")
        
        let parser = try APKParser(apkURL: realAPKURL)
            .replace(iconURL: newIconURL)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_icon.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        do {
            try parser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Icon replacement APK was not built.")
        } catch {
            XCTFail("Build failed for icon replacement: \(error)")
        }
        
        // TODO: Deeper verification: Decompile outputURL and check the icon actual content/size.
    }

    func testReplaceRoundIconRealAPK() throws {
        // Assume these icon files exist in the test bundle for replacement
        let newRoundIconURL = try XCTUnwrap(Bundle.module.url(forResource: "new_icon_round", withExtension: "png"), "new_icon_round.png resource not found.")
        
        let parser = try APKParser(apkURL: realAPKURL)
            .replace(roundIconURL: newRoundIconURL)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_round_icon.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        do {
            try parser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Round icon replacement APK was not built.")
        } catch {
            XCTFail("Build failed for round icon replacement: \(error)")
        }
        
        // TODO: Deeper verification: Decompile outputURL and check the round icon actual content/size.
    }

    func testSignAndAlignRealAPK() throws {
        // 1. Build an unsigned APK first
        let parser = try APKParser(apkURL: realAPKURL)
        let unsignedApkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_unsigned.apk")
        defer { try? FileManager.default.removeItem(at: unsignedApkURL) }

        try parser.build(toPath: unsignedApkURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: unsignedApkURL.path), "Unsigned APK was not built.")

        // 2. Sign and Align the APK
        let signedApkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_signed.apk")
        defer { try? FileManager.default.removeItem(at: signedApkURL) }

        try APKSigner.signature(from: unsignedApkURL, to: signedApkURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: signedApkURL.path), "Signed APK was not created.")

        // 3. Verify Alignment and Signature
        try APKSigner.verifyAlgin(from: signedApkURL)
        try APKSigner.verifySignature(from: signedApkURL)
    }

    func testAllModificationsRealAPK() throws {
        // Assume these icon files exist in the test bundle for replacement
        let newIconURL = try XCTUnwrap(Bundle.module.url(forResource: "new_icon", withExtension: "png"), "new_icon.png resource not found.")
        let newRoundIconURL = try XCTUnwrap(Bundle.module.url(forResource: "new_icon_round", withExtension: "png"), "new_icon_round.png resource not found.")

        // 1. 解析原始 test.apk
        let parser = try APKParser(apkURL: realAPKURL)

        // 2. 定义新的修改值
        let newPackageName = "com.example.full.modified"
        let newDisplayName = "Full Modified App"
        
        // 3. 执行所有修改
        let modifiedParser = try parser
            .replace(packageName: newPackageName)
            .replace(displayName: newDisplayName)
            .replace(iconURL: newIconURL)
            .replace(roundIconURL: newRoundIconURL)

        // 4. 重新打包
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_all_mod.apk")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        do {
            try modifiedParser.build(toPath: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "All modifications APK was not built.")
        } catch {
            XCTFail("Build failed for all modifications: \(error)")
            return
        }

        // 5. 验证新打包的 APK
        let verifiedParser = try APKParser(apkURL: outputURL)

        XCTAssertEqual(verifiedParser.packageName(), newPackageName, "Modified package name mismatch.")
        // TODO: Deeper verification for icons if needed.
    }

    func testBuildWithInvalidPath() throws {
        let parser = try APKParser(apkURL: realAPKURL)
        
        // Try to build to a path that is genuinely invalid: /dev/null is a file, not a directory.
        let invalidPath = URL(fileURLWithPath: "/dev/null/output.apk")

        XCTAssertThrowsError(try parser.build(toPath: invalidPath)) { error in
            // Check for APKParserError or a more general error indicating failure
            XCTAssertTrue(error is APKParserError || (error as NSError).domain == "Command Error apktool", "Expected an error when building to an invalid path.")
        }
    }
}