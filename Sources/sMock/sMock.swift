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

public enum sMock { }

/// sMock configuration.
public extension sMock {
    enum UnexpectedCallBehavior {
        /// Only warns (print) about unexpected call of mocked entities.
        case warning
        
        /// Calls XCTFail for unexpected call of mocked entities.
        case failTest
        
        /// Applies custom handler for unexpected call of mocked entities.
        case custom((_ mockedEntity: String) -> Void)
    }
    
    /// Handler will be called each time unexpected call on mock object is made.
    /// By default, in such cases sMock will trigger XCTFail.
    /// Change this handler in 'setUp' method either on each test case or in the very beginning of the individual test.
    static var unexpectedCallBehavior: UnexpectedCallBehavior = .failTest
    
    /// Timeout used when calling `waitForExpectations() -> Bool` method.
    /// Change this value in 'setUp' method either on each test case or in the very beginning of the individual test.
    static var waitTimeout: TimeInterval = 0.5
    
    /// Wait for currently registered sMock expectations.
    /// - returns: Boolean indicating if all expectations has been waited.
    @discardableResult
    static func waitForExpectations(file: String = #file, line: Int = #line) -> Bool {
        waitForExpectations(timeout: waitTimeout, enforceOrder: false, file: file, line: line) == .completed
    }
    
    /// Wait for currently registered sMock expectations. Extended version.
    static func waitForExpectations(timeout seconds: TimeInterval, enforceOrder enforceOrderOfFulfillment: Bool, file: String = #file, line: Int = #line) -> XCTWaiter.Result {
        let delegate = FailureReporter(file: file, line: line, timeout: seconds)
        let waiter = XCTWaiter(delegate: delegate)
        let waitResult = waiter.wait(for: extractExpectations(), timeout: seconds, enforceOrder: enforceOrderOfFulfillment)
        
        return waitResult
    }
    
    /// Extracts all current sMock expectations, transferring them to the caller.
    static func extractExpectations() -> [XCTestExpectation] {
        expectationsSyncQueue.sync {
            let currentExpectations = expectations
            expectations = []
            
            return currentExpectations
        }
    }
    
    ////// Workaround when 'CurrentTestCaseProvider.currentTestCase' fails due to unknown reason.
    /// Set this variable before using any mock objects.
    /// Usually set it in 'setUp' method of concrete XCTestCase, assigning 'self' to it.
    static var explicitCurrentTestCase: XCTestCase? = nil
}

extension sMock {
    static func expectation(description: String = "") -> XCTestExpectation {
        expectationsSyncQueue.sync {
            let exp = XCTestExpectation(description: description)
            expectations.append(exp)
            
            return exp
        }
    }
    
    private static let expectationsSyncQueue = DispatchQueue(label: "sMock.expectationsSyncQueue")
    private static var expectations: [XCTestExpectation] = []
}

extension sMock.UnexpectedCallBehavior {
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

private extension sMock {
    static let defaultUnexpectedCallBehavior: UnexpectedCallBehavior = .failTest
    static var defaultWaitTimeout: TimeInterval = 0.5
}

// MARK: - MocksSupport

protocol MocksSupporting {
    var mocksSupport: MocksSupport { get }
}

class MocksSupport {
    static let shared = MocksSupport()
    
    var currentTestCase: XCTestCase {
        guard let testCase = observedTestCase ?? Utils.extractCurrentTestCase() ?? sMock.explicitCurrentTestCase else {
            fatalError("Failed to obtain current test case. Please explicitly set 'sMock.explicitCurrentTestCase' global variable.")
        }
        
        return testCase
    }
    
    
    // MARK: Private
    
    private let observer = CurrentTestObserver()
    private var observedTestCase: XCTestCase?
    
    
    private init() {
        observer.onWillStart = { [weak self] in self?.handleTestCaseChange($0) }
        observer.onDidFinish = { [weak self] _ in self?.handleTestCaseChange(nil) }
        Utils.syncOnMainNonblock { XCTestObservationCenter.shared.addTestObserver(observer) }
    }
    
    deinit {
        Utils.syncOnMainNonblock { XCTestObservationCenter.shared.removeTestObserver(observer) }
    }
    
    private func handleTestCaseChange(_ testCase: XCTestCase?) {
        observedTestCase = testCase
        
        // Reset defaults.
        sMock.unexpectedCallBehavior = sMock.defaultUnexpectedCallBehavior
        sMock.defaultWaitTimeout = sMock.defaultWaitTimeout
        
        //  Cleanup expectations.
        let _ = sMock.extractExpectations()
    }
}

private extension MocksSupport {
    private class CurrentTestObserver: NSObject, XCTestObservation {
        var onWillStart: ((_ testCase: XCTestCase) -> Void)?
        var onDidFinish: ((_ testCase: XCTestCase) -> Void)?
        
        func testCaseWillStart(_ testCase: XCTestCase) { onWillStart?(testCase) }
        func testCaseDidFinish(_ testCase: XCTestCase) { onDidFinish?(testCase) }
    }
}

private enum Utils {
    static func syncOnMainNonblock<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
    
    static func extractCurrentTestCase() -> XCTestCase? {
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
}

private extension sMock {
    class FailureReporter: NSObject, XCTWaiterDelegate {
        private let _file: String
        private let _line: Int
        private let _timeout: TimeInterval
        
        init(file: String, line: Int, timeout: TimeInterval) {
            _file = file
            _line = line
            _timeout = timeout
        }
        
        func waiter(_ waiter: XCTWaiter, didTimeoutWithUnfulfilledExpectations unfulfilledExpectations: [XCTestExpectation]) {
            let expectationsDescription = unfulfilledExpectations.map { "\"\($0.expectationDescription)\"" }.joined(separator: ", ")
            reportFailure("Asynchronous wait failed: Exceeded timeout of \(_timeout) seconds, with unfulfilled expectations: \(expectationsDescription).")
        }
        
        func waiter(_ waiter: XCTWaiter, fulfillmentDidViolateOrderingConstraintsFor expectation: XCTestExpectation, requiredExpectation: XCTestExpectation) {
            reportFailure("Failed due to expectation fulfilled in incorrect order: requires \"\(requiredExpectation.expectationDescription)\", actually fulfilled \"\(expectation.expectationDescription)\".")
        }
        
        func waiter(_ waiter: XCTWaiter, didFulfillInvertedExpectation expectation: XCTestExpectation) {
            reportFailure("Fulfilled inverted expectation \"\(expectation.expectationDescription)\".")
        }
        
        func nestedWaiter(_ waiter: XCTWaiter, wasInterruptedByTimedOutWaiter outerWaiter: XCTWaiter) {
            reportFailure("Asynchronous waiter \(waiter) failed: interrupted by timeout of containing waiter \(outerWaiter).");
        }
        
        private func reportFailure(_ description: String) {
            MocksSupport.shared.currentTestCase.recordFailure(withDescription: description, inFile: _file, atLine: _line, expected: true)
        }
    }
}
