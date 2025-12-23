import XCTest
@testable import APKParser
@testable import Command
@testable import APKSigner

class SideEffectMockRunner: MockCommandRunner {
    var sideEffect: ((String, [String]) -> Void)?
    
    override func run(_ command: String, arguments: [String], environment: [String : String]?) throws -> String {
        sideEffect?(command, arguments)
        return try super.run(command, arguments: arguments, environment: environment)
    }
}

final class APKSignerUnitTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testSignatureCommands() throws {
        let mockRunner = SideEffectMockRunner()
        mockRunner.sideEffect = { command, args in
            // Simulate apksigner producing the output file
            if command == "apksigner" {
                if let outIndex = args.firstIndex(of: "--out"), outIndex + 1 < args.count {
                    let outPath = args[outIndex + 1]
                    try? "dummy signed apk".write(to: URL(fileURLWithPath: outPath), atomically: true, encoding: .utf8)
                }
            }
        }
        
        let inputFile = tempDir.appendingPathComponent("input.apk")
        let outputFile = tempDir.appendingPathComponent("output.apk")
        
        // Create dummy input file
        try "dummy".write(to: inputFile, atomically: true, encoding: .utf8)
        
        try APKSigner.signature(from: inputFile, to: outputFile, commandRunner: mockRunner)
        
        // Expect 2 commands: zipalign and apksigner
        XCTAssertEqual(mockRunner.commands.count, 2)
        
        // 1. Verify zipalign
        let alignCommand = mockRunner.commands[0]
        XCTAssertEqual(alignCommand.command, "zipalign")
        XCTAssertTrue(alignCommand.arguments.contains("-v"))
        XCTAssertTrue(alignCommand.arguments.contains("-p"))
        XCTAssertTrue(alignCommand.arguments.contains("4"))
        
        // 2. Verify apksigner
        let signCommand = mockRunner.commands[1]
        XCTAssertEqual(signCommand.command, "apksigner")
        XCTAssertEqual(signCommand.arguments.first, "sign")
        XCTAssertTrue(signCommand.arguments.contains("--ks"))
        XCTAssertTrue(signCommand.arguments.contains("--out"))
        
        // Verify output file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
    }
    
    func testVerifyAlignCommand() throws {
        let mockRunner = MockCommandRunner()
        let inputFile = tempDir.appendingPathComponent("input.apk")
        
        try APKSigner.verifyAlgin(from: inputFile, commandRunner: mockRunner)
        
        XCTAssertEqual(mockRunner.commands.count, 1)
        let command = mockRunner.commands[0]
        XCTAssertEqual(command.command, "zipalign")
        XCTAssertTrue(command.arguments.contains("-c"))
        XCTAssertTrue(command.arguments.contains("4"))
        XCTAssertTrue(command.arguments.contains(inputFile.path))
    }

    func testVerifySignatureCommand() throws {
        let mockRunner = MockCommandRunner()
        let inputFile = tempDir.appendingPathComponent("input.apk")
        
        try APKSigner.verifySignature(from: inputFile, commandRunner: mockRunner)
        
        XCTAssertEqual(mockRunner.commands.count, 1)
        let command = mockRunner.commands[0]
        XCTAssertEqual(command.command, "apksigner")
        XCTAssertTrue(command.arguments.contains("verify"))
        XCTAssertTrue(command.arguments.contains("--print-certs"))
        XCTAssertTrue(command.arguments.contains(inputFile.path))
    }
    
    func testSignatureFailure() {
        let mockRunner = MockCommandRunner()
        mockRunner.errorToThrow = NSError(domain: "CommandError", code: 1, userInfo: nil)
        
        let inputFile = tempDir.appendingPathComponent("input.apk")
        let outputFile = tempDir.appendingPathComponent("output.apk")
        
        XCTAssertThrowsError(try APKSigner.signature(from: inputFile, to: outputFile, commandRunner: mockRunner))
    }
}
