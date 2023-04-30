import sMock
import XCTest

class ClosureTests: XCTestCase {
    func test() {
        let c1 = MockClosure<Int, Void>("test").expect("call 1").match(10).willOnce().asClosure()
        c1(10)
        
        let c2: () -> Int = MockClosure<Void, Int>("test", returnOnFail: 0).expect("call 1").willOnce(.return(10)).asClosure()
        XCTAssertEqual(c2(), 10)
        
        sMock.waitForExpectations()
    }
    
    func test_chaining() {
        let c = MockClosure<Int, String>("test", returnOnFail: "")
            .expect("call 1").match(10).willOnce(.return("first"))
            .expect("call 2").match(20).willOnce(.return("second"))
        
        let closure: (Int) -> String = c.asClosure()
        XCTAssertEqual(closure(20), "second")
        XCTAssertEqual(closure(10), "first")
        
        sMock.waitForExpectations()
    }
}
