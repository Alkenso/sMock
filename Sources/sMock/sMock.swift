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
    static func waitForExpectations() -> Bool {
        waitForExpectations(timeout: waitTimeout, enforceOrder: false) == .completed
    }
    
    /// Wait for currently registered sMock expectations. Extended version.
    static func waitForExpectations(timeout seconds: TimeInterval, enforceOrder enforceOrderOfFulfillment: Bool) -> XCTWaiter.Result {
        XCTWaiter.wait(for: extractExpectations(), timeout: seconds, enforceOrder: enforceOrderOfFulfillment)
    }
    
    /// Extracts all current sMock expectations, transferring them to the caller.
    static func extractExpectations() -> [XCTestExpectation] {
        expectationsSyncQueue.sync {
            let currentExpectations = expectations
            expectations = []
            
            return currentExpectations
        }
    }
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
    
    
    // MARK: Private
    
    private let observer = CurrentTestObserver()
    
    private init() {
        observer.onWillStart = { [weak self] in self?.handleTestCaseChange($0) }
        observer.onDidFinish = { [weak self] _ in self?.handleTestCaseChange(nil) }
        Utils.syncOnMainNonblock { XCTestObservationCenter.shared.addTestObserver(observer) }
    }
    
    deinit {
        Utils.syncOnMainNonblock { XCTestObservationCenter.shared.removeTestObserver(observer) }
    }
    
    private func handleTestCaseChange(_ testCase: XCTestCase?) {
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
}
