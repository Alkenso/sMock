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


// MARK: - Multiple argument match

public extension MatcherType {
    static func split<T0, T1>(_ matcher0: MatcherType<T0>,
                              _ matcher1: MatcherType<T1>) -> MatcherType<(T0, T1)> {
        .custom({ matcher0.match($0.0) && matcher1.match($0.1) })
    }

    static func split<T0, T1, T2>(_ matcher0: MatcherType<T0>,
                                  _ matcher1: MatcherType<T1>,
                                  _ matcher2: MatcherType<T2>) -> MatcherType<(T0, T1, T2)> {
        .custom({ matcher0.match($0.0) && matcher1.match($0.1) && matcher2.match($0.2) })
    }

    static func split<T0, T1, T2, T3>(_ matcher0: MatcherType<T0>,
                                      _ matcher1: MatcherType<T1>,
                                      _ matcher2: MatcherType<T2>,
                                      _ matcher3: MatcherType<T3>) -> MatcherType<(T0, T1, T2, T3)> {
        .custom({ matcher0.match($0.0) && matcher1.match($0.1) && matcher2.match($0.2) && matcher3.match($0.3) })
    }

    static func split<T0, T1, T2, T3, T4>(_ matcher0: MatcherType<T0>,
                                      _ matcher1: MatcherType<T1>,
                                      _ matcher2: MatcherType<T2>,
                                      _ matcher3: MatcherType<T3>,
                                      _ matcher4: MatcherType<T4>) -> MatcherType<(T0, T1, T2, T3, T4)> {
        .custom({ matcher0.match($0.0) && matcher1.match($0.1) && matcher2.match($0.2) && matcher3.match($0.3) && matcher4.match($0.4) })
    }

    static func split<T0, T1, T2, T3, T4, T5>(_ matcher0: MatcherType<T0>,
                                      _ matcher1: MatcherType<T1>,
                                      _ matcher2: MatcherType<T2>,
                                      _ matcher3: MatcherType<T3>,
                                      _ matcher4: MatcherType<T4>,
                                      _ matcher5: MatcherType<T5>) -> MatcherType<(T0, T1, T2, T3, T4, T5)> {
        .custom({ matcher0.match($0.0) && matcher1.match($0.1) && matcher2.match($0.2) && matcher3.match($0.3) && matcher4.match($0.4) && matcher5.match($0.5) })
    }
}


// MARK: Equatable

public extension MatcherType where Args: Equatable {
    static func value(_ value: Args) -> MatcherType<Args> {
        .custom({ $0 == value })
    }
    
    static func notValue(_ value: Args) -> MatcherType<Args> {
        .custom({ $0 != value })
    }
}


// MARK: Comparable

public extension MatcherType where Args: Comparable {
    static func ge(_ value: Args) -> MatcherType<Args> {
        .custom({ $0 >= value })
    }
    
    static func gt(_ value: Args) -> MatcherType<Args> {
        .custom({ $0 > value })
    }
    
    static func le(_ value: Args) -> MatcherType<Args> {
        .custom({ $0 <= value })
    }
    
    static func lt(_ value: Args) -> MatcherType<Args> {
        .custom({ $0 < value })
    }
}


// MARK: Bool

public extension MatcherType where Args == Bool {
    static func isTrue() -> MatcherType<Args> {
        .custom({ $0 == true })
    }
    
    static func isFalse() -> MatcherType<Args> {
        .custom({ $0 == false })
    }
}


// MARK: String

public extension MatcherType where Args == String {
    static func caseEq<S: StringProtocol>(_ str: S) -> MatcherType<Args> {
        .custom({ $0.compare(str, options: .caseInsensitive) == .orderedSame })
    }
    
    static func caseNe<S: StringProtocol>(_ str: S) -> MatcherType<Args> {
        .custom({ $0.compare(str, options: .caseInsensitive) != .orderedSame })
    }
}


// MARK: - Collection

public extension MatcherType where Args: Collection, Args.Element: Equatable {
    static func contains(_ element: Args.Element) -> MatcherType<Args> {
        .custom({ $0.contains(element) })
    }
    
    static func containsAllOf<C>(_ subset: C) -> MatcherType<Args> where C: Collection, C.Element == Args.Element {
        .custom({ collection in subset.reduce(true) { $0 && collection.contains($1) } })
    }
    
    static func containsAnyOf<C>(_ subset: C) -> MatcherType<Args> where C: Collection, C.Element == Args.Element {
        .custom({ collection in subset.reduce(false) { $0 || collection.contains($1) } })
    }
    
    static func startsWith<C>(_ prefix: C) -> MatcherType<Args> where C: Collection, C.Element == Args.Element {
        .custom({ $0.starts(with: prefix) })
    }
    
    static func endsWith<C>(_ suffix: C) -> MatcherType<Args> where C: Collection, C.Element == Args.Element {
        .custom({
            guard $0.count < suffix.count else { return false }
            return $0.dropFirst($0.count - suffix.count).elementsEqual(suffix)
        })
    }
}

public extension MatcherType where Args: Collection {
    static func isEmpty<Args>() -> MatcherType<Args> where Args: Collection {
        .custom({ $0.isEmpty })
    }
    
    static func sizeIs<Args>(_ size: Int) -> MatcherType<Args> where Args: Collection {
        .custom({ $0.count == size })
    }
    
    static func each<Args>(_ matcher: @escaping Matcher<Args.Element>) -> MatcherType<Args> where Args: Collection {
        .custom({ $0.reduce(true) { $0 && matcher($1) } })
    }
    
    static func atLeastOne<Args>(_ matcher: @escaping Matcher<Args.Element>) -> MatcherType<Args> where Args: Collection {
        .custom({ $0.reduce(false) { $0 || matcher($1) } })
    }
}


// MARK: Element in Collection

public extension MatcherType where Args: Equatable {
    static func inCollection<C: Collection>(_ collection: C) -> MatcherType<Args> where Args == C.Element {
        .custom({ collection.contains($0) })
    }
}
