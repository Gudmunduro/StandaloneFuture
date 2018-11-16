import XCTest

import StandaloneFutureTests

var tests = [XCTestCaseEntry]()
tests += StandaloneFutureTests.allTests()
XCTMain(tests)