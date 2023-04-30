import sMock
import XCTest

class MatcherTests: XCTestCase {
    func test_allOf() {
        let mTrue = Matcher<Int> { _ in true }
        let mFalse = Matcher<Int> { _ in false }
        
        XCTAssertTrue(Matcher<Int>.allOf(mTrue)(10))
        XCTAssertFalse(Matcher<Int>.allOf(mFalse)(10))
        
        XCTAssertTrue(Matcher<Int>.allOf(mTrue, mTrue)(10))
        XCTAssertFalse(Matcher<Int>.allOf(mTrue, mFalse)(10))
        XCTAssertFalse(Matcher<Int>.allOf(mFalse, mFalse)(10))
    }
    
    func test_anyOf() {
        let mTrue = Matcher<Int> { _ in true }
        let mFalse = Matcher<Int> { _ in false }
        
        XCTAssertTrue(Matcher<Int>.anyOf(mTrue)(10))
        XCTAssertFalse(Matcher<Int>.anyOf(mFalse)(10))
        
        XCTAssertTrue(Matcher<Int>.anyOf(mTrue, mTrue)(10))
        XCTAssertTrue(Matcher<Int>.anyOf(mTrue, mFalse)(10))
        XCTAssertFalse(Matcher<Int>.anyOf(mFalse, mFalse)(10))
        
        sMock.waitForExpectations()
    }
}
