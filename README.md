# sMock

## What is sMock?
- Swift mock-helping library written with gMock (C++) library approach in mind;
- uses XCTestExpectations inside, that makes sMock not only mocking library, but also library that allows easy unit-test coverage of mocked objects expected behavior;
- lightweight and zero-dependecy;
- works out-of-the-box without need of generators, tools, etc;
- required minimum of additional code to prepare mocks.

**Testing with sMock is simple!**
1. Create Mock class implementing protocol / subclassing / as callback closure;
2. Make expectations;
3. Execute test code;
4. Wait for expectations using sMock.waitForExpectations()

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
        sMock.waitForExpectations(timeout: 0.5)
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
        sMock.waitForExpectations(timeout: 0.5)
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
        sMock.waitForExpectations(timeout: 0.5)
    }
}
```

## Matchers

##### Use matchers with mock entity to make exact expectations.<br>*All matchers are the same for MockMethod, MockClosure and MockSetter.*

### Basic
Matcher | Description | Example
--- | --- | ---
.any | Matches any argument | .any
.custom( (Args) -> Bool ) | Use custom closure to match | .custom( { (args) in return true/false } )
<br>

### Predifined
```
let mock = MockMethod<Int, Void>()
mock.expect("Method called.").match(<matchers go here>)...
```

##### Miscellaneous
Matcher | Description | Example
--- | --- | ---
.keyPath<Root, Value> <br> .keyPath<Root, Value: Equatable> | Applies matcher to actual value by keyPath | // Number of bits in Int <br> .keyPath(\\.bitWidth, .equal(64)) <br> .keyPath(\\.bitWidth, 64)
.optional | Allows to pass matcher of Optional type.<br>nil matches as false | let value: Int? = ...<br>.optional(.equal(value))
.splitArgs<T...> | Allows to apply matchers to each actual value separately | // let mock = MockMethod<(Int, String), Void>()<br>.splitArgs(.any, .equal("str"))
.isNil<T> where Args == Optional<T> <br> .notNil<T> where Args == Optional<T> | Checks if actual value is nil/not nil | // let mock = MockMethod<String?, Void>() <br> .isNil() / .isNotNil()
.cast<T> | Casts actual value to T and uses matcher for T | // let mock = MockMethod<URLResponse, Void()<br>.cast(.keyPath(\HTTPURLResponse.statusCode, 200)) <br> .cast(to: HTTPURLResponse.self, .keyPath(\\.statusCode, 200))

##### Args: Equatable
Matcher | Description | Example
--- | --- | ---
.equal | actual == value | .equal(10)
.notEqual | actual != value | .notEqual(20)
.inCollection<C: Collection> where Args == C.Element | Checks if item is in collection | .inCollection( [10, 20] )

##### Args: Comparable
Matcher | Description | Example
--- | --- | ---
.greaterEqual | actual >= value | .greaterEqual(10)
.greater | actual > value | .greaterEqual(10)
.lessEqual | actual <= value | .greaterEqual(10)
.less | actual < value | .greaterEqual(10)

##### Args == Bool
Matcher | Description | Example
--- | --- | ---
.isTrue | actual == true | .isTrue()
.isFalse | actual == false | .isFalse()

##### Args == String
Matcher | Description | Example
--- | --- | ---
.strCaseEqual | actual == value (case insensitive) | .strCaseEqual("sTrInG")
.strCaseNotEqual | actual != value (case insensitive) | .strCaseNotEqual("sTrInG")

##### Args: Collection
```
let mock = MockMethod<[Int], Void>()
mock.expect("Method called.").match(<matchers go here>)...
```

Matcher | Description | Example
--- | --- | ---
.isEmpty | Checks if collection is empty | .isEmpty()
.sizeIs | Checks that size of collection equals value | .sizeIs(10)
.each | Requires each element of collection to be matched | .each(.greater(10))
.atLeastOne | Required at least on element of collection to be matched | .atLeastOne(.equal(10))

##### Args: Collection, Args.Element: Equatable
Matcher | Description | Example
--- | --- | ---
.contains | Checks if actual collection contains element | .contains(10)
.containsAllOf<C: Collection> | Checks if actual collection contains all items from subset | .containsAllOf( [10, 20] )
.containsAnyOf<C: Collection> | Checks if actual collection contains any item from subset | .containsAnyOf( [10, 20] )
.startsWith<C: Collection> | Checks if actual collection is prefixed by subset | .startsWith( [10, 20] )
.endsWith<C: Collection> | Checks if actual collection is suffixed by subset | .endsWith( [10, 20] )

## Actions

##### Actions are used to determine mocked entity behavior if call was matched.<br>*All actions are the same for MockMethod, MockClosure and MockSetter.*

### Types
Action | Description | Example
--- | --- | ---
WillOnce | Expect call should be made once and only once | .WillOnce()
WillRepeatedly | Expect call should be made some number of times (or unlimited) | .WillRepeatedly(.count(10))
WillNever | Expect call should be never made | .WillNever()

### Actions
Action | Description | Example
--- | --- | ---
.return(R) | Call to mocked entity will return exact value | .return(10)
.throw(Error) | Call to mocked entity will throw error | .throw(RuntimeError("Something happened.))
.perform( (Args) throws -> R ) | Call to mocked entity will perform custom action | .perform( { (args) in return ... } )

### Capturing arguments
Proper argument capturing expected to be made using ArgumentCaptor.

```
let mock = MockMethod<Int, Void>()

let captor = ArgumentCaptor<Int>()
mock.expect("Method called.").match(.any).capture(captor).willOnce()
print(captor.captured) // All captured values or empty is nothing captured.

let initedCaptor = InitedArgumentCaptor<Int>(-1)
mock.expect("Method called.").match(.any).capture(initedCaptor).willOnce()
print(initedCaptor.lastCaptured) // Last captured value or default value if nothing captured.
```

## sMock configuration
sMock support custom configuration

Property | Description | Values
--- | --- | ---
unexpectedCallBehavior | Determines what will sMock do when unexpected call is made | **.warning**: just print message to console <br> **.failTest**: XCTFail is triggerred <br> **.custom**((_ mockedEntity: String) -> Void): custom function is called <br><br> Default value: .failTest
waitTimeout: TimeInterval | Default timeout used in 'waitForExpectations' function | Timeout in seconds <br><br> Default value: 0.5

## Work to be done
- [ ] cover mocking code itself with tests
- [ ] cover matchers with tests
- [x] add support of throwing methods and functions
