/*
 * MIT License
 *
 * Copyright (c) 2020 Alkenso (Vladimir Vashurkin)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import XCTest

/// sMock configuration.
public enum sMock {
    public enum UnexpectedCallBehavior {
        case warning
        case failTest
        case custom((_ mockedEntity: String) -> Void)
    }
    /// Handler will be called each time unexpected call on mock object is made.
    /// By default, in such cases sMock will trigger XCTFail.
    /// Change this handler in 'setUp' method either on each test case or in the very beginning of the individual test.
    public static var unexpectedCallBehavior: UnexpectedCallBehavior = .failTest
    
    /// Workaround when 'CurrentTestCaseProvider.currentTestCase' fails due to unknown reason.
    /// Set this variable before using any mock objects.
    /// Usually set it in 'setUp' method of concrete XCTestCase, assigning 'self' to it.
    public static var explicitCurrentTestCase: XCTestCase? = nil
}


// MARK: - Mock Engine

public extension MockFunction {
    /// Makes an expectation for mock call.
    func expect(_ description: String) -> ExpectMatch<Args, R> {
        ExpectMatch(description: description, addExpectation: addExpectation)
    }
}


// MARK: MockMethod

public class MockMethod<Args, R>: MockFunction<Args, R> {
    public init() { }
    
    /// Should be called inside mocked method implementation.
    public func call(_ args: Args, functionName: String = #function) -> R? {
        evaluate(args, functionName)
    }
    
    /// Should be called inside mocked method implementation.
    public func callT(_ args: Args, functionName: String = #function) throws -> R? {
        try evaluateT(args, functionName)
    }
}

public extension MockMethod where Args == Void {
    /// Should be called inside mocked method implementation.
    func call(functionName: String = #function) -> R? {
        call((), functionName: functionName)
    }
}

public extension MockMethod {
    /// Should be called inside mocked method implementation.
    func call<T0, T1>(_ arg0: T0, _ arg1: T1, functionName: String = #function) -> R? where Args == (T0, T1) {
        call((arg0, arg1), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2>(_ arg0: T0, _ arg1: T1, _ arg2: T2, functionName: String = #function) -> R? where Args == (T0, T1, T2) {
        call((arg0, arg1, arg2), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2, T3>(_ arg0: T0, _ arg1: T1, _ arg2: T2, _ arg3: T3, functionName: String = #function) -> R? where Args == (T0, T1, T2, T3) {
        call((arg0, arg1, arg2, arg3), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2, T3, T4>(_ arg0: T0, _ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, functionName: String = #function) -> R? where Args == (T0, T1, T2, T3, T4) {
        call((arg0, arg1, arg2, arg3, arg4), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2, T3, T4, T5>(_ arg0: T0, _ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, _ arg5: T5, functionName: String = #function) -> R? where Args == (T0, T1, T2, T3, T4, T5) {
        call((arg0, arg1, arg2, arg3, arg4, arg5), functionName: functionName)
    }
}


// MARK: MockClosure

public class MockClosure<Args, R>: MockFunction<Args, R> {
    private let closureName: String
    private let returnOnFail: R
    
    
    public init(_ closureName: String = "Anonymous closure.", returnOnFail: R) {
        self.closureName = closureName
        self.returnOnFail = returnOnFail
    }
}

public extension MockClosure {
    // MARK: No throw
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    /// Warning: for throwing closures use 'asClosureT'.
    func asClosure() -> (Args) -> R {
        return { self.evaluate($0) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    /// Warning: for throwing closures use 'asClosureT'.
    func asClosure<T0, T1>() -> (T0, T1) -> R where Args == (T0, T1) {
        return { self.evaluate(($0, $1)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    /// Warning: for throwing closures use 'asClosureT'.
    func asClosure<T0, T1, T2>() -> (T0, T1, T2) -> R where Args == (T0, T1, T2) {
        return { self.evaluate(($0, $1, $2)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    /// Warning: for throwing closures use 'asClosureT'.
    func asClosure<T0, T1, T2, T3>() -> (T0, T1, T2, T3) -> R where Args == (T0, T1, T2, T3) {
        return { self.evaluate(($0, $1, $2, $3)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    /// Warning: for throwing closures use 'asClosureT'.
    func asClosure<T0, T1, T2, T3, T4>() -> (T0, T1, T2, T3, T4) -> R where Args == (T0, T1, T2, T3, T4) {
        return { self.evaluate(($0, $1, $2, $3, $4)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    /// Warning: for throwing closures use 'asClosureT'. 
    func asClosure<T0, T1, T2, T3, T4, T5>() -> (T0, T1, T2, T3, T4, T5) -> R where Args == (T0, T1, T2, T3, T4, T5) {
        return { self.evaluate(($0, $1, $2, $3, $4, $5)) }
    }
    
    private func evaluate(_ args: Args) -> R {
        evaluate(args, self.closureName) ?? self.returnOnFail
    }
    
    
    // MARK: Throw
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    func asClosureT() -> (Args) throws -> R {
        return { try self.evaluateT($0) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    func asClosureT<T0, T1>() -> (T0, T1) throws -> R where Args == (T0, T1) {
        return { try self.evaluateT(($0, $1)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    func asClosureT<T0, T1, T2>() -> (T0, T1, T2) throws -> R where Args == (T0, T1, T2) {
        return { try self.evaluateT(($0, $1, $2)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    func asClosureT<T0, T1, T2, T3>() -> (T0, T1, T2, T3) throws -> R where Args == (T0, T1, T2, T3) {
        return { try self.evaluateT(($0, $1, $2, $3)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    func asClosureT<T0, T1, T2, T3, T4>() -> (T0, T1, T2, T3, T4) throws -> R where Args == (T0, T1, T2, T3, T4) {
        return { try self.evaluateT(($0, $1, $2, $3, $4)) }
    }
    
    /// Represents mocked method as usual closure. Conveniet to use when mocking callbacks.
    func asClosureT<T0, T1, T2, T3, T4, T5>() -> (T0, T1, T2, T3, T4, T5) throws -> R where Args == (T0, T1, T2, T3, T4, T5) {
        return { try self.evaluateT(($0, $1, $2, $3, $4, $5)) }
    }
    
    private func evaluateT(_ args: Args) throws -> R {
        try evaluateT(args, self.closureName) ?? self.returnOnFail
    }
}

public extension MockClosure where R == Void {
    convenience init(_ closureName: String = "Anonymous closure.") {
        self.init(closureName, returnOnFail: ())
    }
}


// MARK: MockSetter

public class MockSetter<T>: MockFunction<T, Void> {
    private let propertyName: String
    private let captor: InitedArgumentCaptor<T>

    
    public init(_ propertyName: String, _ value: T) {
        self.propertyName = propertyName
        self.captor = .create(initialValue: value)
        
        super.init(captor)
    }
    
    /// Should be called inside mocked property getter.
    public func callGet() -> T {
        captor.lastCaptured
    }
    
    /// Should be called inside mocked property setter.
    public func callSet(_ value: T)  {
        evaluate(value, propertyName)
    }
}


// MARK: - Match expectations

public typealias Matcher<Args> = (Args) -> Bool

public enum MatcherType<Args> {
    /// Match any arguments.
    case any
    
    /// Match arguments using specific matcher.
    case custom(Matcher<Args>)
}

public extension ExpectMatch {
    /// Expectation will be matched using the matcher.
    func match(_ matcher: MatcherType<Args>) -> OnMatchAction<Args, R> {
        OnMatchAction(description: description, matcher: matcher.match, addExpectation: addExpectation)
    }
}

public extension ExpectMatch where Args: Equatable {
    /// Expectation will be matched using the matcher.
    func match(_ value: Args) -> OnMatchAction<Args, R> {
        match(.equal(value))
    }
}


// MARK: - On-Match actions

public enum ExpectTimes {
    /// Exact number of calls.
    case count(Int)
    
    /// Any (0..∞) number of calls.
    case unlimited
}

public extension OnMatchAction {
    enum Action {
        case `return`(R)
        case `throw`(Error)
        case perform((Args) throws -> R)
    }
    
    
    /// Assumes expectation will be triggerred only once.
    func willOnce(_ action: Action) {
        willRepeatedly(.count(1), action)
    }
    
    /// Assumes expectation will be triggerred specific number of times.
    func willRepeatedly(_ times: ExpectTimes, _ action: Action) {
        addExpectation(description, times, matcher, argumentCaptors, action.action)
    }
    
    func willNever() {
        addExpectation(description, .count(0), matcher, argumentCaptors, nil)
    }
}

public extension OnMatchAction where R == Void {
    /// Assumes expectation will be triggerred only once.
     func willOnce() {
        willOnce(.return(()))
    }
    
    /// Assumes expectation will be triggerred specific number of times.
    func willRepeatedly(_ times: ExpectTimes) {
        willRepeatedly(times, .return(()))
    }
}


// MARK: Capturing arguments

public extension OnMatchAction {
    /// Adds 'captor' that captures arguments.
    func capture(_ captor: ArgumentCaptor<Args>) -> OnMatchAction<Args, R> {
        var copy = self
        copy.argumentCaptors.append(captor)
        
        return copy
    }
}

public extension ArgumentCaptor {
    /// Array of captured arguments. Last value is the latest captured one.
    var captured: [Args] { capturedArgs }
    
    /// Creates usual captor.
    static func create() -> ArgumentCaptor<Args> {
        ArgumentCaptor<Args>()
    }
    
    /// Creates captor with initial value.
    static func create(initialValue: Args) -> InitedArgumentCaptor<Args> {
        InitedArgumentCaptor<Args>(initialValue)
    }
}

public extension InitedArgumentCaptor {
    var lastCaptured: Args { captured.last ?? initialValue }
}


// MARK: - Other + Internal/Private

public class MockFunction<Args, R> {
    init (_ defaultCaptor: ArgumentCaptor<Args>? = nil) {
        self.defaultCaptor = defaultCaptor
    }
    
    /// Should be called inside mocked method implementation, passing all method parameters as Args tuple.
    func evaluate(_ args: Args, _ mockEntityName: String) -> R? {
        do {
            return try evaluateT(args, mockEntityName)
        } catch {
            fatalError("Throw exception in non-throwing function. Maybe you wanted to call 'throwing' version of call on mock?")
        }
    }
    
    func evaluateT(_ args: Args, _ mockEntityName: String) throws -> R? {
        guard let expectation = find(args, skip: 0) else {
            sMock.unexpectedCallBehavior.handleUnexpectedCall(mockEntityName)
            return nil
        }

        expectation.count -= 1
        
        return try expectation.action(args)
    }
    
    
    //  MARK: Private
    
    private class Expectation {
        var count: Int
        let matcher: Matcher<Args>
        let action: (Args) throws -> R?
        
        
        init(count: Int, matcher: @escaping (Args) -> Bool, action: @escaping (Args) throws -> R?) {
            self.count = count
            self.matcher = matcher
            self.action = action
        }
    }
    
    
    private let testCaseWatcher = CurrentTestCaseWatcher()
    private var expectations: [Expectation] = []
    private let defaultCaptor: ArgumentCaptor<Args>?
    
    
    private func addExpectation(_ description: String, times: ExpectTimes, matcher: @escaping Matcher<Args>, captors: [ArgumentCaptor<Args>], action: ExpectationAction<Args, R>) {
        let test = sMock.explicitCurrentTestCase ?? testCaseWatcher.currentTestCase
        let exp = times.expectation(test: test, description: description)
        expectations.append(Expectation(count: times.rawCount, matcher: matcher, action: { [weak defaultCaptor] (args) in
            defer { exp?.fulfill() }
            
            captors.forEach { $0.capture(args) }
            defaultCaptor?.capture(args)
            
            if let action = action {
                return try action(args)
            } else {
                return nil
            }
        }))
    }
    
    private func find(_ args: Args, skip: Int) -> Expectation? {
        for (idx, e) in expectations.dropFirst(skip).enumerated() {
            guard e.matcher(args) else { continue }
            return e.count > 0 ? e : find(args, skip: idx + 1 + skip)
        }
        
        return nil
    }
}

private typealias ExpectationAction<Args, R> = ((Args) throws -> R)?

public struct ExpectMatch<Args, R> {
    fileprivate let description: String
    fileprivate let addExpectation: (String, ExpectTimes, @escaping Matcher<Args>, [ArgumentCaptor<Args>], ExpectationAction<Args, R>) -> Void
}

public struct OnMatchAction<Args, R> {
    
    fileprivate let description: String
    fileprivate let matcher: Matcher<Args>
    fileprivate let addExpectation: (String, ExpectTimes, @escaping Matcher<Args>, [ArgumentCaptor<Args>], ExpectationAction<Args, R>) -> Void
    fileprivate var argumentCaptors: [ArgumentCaptor<Args>] = []
}

public class InitedArgumentCaptor<Args>: ArgumentCaptor<Args> {
    private let initialValue: Args
    
    
    init(_ initialValue: Args) {
        self.initialValue = initialValue
    }
}

public class ArgumentCaptor<Args> {
    private var capturedArgs: [Args] = []
    
    
    func capture(_ args: Args) {
        capturedArgs.append(args)
    }
}

private extension ExpectTimes {
    func expectation(test: XCTestCase, description: String) -> XCTestExpectation? {
        switch self {
        case .unlimited:
            return nil
        case .count(let count):
            let exp = test.expectation(description: description)
            if count > 0 {
                exp.expectedFulfillmentCount = count
            } else {
                exp.isInverted = true
            }
            
            return exp
        }
    }
    
    var rawCount: Int {
        switch self {
        case .unlimited:
            return Int.max
        case .count(let count):
            return count
        }
    }
}

private extension OnMatchAction.Action {
    var action: (Args) throws -> R {
        switch self {
        case .return(let value):
            return { _ in value }
        case .throw(let error):
            return { _ in throw error }
        case .perform(let action):
            return action
        }
    }
}

extension MatcherType {
    func match(_ args: Args) -> Bool {
        switch self {
        case .any:
            return true
        case .custom(let matcher):
            return matcher(args)
        }
    }
}

private extension sMock.UnexpectedCallBehavior {
    func handleUnexpectedCall(_ mockEntityName: String) {
        let message = "Unexpected call to \(mockEntityName)."
        switch self {
        case .warning:
            print(message)
        case .failTest:
            XCTFail(message)
        case .custom(let handler):
            handler(mockEntityName)
        }
    }
}

private class CurrentTestCaseWatcher {
    var currentTestCase: XCTestCase {
        guard let testCase = observedTestCase ?? extractCurrentTestCase else {
            fatalError("Failed to obtain current test case. Please explicitly set 'sMock_explicitCurrentTestCase' global variable.")
        }
        
        return testCase
    }
    
    init() {
        observer.onWillStart = { [weak self] in self?.handleTestCaseChange($0) }
        observer.onDidFinish = { [weak self] _ in self?.handleTestCaseChange(nil) }
        Self.syncOnMainNonblock { XCTestObservationCenter.shared.addTestObserver(observer) }
    }
    
    deinit {
        Self.syncOnMainNonblock { XCTestObservationCenter.shared.removeTestObserver(observer) }
    }
    
    // MARK: Private
    
    private class Observer: NSObject, XCTestObservation {
        var onWillStart: ((_ testCase: XCTestCase) -> Void)?
        var onDidFinish: ((_ testCase: XCTestCase) -> Void)?

        func testCaseWillStart(_ testCase: XCTestCase) { onWillStart?(testCase) }
        func testCaseDidFinish(_ testCase: XCTestCase) { onDidFinish?(testCase) }
    }
    
    private let observer = Observer()
    private var observedTestCase: XCTestCase?
    
    
    private func handleTestCaseChange(_ testCase: XCTestCase?) {
        observedTestCase = testCase
        sMock.unexpectedCallBehavior = .failTest
    }
    
    private var extractCurrentTestCase: XCTestCase? {
        guard let cl: AnyClass = NSClassFromString("XCTestMisuseObserver"),
            let builtInObservers = XCTestObservationCenter.shared.perform(NSSelectorFromString("observers")),
            let builtInObserverArray = builtInObservers.takeUnretainedValue() as? [NSObject],
            let misuseObserver = builtInObserverArray.first(where: { $0.isKind(of: cl) }),
            let currentCaseAny = misuseObserver.perform(NSSelectorFromString("currentTestCase")),
            let currentCase = currentCaseAny.takeUnretainedValue() as? XCTestCase else {
                return nil
        }
        
        return currentCase
    }
    
    static func syncOnMainNonblock<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
}
