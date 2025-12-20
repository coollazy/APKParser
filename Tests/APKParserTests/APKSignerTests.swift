import XCTest
@testable import APKSigner
@testable import Command
@testable import APKParser // Import APKParser to access MockCommandRunner if public, otherwise redefine

// Since MockCommandRunner is internal to APKParserTests target (if defined there), 
// and APKSigner is a separate module, we might need to redefine it or make it public in a shared test support file.
// For simplicity in this CLI context, I will redefine a similar mock here or reuse if possible.
// Actually, they are in the same Test Target "APKParserTests", so they share the scope!
// But MockCommandRunner was defined inside APKParserTests.swift file at top level? 
// Yes, check previous file content. It was defined at top level.
// So it should be available if in the same target.

final class APKSignerTests: XCTestCase {
    
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
    
    func testVerifyAlign() throws {
        let mockRunner = MockCommandRunner()
        try APKSigner.verifyAlgin(from: tempAPKURL, commandRunner: mockRunner)
        
        XCTAssertEqual(mockRunner.commands.count, 1)
        XCTAssertEqual(mockRunner.commands.first?.command, "zipalign")
        XCTAssertEqual(mockRunner.commands.first?.arguments.contains("-c"), true)
    }
    
    func testVerifySignature() throws {
        let mockRunner = MockCommandRunner()
        try APKSigner.verifySignature(from: tempAPKURL, commandRunner: mockRunner)
        
        XCTAssertEqual(mockRunner.commands.count, 1)
        XCTAssertEqual(mockRunner.commands.first?.command, "apksigner")
        XCTAssertEqual(mockRunner.commands.first?.arguments.contains("verify"), true)
    }
    
    // Note: Testing `signature` is harder because it has internal logic creating files and directories 
    // and expects them to exist (like "aligned.apk").
    // The current MockCommandRunner only mocks the execution, but doesn't create the artifacts 
    // that the `signature` method might check for (e.g. it moves `signedURL` to `toApkURL`).
    // `try FileManager.default.moveItem(at: signedURL, to: toApkURL)`
    // Since `apksigner` command is mocked, it won't create `signedURL`.
    // So `moveItem` will fail.
    // 
    // To test `signature` fully, the mock runner needs to simulate the side effects (creating files)
    // or we need to intercept file system calls too (which is overkill).
    // 
    // We can skip testing `signature` fully or try to create the expected file in a custom MockRunner.
    
    func testSignatureFlow() throws {
        let mockRunner = SideEffectCommandRunner() // Custom runner
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("signed_output.apk")
        
        // We need to ensure that when `zipalign` and `apksigner` are "run", 
        // they produce the expected output files so the subsequent code doesn't crash on file moves.
        
        try APKSigner.signature(from: tempAPKURL, to: outputURL, commandRunner: mockRunner)
        
        XCTAssertEqual(mockRunner.commands.count, 2)
        XCTAssertEqual(mockRunner.commands[0].command, "zipalign")
        XCTAssertEqual(mockRunner.commands[1].command, "apksigner")
    }
}

class SideEffectCommandRunner: CommandRunner {
    var commands: [(command: String, arguments: [String], environment: [String: String]?)] = []
    
    func run(_ command: String, arguments: [String], environment: [String: String]?) throws -> String {
        commands.append((command, arguments, environment))
        
        // Simulate side effects
        if command == "zipalign" {
            // Last argument is usually output path in the code: `alignedURL.path`
            if let outputPath = arguments.last {
                FileManager.default.createFile(atPath: outputPath, contents: Data(), attributes: nil)
            }
        }
        
        if command == "apksigner" {
            // arguments: ..., "--out", signedURL.path, alignedURL.path
            if let outIndex = arguments.firstIndex(of: "--out"), outIndex + 1 < arguments.count {
                let outputPath = arguments[outIndex + 1]
                 FileManager.default.createFile(atPath: outputPath, contents: Data(), attributes: nil)
            }
        }
        
        return "Success"
    }
}
