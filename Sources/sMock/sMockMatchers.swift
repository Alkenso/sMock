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

public enum TupleMatcher<Arg> {
    case any
    case matcher(Matcher<Arg>)
    
    fileprivate func match(_ arg: Arg) -> Bool {
        switch self {
        case .any:
            return true
        case .matcher(let matcher):
            return matcher(arg)
        }
    }
}

public func AllOf<T0, T1>(_ matcher0: TupleMatcher<T0>, _ matcher1: TupleMatcher<T1>) -> Matcher<(T0, T1)> {
    return { matcher0.match($0.0) && matcher1.match($0.1) }
}

public func AllOf<T0, T1, T2>(_ matcher0: TupleMatcher<T0>, _ matcher1: TupleMatcher<T1>, _ matcher2: TupleMatcher<T2>) -> Matcher<(T0, T1, T2)> {
    return { matcher0.match($0.0) && matcher1.match($0.1) && matcher2.match($0.2) }
}


// MARK: - Equatable

public func Eq<Args>(_ args: Args) -> Matcher<Args> where Args: Equatable {
    return { $0 == args }
}

public func Ne<Args>(_ args: Args) -> Matcher<Args> where Args: Equatable {
    return { $0 != args }
}


// MARK: - Comparable

public func Ge<Args>(_ args: Args) -> Matcher<Args> where Args: Comparable {
    return { $0 >= args }
}

public func Gt<Args>(_ args: Args) -> Matcher<Args> where Args: Comparable {
    return { $0 > args }
}

public func Le<Args>(_ args: Args) -> Matcher<Args> where Args: Comparable {
    return { $0 <= args }
}

public func Lt<Args>(_ args: Args) -> Matcher<Args> where Args: Comparable {
    return { $0 < args }
}


// MARK: - Bool

public func IsFalse() -> Matcher<Bool> {
    return { $0 == false }
}

public func IsTrue() -> Matcher<Bool> {
    return { $0 == true}
}


// MARK: - String

public func StrCaseEq<S: StringProtocol>(_ str: S) -> Matcher<String> {
    return { $0.compare(str, options: .caseInsensitive) == .orderedSame }
}

public func StrCaseNe<S: StringProtocol>(_ str: S) -> Matcher<String> {
    return { $0.compare(str, options: .caseInsensitive) != .orderedSame }
}


// MARK: - Collection

public func Contains<Args>(_ element: Args.Element) -> Matcher<Args> where Args: Collection, Args.Element: Equatable {
    return { $0.contains(element) }
}

public func Contains<Args>(_ subset: [Args.Element]) -> Matcher<Args> where Args: Collection, Args.Element: Equatable {
    return { c in subset.reduce(true) { $0 && c.contains($1) } }
}

public func StartsWith<Args>(_ prefix: [Args.Element]) -> Matcher<Args> where Args: Collection, Args.Element: Equatable {
    return { $0.starts(with: prefix) }
}

public func EndsWith<Args>(_ suffix: [Args.Element]) -> Matcher<Args> where Args: Collection, Args.Element: Equatable {
    return {
        guard $0.count < suffix.count else { return false }
        return $0.dropFirst($0.count - suffix.count).elementsEqual(suffix)
    }
}

public func IsEmpty<Args>() -> Matcher<Args> where Args: Collection {
    return { $0.isEmpty }
}

public func SizeIs<Args>(_ size: Int) -> Matcher<Args> where Args: Collection {
    return { $0.count == size }
}

public func Each<Args>(_ matcher: @escaping Matcher<Args.Element>) -> Matcher<Args> where Args: Collection {
    return { $0.reduce(true) { $0 && matcher($1) } }
}

public func AtLeastOne<Args>(_ matcher: @escaping Matcher<Args.Element>) -> Matcher<Args> where Args: Collection {
    return { $0.reduce(false) { $0 || matcher($1) } }
}


// MARK: - Element in Collection

public func ContainedByCollection<C: Collection>(_ collection: C) -> Matcher<C.Element> where C.Element: Equatable {
    return { (element: C.Element) in collection.contains(element) }
}


// MARK: - Optional

public func IsNil<PureArgs>() -> Matcher<Optional<PureArgs>> {
    return { $0 == nil}
}

public func NotNil<PureArgs>() -> Matcher<Optional<PureArgs>> {
    return { $0 != nil}
}
