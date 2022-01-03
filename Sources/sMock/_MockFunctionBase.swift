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

// MARK: - MockFunctionBase

public class _MockFunctionBase<Args, R, Finalize> {
    private var allExpectations: [ArmedExpectation<Args, R>] = []
    
    public init() { }
    
    func finalize() -> Finalize {
        fatalError("finalize() MUST be implemented in subclass \(Self.self)")
    }
    
    private func armExpectation(_ expectation: Expectation<Args, R>) {
        allExpectations.append(.init(expectation: expectation))
    }

    // MARK: Make expectations
    
    public func expect(_ description: String) -> OnExpect<Args, R, Finalize> {
        var exp = Expectation<Args, R>()
        exp.description = description
        return OnExpect(expectation: exp) {
            self.armExpectation($0)
            return self.finalize()
        }
    }
    
    public func expect(_ description: String) -> OnMatch<Args, R, Finalize> where Args == Void {
        (expect(description) as OnExpect<Args, R, Finalize>).match()
    }
    
    // MARK: Evaluate calls
    
    /// Should be called inside mocked method implementation, passing all method parameters as Args tuple.
    func evaluate(_ args: Args, _ mockEntityName: String) -> R? {
        do {
            return try evaluateT(args, mockEntityName)
        } catch {
            XCTFail("Throw exception in non-throwing function. Maybe you wanted to call 'throwing' version of call on mock?")
            return nil
        }
    }
    
    func evaluateT(_ args: Args, _ mockEntityName: String) throws -> R? {
        for expectation in allExpectations {
            if let result = try expectation.tryFulfill(args) {
                return result
            }
        }
        
        sMock.unexpectedCallBehavior.handleUnexpectedCall(mockEntityName)
        return nil
    }
}

struct Expectation<Args, R> {
    var description: String = ""
    var times: ExpectTimes = .count(0)
    var matcher: Matcher<Args> = .any
    var action: OnMatchAction<Args, R>?
    var onMatch: [(Args) -> Void] = []
}

class ArmedExpectation<Args, R> {
    private let expectation: Expectation<Args, R>
    private let xctExpectation: XCTestExpectation?
    private let queue = DispatchQueue(label: "ArmedExpectation.queue")
    private var count: Int = 0
    
    init(expectation: Expectation<Args, R>) {
        self.expectation = expectation
        self.xctExpectation = expectation.times.expectation(description: expectation.description)
    }
    
    func tryFulfill(_ args: Args) throws -> R? {
        guard expectation.matcher(args) else { return nil }
        guard testAndIncrement() else { return nil }
        
        defer { xctExpectation?.fulfill() }
        
        expectation.onMatch.forEach { $0(args) }
        
        return try expectation.action?(args)
    }
    
    private func testAndIncrement() -> Bool {
        queue.sync {
            guard count < expectation.times.rawCount else { return false }
            
            count += 1
            return true
        }
    }
}

// MARK: - OnExpect

public struct OnExpect<Args, R, Finalize> {
    var expectation: Expectation<Args, R>
    var addExpectation: (Expectation<Args, R>) -> Finalize
    
    /// Expectation will be matched using the matcher.
    public func match(_ matcher: Matcher<Args>) -> OnMatch<Args, R, Finalize> {
        var exp = expectation
        exp.matcher = matcher
        return OnMatch(expectation: exp, addExpectation: addExpectation)
    }
}
 
extension OnExpect {
    public func match(_ value: Args) -> OnMatch<Args, R, Finalize> where Args: Equatable {
        match(.equal(value))
    }
    
    public func match() -> OnMatch<Args, R, Finalize> where Args == Void {
        match(.any)
    }
}

// MARK: - OnMatch

public struct OnMatch<Args, R, Finalize> {
    var expectation: Expectation<Args, R>
    var addExpectation: (Expectation<Args, R>) -> Finalize
    
    private func finalize(_ times: ExpectTimes, _ action: OnMatchAction<Args, R>?) -> Finalize {
        var exp = expectation
        exp.times = times
        exp.action = action
        return addExpectation(exp)
    }
}

// MARK: Match count

extension OnMatch {
    /// Assumes expectation will be triggerred specific number of times.
    public func willRepeatedly(_ times: ExpectTimes, _ action: OnMatchAction<Args, R>) -> Finalize {
        finalize(times, action)
    }
    
    /// Assumes expectation will be triggerred only once.
    public func willOnce(_ action: OnMatchAction<Args, R>) -> Finalize {
        finalize(.count(1), action)
    }
    
    public func willNever() -> Finalize {
        finalize(.count(0), nil)
    }
}

extension OnMatch where R == Void {
    /// Assumes expectation will be triggerred only once.
    public func willOnce() -> Finalize where R == Void {
        willOnce(.return(()))
    }
    
    /// Assumes expectation will be triggerred specific number of times.
    public func willRepeatedly(_ times: ExpectTimes) -> Finalize where R == Void {
        willRepeatedly(times, .return(()))
    }
}

// MARK: Custom match actions

extension OnMatch {
    /// Adds 'captor' that captures arguments.
    public func onMatch(_ action: @escaping (Args) -> Void) -> Self {
        var copy = self
        copy.expectation.onMatch.append(action)
        
        return copy
    }
    
    /// Adds 'captor' that captures arguments.
    public func capture(_ captor: ArgumentCaptor<Args>) -> Self {
        onMatch(captor.capture)
    }
}

// MARK: OnMatch utils

public enum ExpectTimes {
    /// Exact number of calls.
    case count(Int)
    
    /// Any (0..∞) number of calls.
    case unlimited
}

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

public struct OnMatchAction<Args, R> {
    let fn: (Args) throws -> R
    func callAsFunction(_ args: Args) throws -> R { try fn(args) }
}

extension OnMatchAction {
    public static func `return`(_ value: R) -> Self {
        .init { _ in value }
    }
    
    public static func `throw`(_ error: Error) -> Self {
        .init { _ in throw error }
    }
    
    public static func perform(_ body: @escaping (Args) throws -> R) -> Self {
        .init(fn: body)
    }
}

// MARK: - Capturing arguments

public class ArgumentCaptor<Args> {
    private var queue = DispatchQueue(label: "ArgumentCaptor")
    private var capturedArgs: [Args] = []
    
    public init() { }
    
    /// Array of captured arguments. Last value is the latest captured one.
    public var captured: [Args] { queue.sync { capturedArgs } }
    
    func capture(_ args: Args) {
        queue.async {
            self.capturedArgs.append(args)
        }
    }
}
