import XCTest
@testable import APKParser
@testable import Command

class MockCommandRunner: CommandRunner {
    var commands: [(command: String, arguments: [String], environment: [String: String]?)] = []
    var resultString: String = ""
    var errorToThrow: Error?
    var onRun: ((String, [String]) -> Void)?
    
    func run(_ command: String, arguments: [String], environment: [String: String]?) throws -> String {
        commands.append((command, arguments, environment))
        onRun?(command, arguments)
        if let error = errorToThrow {
            throw error
        }
        return resultString
    }
}

final class APKParserTests: XCTestCase {
    
    var tempAPKURL: URL!
    
    override func setUp() {
        super.setUp()
        tempAPKURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".apk")
        _ = FileManager.default.createFile(atPath: tempAPKURL.path, contents: Data(), attributes: nil)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempAPKURL)
        super.tearDown()
    }
    
    func testInitDecodesAPK() throws {
        let mockRunner = MockCommandRunner()
        let parser = try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner)
        
        XCTAssertEqual(mockRunner.commands.count, 1)
        let command = mockRunner.commands.first
        XCTAssertEqual(command?.command, "apktool")
        XCTAssertEqual(command?.arguments.first, "d")
        XCTAssertEqual(command?.arguments.contains(parser.appDirectory.path), true)
    }
    
    func testBuildEncodesAPK() throws {
        let mockRunner = MockCommandRunner()
        let parser = try APKParser(apkURL: tempAPKURL, commandRunner: mockRunner)
        
        // Clear init command
        mockRunner.commands.removeAll()
        
        // Mock apktool building the file so the subsequent moveItem works
        mockRunner.onRun = { command, args in
            if command == "apktool", args.first == "b" {
                if let outputIndex = args.firstIndex(of: "-o"), outputIndex + 1 < args.count {
                    let outputPath = args[outputIndex + 1]
                    let outputURL = URL(fileURLWithPath: outputPath)
                    // Ensure parent directory exists and create dummy file
                    try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    FileManager.default.createFile(atPath: outputPath, contents: Data(), attributes: nil)
                }
            }
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.apk")
        try parser.build(toPath: outputURL)
        
        // Verify that 2 commands were run in sequence
        XCTAssertEqual(mockRunner.commands.count, 2)
        
        // 1. Verify apktool command
        let buildCommand = mockRunner.commands[0]
        XCTAssertEqual(buildCommand.command, "apktool")
        XCTAssertEqual(buildCommand.arguments.first, "b")
        XCTAssertTrue(buildCommand.arguments.contains(parser.appDirectory.path))
        
        // 2. Verify zipinfo command
        let verifyCommand = mockRunner.commands[1]
        XCTAssertEqual(verifyCommand.command, "zipinfo")
        XCTAssertEqual(verifyCommand.arguments.first, "-t")
        
        // Verify final file was "moved" to destination
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: outputURL)
    }
    
    func testInitFailsIfAPKNotFound() {
        let mockRunner = MockCommandRunner()
        let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent("missing.apk")
        
        XCTAssertThrowsError(try APKParser(apkURL: missingURL, commandRunner: mockRunner)) { error in
            if let apkError = error as? APKParserError {
                switch apkError {
                case .templateAPKNotFound:
                    XCTAssertTrue(true)
                default:
                    XCTFail("Wrong error type")
                }
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
}
