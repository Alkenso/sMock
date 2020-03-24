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


// MARK: - ExpectMatch

public typealias Matcher<Args> = (Args) -> Bool

public extension ExpectMatch {
    func match(_ matcher: @escaping Matcher<Args>) -> ExpectReturn<Args, R> {
        ExpectReturn(description: description, matcher: matcher, addExpectation: addExpectation)
    }
    
    func matchAll() -> ExpectReturn<Args, R> {
        match({ _ in true })
    }
}

public extension ExpectMatch where Args: Equatable {
    func match(_ value: Args) -> ExpectReturn<Args, R> {
        match({ $0 == value })
    }
}


// MARK: - ExpectReturn

public enum ExpectTimes {
    case count(Int)
    case unlimited
}

public extension ExpectReturn {
    func capture(_ captor: ArgumentCaptor<Args>) -> ExpectReturn<Args, R> {
        var copy = self
        copy.argumentCaptor = captor
        
        return copy
    }
}

public extension ExpectReturn {
    enum Action {
        case `return`(R)
        case perform((Args) -> R)
    }
    
    
    func willOnce(_ action: Action) {
        willRepeatedly(.count(1), action)
    }
    
    func willRepeatedly(_ times: ExpectTimes, _ action: Action) {
        addExpectation(description, times, matcher, argumentCaptor, action.action)
    }
}

public extension ExpectReturn where R == Void {
     func willOnce() {
        willOnce(.return(()))
    }
    
    func willRepeatedly(_ times: ExpectTimes) {
        willRepeatedly(times, .return(()))
    }
}


// MARK: - ArgumentCaptor

public extension ArgumentCaptor {
    var captured: [Args] { capturedArgs }
    
    static func create(_ onCapture: @escaping (Args) -> Void = { _ in }) -> ArgumentCaptor<Args> {
        ArgumentCaptor<Args>(onCapture)
    }
}


// MARK: - MockMethod

public extension MockMethod {
    func expect(_ description: String) -> ExpectMatch<Args, R> {
        ExpectMatch(description: description, addExpectation: addExpectation)
    }
    
    func evaluate(_ args: Args, function: String = #function) -> R? {
        guard let expectation = find(args, skip: 0) else {
            XCTFail("Unexpected call to \(function).")
            return nil
        }
        
        expectation.count -= 1
        
        return expectation.action(args)
    }
}

public extension MockMethod where Args == Void {
    func evaluate(function: String = #function) -> R? {
        evaluate((), function: function)
    }
}


// MARK: - Other + Internal/Private

public class MockMethod<Args, R> {
    public init(_ test: XCTestCase) {
        self.test = test
    }
    
    public convenience init() {
        self.init(.currentTestCase)
    }
    
    //  MARK: Private
    
    private class Expectation {
        var count: Int
        let matcher: Matcher<Args>
        let action: (Args) -> R
        
        
        init(count: Int, matcher: @escaping (Args) -> Bool, action: @escaping (Args) -> R) {
            self.count = count
            self.matcher = matcher
            self.action = action
        }
    }
    
    
    private var expectations: [Expectation] = []
    private let test: XCTestCase
    
    
    private func addExpectation(_ description: String, times: ExpectTimes, matcher: @escaping Matcher<Args>, captor: ArgumentCaptor<Args>?, action: @escaping (Args) -> R) {
        let exp = times.expectation(test: test, description: description)
        expectations.append(Expectation(count: times.rawCount, matcher: matcher, action: {
            exp?.fulfill()
            captor?.capture($0)
            return action($0)
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

public struct ExpectMatch<Args, R> {
    fileprivate let description: String
    fileprivate let addExpectation: (String, ExpectTimes, @escaping Matcher<Args>, ArgumentCaptor<Args>?, @escaping (Args) -> R) -> Void
}

public struct ExpectReturn<Args, R> {
    fileprivate let description: String
    fileprivate let matcher: Matcher<Args>
    fileprivate let addExpectation: (String, ExpectTimes, @escaping Matcher<Args>, ArgumentCaptor<Args>?, @escaping (Args) -> R) -> Void
    fileprivate var argumentCaptor: ArgumentCaptor<Args>?
}

public class ArgumentCaptor<Args> {
    private let onCapture: (Args) -> Void
    private var capturedArgs: [Args] = []
    
    
    func capture(_ args: Args) {
        capturedArgs.append(args)
        onCapture(args)
    }
    
    
    private init(_ onCapture: @escaping (Args) -> Void) {
        self.onCapture = onCapture
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

private extension ExpectReturn.Action {
    var action: (Args) -> R {
        switch self {
        case .return(let value):
            return { _ in value }
        case .perform(let action):
            return action
        }
    }
}

private extension XCTestCase {
    static var currentTestCase: XCTestCase {
        guard let cl: AnyClass = NSClassFromString("XCTestMisuseObserver"),
            let builtInObservers = XCTestObservationCenter.shared.perform(NSSelectorFromString("observers")),
            let builtInObserverArray = builtInObservers.takeUnretainedValue() as? [NSObject],
            let misuseObserver = builtInObserverArray.first(where: { $0.isKind(of: cl) }),
            let currentCaseAny = misuseObserver.perform(NSSelectorFromString("currentTestCase")),
            let currentCase = currentCaseAny.takeUnretainedValue() as? XCTestCase else {
                fatalError("Failed to obtain current test case. Please use explicit transfer of current test case.")
        }

        return currentCase
    }
}
