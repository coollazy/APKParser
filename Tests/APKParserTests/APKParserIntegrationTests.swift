//
//  APKParserIntegrationTests.swift
//  
//
//  Created by Gemini on 2025/12/23.
//

import XCTest
@testable import APKParser
@testable import Command // 如果集成测试中也需要 Command 模块

final class APKParserIntegrationTests: XCTestCase {
    var realAPKURL: URL!
    var tempOutputAPKURL: URL! // 用于保存修改后生成的临时APK文件

    override func setUp() {
        super.setUp()
        // Dynamically locate test.apk from test bundle resources
        realAPKURL = Bundle.module.url(forResource: "test", withExtension: "apk")
        XCTAssertNotNil(realAPKURL, "test.apk resource not found in test bundle. Ensure it's in Tests/APKParserTests/Resources/ and declared in Package.swift.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: realAPKURL.path), "test.apk file does not exist at path: \(realAPKURL?.path ?? "nil")")

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
}