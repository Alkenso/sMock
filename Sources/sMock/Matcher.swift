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

import Foundation

public struct Matcher<Args> {
    let fn: (Args) -> Bool
    
    public init(_ fn: @escaping (Args) -> Bool) {
        self.fn = fn
    }
    
    public func callAsFunction(_ args: Args) -> Bool { fn(args) }
}

// MARK: - Multiple argument match

public extension Matcher {
    static var any: Self { .init { _ in true } }
    
    static func allOf(_ matchers: Matcher<Args>...) -> Matcher<Args> {
        .init { args in
            matchers.first { $0(args) == false } == nil
        }
    }
    
    static func anyOf(_ matchers: Matcher<Args>...) -> Matcher<Args> {
        .init { args in
            matchers.first { $0(args) == true } != nil
        }
    }
}

public extension Matcher {
    static func splitArgs<T0, T1>(
        _ matcher0: Matcher<T0>,
        _ matcher1: Matcher<T1>) -> Matcher<(T0, T1)> {
            .init { matcher0($0.0) && matcher1($0.1) }
        }
    
    static func splitArgs<T0, T1, T2>(
        _ matcher0: Matcher<T0>,
        _ matcher1: Matcher<T1>,
        _ matcher2: Matcher<T2>
    ) -> Matcher<(T0, T1, T2)> {
        .init { matcher0($0.0) && matcher1($0.1) && matcher2($0.2) }
    }
    
    static func splitArgs<T0, T1, T2, T3>(
        _ matcher0: Matcher<T0>,
        _ matcher1: Matcher<T1>,
        _ matcher2: Matcher<T2>,
        _ matcher3: Matcher<T3>
    ) -> Matcher<(T0, T1, T2, T3)> {
        .init { matcher0($0.0) && matcher1($0.1) && matcher2($0.2) && matcher3($0.3) }
    }
    
    static func splitArgs<T0, T1, T2, T3, T4>(
        _ matcher0: Matcher<T0>,
        _ matcher1: Matcher<T1>,
        _ matcher2: Matcher<T2>,
        _ matcher3: Matcher<T3>,
        _ matcher4: Matcher<T4>
    ) -> Matcher<(T0, T1, T2, T3, T4)> {
        .init { matcher0($0.0) && matcher1($0.1) && matcher2($0.2) && matcher3($0.3) && matcher4($0.4) }
    }
    
    static func splitArgs<T0, T1, T2, T3, T4, T5>(
        _ matcher0: Matcher<T0>,
        _ matcher1: Matcher<T1>,
        _ matcher2: Matcher<T2>,
        _ matcher3: Matcher<T3>,
        _ matcher4: Matcher<T4>,
        _ matcher5: Matcher<T5>
    ) -> Matcher<(T0, T1, T2, T3, T4, T5)> {
        .init {
            matcher0($0.0) && matcher1($0.1) && matcher2($0.2) && matcher3($0.3) && matcher4($0.4) && matcher5($0.5)
        }
    }
}

// MARK: KeyPath, Optional, Cast

public extension Matcher {
    static func keyPath<Root, Value>(_ keyPath: KeyPath<Root, Value>, _ valueMatcher: Matcher<Value>) -> Matcher<Root> {
        .init { valueMatcher($0[keyPath: keyPath]) }
    }
    
    static func keyPath<Root, Value>(
        _ keyPath: KeyPath<Root, Value>, _ value: Value
    ) -> Matcher<Root> where Value: Equatable {
        .keyPath(keyPath, .equal(value))
    }
}

public extension Matcher {
    static func optional(_ matcher: Matcher<Args?>) -> Matcher<Args> {
        .init { matcher($0) }
    }
    
    static func isNil<T>() -> Matcher<Args> where Args == Optional<T> {
        .init { $0 == nil }
    }
    
    static func notNil<T>() -> Matcher<Args> where Args == Optional<T> {
        .init { $0 != nil }
    }
}

public extension Matcher {
    static func cast<T>(_ matcher: Matcher<T>) -> Matcher<Args> {
        .cast(to: T.self, matcher)
    }
    
