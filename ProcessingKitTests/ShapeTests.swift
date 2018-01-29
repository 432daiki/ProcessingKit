//
//  ShapeTests.swift
//  ProcessingKitTests
//
//  Created by AtsuyaSato on 2018/01/29.
//  Copyright © 2018年 Atsuya Sato. All rights reserved.
//

import XCTest
@testable import ProcessingKit

enum Shape {
    case rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)
}

class ProcessingViewDelegateShapeSpy: ProcessingViewDelegate {
    private let exception: XCTestExpectation
    private let view: ProcessingView
    private let shape: Shape
    private(set) var context: CGContext?

    init(exception: XCTestExpectation, view: ProcessingView, shape: Shape) {
        self.exception = exception
        self.view = view
        self.shape = shape
    }

    func setup() {
        switch shape {
        case .rect(let x, let y, let width, let height):
            self.view.rect(x, y, width, height)
        }
        self.record(UIGraphicsGetCurrentContext())
        exception.fulfill()
    }

    private func record(_ arg: CGContext?) {
        self.context = arg
    }
}

extension UIBezierPath {
    open func moveTo(_ point: CGPoint) -> UIBezierPath {
        self.move(to: point)
        return self
    }
    open func addLineTo(_ point: CGPoint) -> UIBezierPath {
        self.addLine(to: point)
        return self
    }
    open func closePath() -> UIBezierPath {
        self.close()
        return self
    }
}

class ShapeTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testRect() {
        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                description: "draw rect(0, 0, 50, 50)",
                shape: .rect(x: 0, y: 0, width: 50, height: 50),
                expect: UIBezierPath()
                    .moveTo(CGPoint(x: 0, y: 0))
                    .addLineTo(CGPoint(x: 50, y: 0))
                    .addLineTo(CGPoint(x: 50, y: 50))
                    .addLineTo(CGPoint(x: 0, y: 50))
                    .closePath()
                    .cgPath
            ),
            #line: TestCase(
                description: "draw rect(20, 20, 30, 50)",
                shape: .rect(x: 20, y: 20, width: 30, height: 50),
                expect: UIBezierPath()
                    .moveTo(CGPoint(x: 20, y: 20))
                    .addLineTo(CGPoint(x: 50, y: 20))
                    .addLineTo(CGPoint(x: 50, y: 70))
                    .addLineTo(CGPoint(x: 20, y: 70))
                    .closePath()
                    .cgPath
            ),
        ]

        check(testCases: testCases)
    }

    func check(testCases: [UInt: TestCase]) {
        _ = testCases.map { (line, testCase) in
            let view = ProcessingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

            let transformDelegateSpy = ProcessingViewDelegateShapeSpy(
                exception: expectation(description: testCase.description),
                view: view,
                shape: testCase.shape
            )

            view.delegate = transformDelegateSpy
            waitForExpectations(timeout: 100)

            let actual = transformDelegateSpy.context?.path
            let expected = testCase.expect

            XCTAssertEqual(actual, expected, String(line))
        }
    }

    struct TestCase {
        let description: String
        let shape: Shape
        let expect: CGPath
    }
}
