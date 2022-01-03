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

import sMock
import XCTest

class MatcherTests: XCTestCase {
    func test_allOf() {
        let mTrue = Matcher<Int> { _ in true }
        let mFalse = Matcher<Int> { _ in false }
        
        XCTAssertTrue(Matcher<Int>.allOf(mTrue)(10))
        XCTAssertFalse(Matcher<Int>.allOf(mFalse)(10))
        
        XCTAssertTrue(Matcher<Int>.allOf(mTrue, mTrue)(10))
        XCTAssertFalse(Matcher<Int>.allOf(mTrue, mFalse)(10))
        XCTAssertFalse(Matcher<Int>.allOf(mFalse, mFalse)(10))
    }
    
    func test_anyOf() {
        let mTrue = Matcher<Int> { _ in true }
        let mFalse = Matcher<Int> { _ in false }
        
        XCTAssertTrue(Matcher<Int>.anyOf(mTrue)(10))
        XCTAssertFalse(Matcher<Int>.anyOf(mFalse)(10))
        
        XCTAssertTrue(Matcher<Int>.anyOf(mTrue, mTrue)(10))
        XCTAssertTrue(Matcher<Int>.anyOf(mTrue, mFalse)(10))
        XCTAssertFalse(Matcher<Int>.anyOf(mFalse, mFalse)(10))
        
        sMock.waitForExpectations()
    }
}
