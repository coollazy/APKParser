import XCTest
import Command

final class CommandTests: XCTestCase {
    func testCommandCapture() throws {
        // Use a loop to produce enough output to likely trigger buffers if that matters,
        // but simple echo usually suffices to show if data is consumed.
        let output = try Command.run("echo", arguments: ["hello"])
        XCTAssertTrue(output.contains("hello"), "Output should contain 'hello', got: '\(output)'")
    }
    
    func testCommandErrorCapture() throws {
        // Test stderr capture
        // sh -c 'echo error >&2; exit 1'
        do {
            _ = try Command.run("sh", arguments: ["-c", "echo error >&2; exit 1"])
            XCTFail("Should have thrown error")
        } catch {
            let nsError = error as NSError
            let description = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
            XCTAssertTrue(description.contains("error"), "Error description should contain stderr 'error', got: '\(description)'")
        }
    }
}
