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

### Library family
You can also find Swift libraries for macOS / *OS development
- [SwiftConvenience](https://github.com/Alkenso/SwiftConvenience): Swift common extensions and utilities used in everyday development
- [sXPC](https://github.com/Alkenso/sXPC): Swift type-safe wrapper around NSXPCConnection and proxy object
- [sLaunchctl](https://github.com/Alkenso/sLaunchctl): Swift API to register and manage daemons and user-agents

## Examples
### Mocking synchronous method
```Swift
import XCTest
import sMock


//  Protocol to be mocked.
protocol HTTPClient {
    func sendRequestSync(_ request: String) -> String
}

//  Mock implementation.
class MockHTTPClient: HTTPClient {
    //  Define call's mock entity.
    let sendRequestSyncCall = MockMethod<String, String>()
    
    func sendRequestSync(_ request: String) -> String {
        //  1. Call mock entity with passed arguments.
        //  2. If method returns non-Void type, provide default value for 'Unexpected call' case.
        sendRequestSyncCall.call(request) ?? ""
    }
}

//  Some entity to be tested.
struct Client {
    let httpClient: HTTPClient
    
    func retrieveRecordsSync() -> [String] {
        let response = httpClient.sendRequestSync("{ action: 'retrieve_records' }")
        return response.split(separator: ";").map(String.init)
    }
}

class ExampleTests: XCTestCase {
    func test_Example() {
        let mock = MockHTTPClient()
        let client = Client(httpClient: mock)
        
        //  Here we expect that method 'sendRequestSync' will be called with 'request' argument equals to "{ action: 'retrieve_records' }".
        //  We expect that it will be called only once and return "r1;r2;r3" as 'response'.
        mock.sendRequestSyncCall
            //  Assign name for exact expectation (useful if expectation fails);
            .expect("Request sent.")
            //  This expectation will only be trigerred if argument passed as parameter equals to passed Matcher;
            .match("{ action: 'retrieve_records' }")
            //  Assume how many times this method with this arguments (defined in 'match') should be called.
            .willOnce(
                //  If method for this expectation called, it will return value we pass in .return(...) statement.
                .return("r1;r2;r3"))
        
        //  Client internally requests records using HTTPClient and then parse response.
        let records = client.retrieveRecordsSync()
        XCTAssertEqual(records, ["r1", "r2", "r3"])
    }
}
```

### Mocking synchronous method + mocking asynchonous callback
```Swift
//  Protocol to be mocked.
protocol HTTPClient {
    func sendRequestSync(_ request: String) -> String
}

//  Mock implementation.
class MockHTTPClient: HTTPClient {
    //  Define call's mock entity.
    let sendRequestSyncCall = MockMethod<String, String>()
    
    func sendRequestSync(_ request: String) -> String {
        //  1. Call mock entity with passed arguments.
        //  2. If method returns non-Void type, provide default value for 'Unexpected call' case.
        sendRequestSyncCall.call(request) ?? ""
    }
}

//  Some entity to be tested.
struct Client {
    let httpClient: HTTPClient
    
    func retrieveRecordsAsync(completion: @escaping ([String]) -> Void) {
        let response = httpClient.sendRequestSync("{ action: 'retrieve_records' }")
        completion(response.split(separator: ";").map(String.init))
    }
}

class ExampleTests: XCTestCase {
    func test_Example() {
        let mock = MockHTTPClient()
        let client = Client(httpClient: mock)
        
        //  Here we expect that method 'sendRequestSync' will be called with 'request' argument equals to "{ action: 'retrieve_records' }".
        //  We expect that it will be called only once and return "r1;r2;r3" as 'response'.
        mock.sendRequestSyncCall
            //  Assign name for exact expectation (useful if expectation fails);
            .expect("Request sent.")
            //  This expectation will only be trigerred if argument passed as parameter equals to passed Matcher;
            .match("{ action: 'retrieve_records' }")
            //  Assume how many times this method with this arguments (defined in 'match') should be called.
            .willOnce(
                //  If method for this expectation called, it will return value we pass in .return(...) statement.
                .return("r1;r2;r3"))
        
        //  Here we use 'MockClosure' mock entity to ensure that 'completion' handler is called.
        //  We expect it will be called only once and it's argument is ["r1", "r2", "r3"].
        let completionCall = MockClosure<[String], Void>()
        completionCall
            //  Assign name for exact expectation (useful if expectation fails);
            .expect("Records retrieved.")
            //  This expectation will only be trigerred if argument passed as parameter equals to passed Matcher;
            .match(["r1", "r2", "r3"])
            //  Assume how many times this method with this arguments (defined in 'match') should be called.
            .willOnce()
        
        //  Client internally requests records using HTTPClient and then parse response.
        //  Returns response in completion handler.
        client.retrieveRecordsAsync(completion: completionCall.asClosure())
        
        
        //  Don't forget to wait for potentially async operations.
        sMock.waitForExpectations()
    }
}
```

### Mocking asynchronous method + mocking asynchonous callback
```Swift
//  Protocol to be mocked.
protocol HTTPClient {
    func sendRequestAsync(_ request: String, reply: @escaping (String) -> Void)
}

//  Mock implementation.
class MockHTTPClient: HTTPClient {
    //  Define call's mock entity.
    let sendRequestAsyncCall = MockMethod<(String, (String) -> Void), Void>()
    
    func sendRequestAsync(_ request: String, reply: @escaping (String) -> Void) {
        //  Call mock entity with passed arguments.
        sendRequestAsyncCall.call(request, reply)
    }
}

//  Some entity to be tested.
struct Client {
    let httpClient: HTTPClient
    
    func retrieveRecordsAsync(completion: @escaping ([String]) -> Void) {
        httpClient.sendRequestAsync("{ action: 'retrieve_records' }") { (response) in
            completion(response.split(separator: ";").map(String.init))
        }
    }
}

class ExampleTests: XCTestCase {
    func test_Example() {
        let mock = MockHTTPClient()
        let client = Client(httpClient: mock)
        
        //  Here we expect that method 'sendRequestAsync' will be called with 'request' argument equals to "{ action: 'retrieve_records' }".
        //  We expect that it will be called only once and return "r1;r2;r3" as 'response'.
        mock.sendRequestAsyncCall
            //  Assign name for exact expectation (useful if expectation fails);
            .expect("Request sent.")
            //  This expectation will only be trigerred if argument passed as parameter equals to passed Matcher;
            .match(
                //  SplitArgs allows to apply different Matcher to each argument (splitting tuple);
                .splitArgs(
                    //  Matcher for first argument (here: request);
                    .equal("{ action: 'retrieve_records' }"),
                    //  Matcher for second argument (here: reply block);
                    .any))
            //  Assume how many times this method with this arguments (defined in 'match') should be called.
            .willOnce(
                //  If method for this expectation called, it will perform specific handler with all arguments of the call.
                //  (Here: when mached, it will call 'reply' closure with argument "r1;r2;r3").
                .perform({ (_, reply) in
                    reply("r1;r2;r3")
                }))
        
        //  Here we use 'MockClosure' mock entity to ensure that 'completion' handler is called.
        //  We expect it will be called only once and it's argument is ["r1", "r2", "r3"].
        let completionCall = MockClosure<[String], Void>()
        completionCall
            //  Assign name for exact expectation (useful if expectation fails);
            .expect("Records retrieved.")
            //  This expectation will only be trigerred if argument passed as parameter equals to passed Matcher;
            .match(["r1", "r2", "r3"])
            //  Assume how many times this method with this arguments (defined in 'match') should be called.
            .willOnce()
        
        //  Client internally requests records using HTTPClient and then parse response.
        //  Returns response in completion handler.
        client.retrieveRecordsAsync(completion: completionCall.asClosure())
        
        
        //  Don't forget to wait for potentially async operations.
        sMock.waitForExpectations()
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
        
        //  Set expectations for setter calls. We expect only value 'set'.
        //  Get may be called any number of times.
        mock.valueCall.expect("First value did set.").match(.less(10)).willOnce()
        mock.valueCall.expect("Second value did set.").match(.any).willOnce()
        mock.valueCall.expect("Third value did set.").match(.equal(1)).willOnce()
        
        mock.value = 4
        XCTAssertEqual(mock.value, 4)
        
        mock.value = 100500
        XCTAssertEqual(mock.value, 100500)
        
        mock.value = 1
        XCTAssertEqual(mock.value, 1)
        
        //  At the end of the test, if any expectation has not been trigerred, it will fail the test.
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

##### Args == Result
Matcher | Description | Example
--- | --- | ---
.success<Success, Failure> | If result is success, matches success value using MatcherType<Success>. False if Result.failure | // let mock = MockMethod<Result<Int, Error>, Void>()<br> .success(.equal(10))
.failure<Success, Failure> | If result is failure, matches error using MatcherType<Failure>. False if Result.success | .failure(.any)

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
