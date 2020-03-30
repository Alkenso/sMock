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


public class MockClosure<Args, R>: MockFunction<Args, R> {
    private let closureName: String
    private let returnOnFail: R
    
    
    public init(_ closureName: String = "Anonymous closure.", returnOnFail: R) {
        self.closureName = closureName
        self.returnOnFail = returnOnFail
    }
}

public extension MockClosure where R == Void {
    convenience init(_ closureName: String = "Anonymous closure.") {
        self.init(closureName, returnOnFail: ())
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
