# sMock

## What is sMock?
- Swift mock-helping library written with gMock (C++) library approach in mind;
- has built-in integration with XCTest framework that makes it not only mocking library, but also library that allows easy unit-test coverage of mocked objects;
- lightweight and zero-dependecy;
- works out-of-the-box without need of generators, tools, etc;
- required minimum of additional code to prepare mocks.

## Example
### Mocking typical method:
```Swift
import XCTest
import sMock


protocol SomeProtocol {
    func toString(_ value: Int) -> String
}

class Mock: SomeProtocol {
    let toStringCall = MockMethod<Int, String>()
    
    
    func toString(_ value: Int) -> String {
        toStringCall.call(value) ?? ""
    }
}

class ExampleTests: XCTestCase {
    func test_Example() {
        let mock = Mock()
        
        mock.toStringCall.expect("'toString' called.").match(2).willOnce(.return("two"))
        XCTAssertEqual(mock.toString(2), "two")
        
        
        // Don't forget wait underlying expectations!
        waitForExpectations(timeout: 0.5)
    }
}
```

### Mocking asynchronous method + mocking callback
```Swift
protocol SomeProtocol {
    func toStringAsync(_ value: Int, reply: @escaping (String) -> Void)
}

class Mock: SomeProtocol {
    let toStringAsyncCall = MockMethod<(Int, (String) -> Void), Void>()
    
    
    func toStringAsync(_ value: Int, reply: @escaping (String) -> Void) {
        toStringAsyncCall.call((value, reply))
    }
}

class ExampleTests: XCTestCase {
    func test_Example() {
        let mock = Mock()
        
        let repeats = 10
        let mockCallback = MockClosure<String, Void>()
        mockCallback.expect("Reply block called.")
            .match("two") // Expect argument is always 'two'.
            .willRepeatedly(.count(repeats)) // Expect to be called 'repeats' times.
        
        mock.toStringAsyncCall.expect("'toStringAsync' called.")
            .match(.splitArgs(.equal(2), .any)) // Expect 0 argument will be '2' and second may be any.
            .willRepeatedly(.count(repeats), // Expect to be called 'repeats' times.
                            .perform({ $0.1("two") })) // AND each matched call will invoke reply block with argument 'two'.
        
        // As expected, invoke mock.foo 'repeats' times.
        for _ in 0..<repeats {
            mock.toStringAsync(2, reply: mockCallback.asClosure())
        }
        
        // Don't forget wait underlying expectations!
        waitForExpectations(timeout: 0.5)
    }
}
```

### Mocking property setter
```Swift
protocol SomeProtocol {
    var value: Int { get set }
}

class Mock: SomeProtocol {
    let valueCall = MockSetter<Int>("value", -1)
    
    
    var value: Int {
        get { valueCall.callGet() }
        set { valueCall.callSet(newValue) }
    }
}

class ExampleTests: XCTestCase {
    func test_Example() {
        let mock = Mock()
        
        XCTAssertEqual(mock.value, -1)
        
        mock.valueCall.expect("First value did set.").match(.less(10)).willOnce()
        mock.valueCall.expect("Second value did set.").match(.any).willOnce()
        mock.valueCall.expect("Third value did set.").match(.equal(1)).willOnce()
        
        mock.value = 4
        XCTAssertEqual(mock.value, 4)
        
        mock.value = 100500
        XCTAssertEqual(mock.value, 100500)
        
        mock.value = 1
        XCTAssertEqual(mock.value, 1)
        
        // Don't forget wait underlying expectations!
        waitForExpectations(timeout: 0.5)
    }
}
```

## Work to be done
- [ ] cover mocking code itself with tests
- [ ] cover matchers with tests
- [ ] add support of throwing methods and functions
