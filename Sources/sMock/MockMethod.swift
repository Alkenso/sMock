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


public class MockMethod<Args, R>: MockFunction<Args, R> {
    public init() { }
    
    /// Should be called inside mocked method implementation.
    public func call(_ args: Args, functionName: String = #function) -> R? {
        evaluate(args, functionName)
    }
    
    /// Should be called inside mocked method implementation.
    public func callT(_ args: Args, functionName: String = #function) throws -> R? {
        try evaluateT(args, functionName)
    }
}

public extension MockMethod where Args == Void {
    /// Should be called inside mocked method implementation.
    func call(functionName: String = #function) -> R? {
        call((), functionName: functionName)
    }
}

public extension MockMethod {
    /// Should be called inside mocked method implementation.
    func call<T0, T1>(_ arg0: T0, _ arg1: T1, functionName: String = #function) -> R? where Args == (T0, T1) {
        call((arg0, arg1), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2>(_ arg0: T0, _ arg1: T1, _ arg2: T2, functionName: String = #function) -> R? where Args == (T0, T1, T2) {
        call((arg0, arg1, arg2), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2, T3>(_ arg0: T0, _ arg1: T1, _ arg2: T2, _ arg3: T3, functionName: String = #function) -> R? where Args == (T0, T1, T2, T3) {
        call((arg0, arg1, arg2, arg3), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2, T3, T4>(_ arg0: T0, _ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, functionName: String = #function) -> R? where Args == (T0, T1, T2, T3, T4) {
        call((arg0, arg1, arg2, arg3, arg4), functionName: functionName)
    }
    
    /// Should be called inside mocked method implementation.
    func call<T0, T1, T2, T3, T4, T5>(_ arg0: T0, _ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, _ arg5: T5, functionName: String = #function) -> R? where Args == (T0, T1, T2, T3, T4, T5) {
        call((arg0, arg1, arg2, arg3, arg4, arg5), functionName: functionName)
    }
}