    static func cast<T>(to type: T.Type, _ matcher: Matcher<T>) -> Matcher<Args> {
        .init {
            guard let arg = $0 as? T else { return false }
            return matcher(arg)
        }
    }
}

// MARK: Equatable

public extension Matcher where Args: Equatable {
    static func equal(_ value: Args) -> Matcher<Args> {
        .init { $0 == value }
    }
    
    static func notEqual(_ value: Args) -> Matcher<Args> {
        .init { $0 != value }
    }
}

// MARK: Comparable

public extension Matcher where Args: Comparable {
    static func greaterEqual(_ value: Args) -> Matcher<Args> {
        .init { $0 >= value }
    }
    
    static func greater(_ value: Args) -> Matcher<Args> {
        .init { $0 > value }
    }
    
    static func lessEqual(_ value: Args) -> Matcher<Args> {
        .init { $0 <= value }
    }
    
    static func less(_ value: Args) -> Matcher<Args> {
        .init { $0 < value }
    }
}

// MARK: Bool

public extension Matcher where Args == Bool {
    static func isTrue() -> Matcher<Args> {
        .init { $0 == true }
    }
    
    static func isFalse() -> Matcher<Args> {
        .init { $0 == false }
    }
}

// MARK: String

public extension Matcher where Args == String {
    static func strCaseEqual<S: StringProtocol>(_ str: S) -> Matcher<Args> {
        .init { $0.compare(str, options: .caseInsensitive) == .orderedSame }
    }
    
    static func strCaseNotEqual<S: StringProtocol>(_ str: S) -> Matcher<Args> {
        .init { $0.compare(str, options: .caseInsensitive) != .orderedSame }
    }
}

// MARK: Result

public extension Matcher {
    static func success<Success, Failure>(_ matcher: Matcher<Success>) -> Matcher<Args>
    where Args == Result<Success, Failure> {
        .init {
            switch $0 {
            case .success(let value): return matcher(value)
            case .failure: return false
            }
        }
    }
    
    static func failure<Success, Failure>(_ matcher: Matcher<Failure>) -> Matcher<Args>
    where Args == Result<Success, Failure> {
        .init {
            switch $0 {
            case .success: return false
            case .failure(let error): return matcher(error)
            }
        }
    }
}

// MARK: - Collection

public extension Matcher where Args: Collection, Args.Element: Equatable {
    static func contains(_ element: Args.Element) -> Matcher<Args> {
        .init { $0.contains(element) }
    }
    
    static func containsAllOf<C>(_ subset: C) -> Matcher<Args> where C: Collection, C.Element == Args.Element {
        .init { collection in subset.reduce(true) { $0 && collection.contains($1) } }
    }
    
    static func containsAnyOf<C>(_ subset: C) -> Matcher<Args> where C: Collection, C.Element == Args.Element {
        .init { collection in subset.reduce(false) { $0 || collection.contains($1) } }
    }
    
    static func startsWith<C>(_ prefix: C) -> Matcher<Args> where C: Collection, C.Element == Args.Element {
        .init { $0.starts(with: prefix) }
    }
    
    static func endsWith<C>(_ suffix: C) -> Matcher<Args> where C: Collection, C.Element == Args.Element {
        .init {
            guard $0.count < suffix.count else { return false }
            return $0.dropFirst($0.count - suffix.count).elementsEqual(suffix)
        }
    }
}

public extension Matcher where Args: Collection {
    static func isEmpty() -> Matcher<Args> {
        .init { $0.isEmpty }
    }
    
    static func sizeIs(_ size: Int) -> Matcher<Args> {
        .init { $0.count == size }
    }
    
    static func each(_ matcher: Matcher<Args.Element>) -> Matcher<Args> {
        .init { $0.reduce(true) { $0 && matcher($1) } }
    }
    
    static func atLeastOne(_ matcher: Matcher<Args.Element>) -> Matcher<Args> {
        .init { $0.reduce(false) { $0 || matcher($1) } }
    }
}

// MARK: Element in Collection

public extension Matcher where Args: Equatable {
    static func inCollection<C: Collection>(_ collection: C) -> Matcher<Args> where Args == C.Element {
        .init { collection.contains($0) }
    }
}
