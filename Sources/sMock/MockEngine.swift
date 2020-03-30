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


// MARK: - Making expectations

public extension MockFunction {
    /// Makes an expectation for mock call.
    func expect(_ description: String) -> ExpectMatch<Args, R> {
        ExpectMatch(description: description, addExpectation: addExpectation)
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

public struct ExpectMatch<Args, R> {
    fileprivate let description: String
    fileprivate let addExpectation: (String, ExpectTimes, @escaping Matcher<Args>, [ArgumentCaptor<Args>], ExpectationAction<Args, R>) -> Void
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

public struct OnMatchAction<Args, R> {
    fileprivate let description: String
    fileprivate let matcher: Matcher<Args>
    fileprivate let addExpectation: (String, ExpectTimes, @escaping Matcher<Args>, [ArgumentCaptor<Args>], ExpectationAction<Args, R>) -> Void
    fileprivate var argumentCaptors: [ArgumentCaptor<Args>] = []
}


// MARK: - Capturing arguments

public extension OnMatchAction {
    /// Adds 'captor' that captures arguments.
    func capture(_ captor: ArgumentCaptor<Args>) -> OnMatchAction<Args, R> {
        var copy = self
        copy.argumentCaptors.append(captor)
        
        return copy
    }
}

/// Usual argument captor.
public class ArgumentCaptor<Args> {
    private var capturedArgs: [Args] = []
    
    public init() { }
    
    /// Array of captured arguments. Last value is the latest captured one.
    public var captured: [Args] { capturedArgs }
}

/// Argument captor with initial value.
public class InitedArgumentCaptor<Args>: ArgumentCaptor<Args> {
    private let initialValue: Args
    
    public init(_ initialValue: Args) { self.initialValue = initialValue }
    
    /// Last captured value or initial value if nothing was captured.
    public var lastCaptured: Args { captured.last ?? initialValue }
}

private extension ArgumentCaptor {
    func capture(_ args: Args) {
        capturedArgs.append(args)
    }
}

// MARK: - Internals

private typealias ExpectationAction<Args, R> = ((Args) throws -> R)?

public class MockFunction<Args, R>: MocksSupporting {
    let mocksSupport = MocksSupport.shared
    
    
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
    
    private var expectations: [Expectation] = []
    private let defaultCaptor: ArgumentCaptor<Args>?
    
    
    private func addExpectation(_ description: String, times: ExpectTimes, matcher: @escaping Matcher<Args>, captors: [ArgumentCaptor<Args>], action: ExpectationAction<Args, R>) {
        let exp = times.expectation(description: description)
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

private extension MockFunction {
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
}


// MARK: - Internal extensions

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


// MARK: - Private extensions

private extension ExpectTimes {
    func expectation(description: String) -> XCTestExpectation? {
        switch self {
        case .unlimited:
            return nil
        case .count(let count):
            let exp = sMock.expectation(description: description)
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
