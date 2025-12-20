import XCTest
@testable import APKParser

final class CGSizeOperatorTests: XCTestCase {
    
    func testMultiplication() {
        let size = CGSize(width: 100, height: 200)
        let multiplier: Double = 2.5
        
        let result = size * multiplier
        
        XCTAssertEqual(result.width, 250)
        XCTAssertEqual(result.height, 500)
    }
    
    func testMultiplicationZero() {
        let size = CGSize(width: 100, height: 200)
        let result = size * 0
        
        XCTAssertEqual(result.width, 0)
        XCTAssertEqual(result.height, 0)
    }
}
