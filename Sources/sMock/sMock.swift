import XCTest


// MARK: - ExpectMatch

public extension ExpectMatch {
    func match(_ matcher: @escaping (Args) -> Bool) -> ExpectReturn<Args, R> {
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
    func willOnce(_ action: @escaping () -> R) {
        addExpectation(description, .count(1), matcher, action)
    }
    
    func willOnce(_ value: R) {
        willOnce({ value })
    }
    
    func willRepeatedly(_ times: ExpectTimes, _ action: @escaping () -> R) {
        addExpectation(description, times, matcher, action)
    }
    
    func willRepeatedly(_ times: ExpectTimes, value: R) {
        willRepeatedly(times, { value })
    }
}

public extension ExpectReturn where R == Void {
     func willOnce() {
        willOnce(())
    }
    
    func willRepeatedly(_ times: ExpectTimes) {
        willRepeatedly(times, value: ())
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
        
        return expectation.action()
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
        let matcher: (Args) -> Bool
        let action: () -> R
        
        
        init(count: Int, matcher: @escaping (Args) -> Bool, action: @escaping () -> R) {
            self.count = count
            self.matcher = matcher
            self.action = action
        }
    }
    
    
    private var expectations: [Expectation] = []
    private let test: XCTestCase
    
    
    private func addExpectation(_ description: String, times: ExpectTimes, matcher: @escaping (Args) -> Bool, action: @escaping () -> R) {
        let exp = times.expectation(test: test, description: description)
        expectations.append(Expectation(count: times.rawCount, matcher: matcher, action: {
            exp?.fulfill()
            return action()
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
    fileprivate let addExpectation: (String, ExpectTimes, @escaping (Args) -> Bool, @escaping () -> R) -> Void
}

public struct ExpectReturn<Args, R> {
    fileprivate let description: String
    fileprivate let matcher: (Args) -> Bool
    fileprivate let addExpectation: (String, ExpectTimes, @escaping (Args) -> Bool, @escaping () -> R) -> Void
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

private extension XCTestCase {
    static var currentTestCase: XCTestCase {
        guard let cl: AnyClass = NSClassFromString("XCTestMisuseObserver"),
            let builtInObservers = XCTestObservationCenter.shared.perform(NSSelectorFromString("observers")),
            let builtInObserverArray = builtInObservers.takeUnretainedValue() as? [NSObject],
            let misuseObserver = builtInObserverArray.first(where: { $0.isKind(of: cl) }),
            let currentCase = misuseObserver.perform(NSSelectorFromString("currentTestCase"))?.takeUnretainedValue() as? XCTestCase else {
                fatalError("Failed to obtain current test case. Please use explicit transfer of current test case.")
        }
        
        return currentCase
    }
}
