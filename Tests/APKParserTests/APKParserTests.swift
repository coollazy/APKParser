import XCTest
@testable import APKParser
@testable import Command

class MockCommandRunner: CommandRunner {
    var commands: [(command: String, arguments: [String], environment: [String: String]?)] = []
    var resultString: String = ""
    var errorToThrow: Error?
    
    func run(_ command: String, arguments: [String], environment: [String: String]?) throws -> String {
        commands.append((command, arguments, environment))
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
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.apk")
        try parser.build(toPath: outputURL)
        
        XCTAssertEqual(mockRunner.commands.count, 1)
        let command = mockRunner.commands.first
        XCTAssertEqual(command?.command, "apktool")
        XCTAssertEqual(command?.arguments.first, "b")
        XCTAssertEqual(command?.arguments.contains(parser.appDirectory.path), true)
        XCTAssertEqual(command?.arguments.contains(outputURL.path), true)
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
