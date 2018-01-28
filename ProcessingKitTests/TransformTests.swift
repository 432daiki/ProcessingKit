//
//  TransformTests.swift
//  ProcessingKitTests
//
//  Created by AtsuyaSato on 2018/01/14.
//  Copyright © 2018年 Atsuya Sato. All rights reserved.
//

import XCTest
@testable import ProcessingKit

/* Quartz 2D
 https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_affine/dq_affine.html

                       | a  b  0 |
 [x' y' 1] = [x y 1] × | c  d  0 |
                       | tx ty 1 |

 y
 ^
 |
 |
 0ーーーー> x
 */

enum Transform {
    case translate(x: CGFloat, y: CGFloat)
    case rotate(angle: CGFloat)
}

class ProcessingViewDelegateTransformSpy: ProcessingViewDelegate {
    private let exception: XCTestExpectation
    private let view: ProcessingView
    private let transform: Transform
    private(set) var context: CGContext?

    init(exception: XCTestExpectation, view: ProcessingView, transform: Transform) {
        self.exception = exception
        self.view = view
        self.transform = transform
    }

    func setup() {
        switch transform {
        case .translate(let x, let y):
            self.view.translate(x, y)
        case .rotate(let angle):
            self.view.rotate(angle)
        }
        self.record(UIGraphicsGetCurrentContext())
        exception.fulfill()
    }

    private func record(_ arg: CGContext?) {
        self.context = arg
    }
}

class TransformTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testTranslate() {
        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                description: "Move 100pt to the right",
                transform: .translate(x: 100.0, y: 0.0),
                expect: CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 100.0, ty: 0.0)
            ),
            #line: TestCase(
                description: "Move 50pt to the bottom",
                transform: .translate(x: 0.0, y: 50.0),
                expect: CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: -50.0)
            ),
            #line: TestCase(
                description: "Move 40pt to the left, 20pt to the top",
                transform: .translate(x: -40.0, y: -20.0),
                expect: CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: -40.0, ty: 20.0)
            ),
        ]

        check(testCases: testCases)
    }

    func testRotate() {
        let radians = { (angle: CGFloat) -> CGFloat in
            return .pi * angle / 360
        }

        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                description: "Rotate by 90 degrees",
                transform: .rotate(angle: radians(90)),
                expect: CGAffineTransform(a: cos(radians(90)), b: -sin(radians(90)), c: sin(radians(90)), d: cos(radians(90)), tx: 0.0, ty: 0.0)
            ),
            #line: TestCase(
                description: "Rotate by 360 degrees",
                transform: .rotate(angle: radians(360)),
                expect: CGAffineTransform(a: cos(radians(360)), b: -sin(radians(360)), c: sin(radians(360)), d: cos(radians(360)), tx: 0.0, ty: 0.0)
            ),
            #line: TestCase(
                description: "Rotate by -90 degrees",
                transform: .rotate(angle: radians(-90)),
                expect: CGAffineTransform(a: cos(radians(-90)), b: -sin(radians(-90)), c: sin(radians(-90)), d: cos(radians(-90)), tx: 0.0, ty: 0.0)
            ),
        ]

        check(testCases: testCases)
    }

    func check(testCases: [UInt: TestCase]) {
        _ = testCases.map { (line, testCase) in
            let view = ProcessingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

            let transformDelegateSpy = ProcessingViewDelegateTransformSpy(
                exception: expectation(description: testCase.description),
                view: view,
                transform: testCase.transform
            )

            view.delegate = transformDelegateSpy
            waitForExpectations(timeout: 100)

            let actual = transformDelegateSpy.context?.ctm

            switch testCase.transform {
            // Multiply translate(0.0, 100.0), scale(1.0, -1.0) and expect together for coordinate system
            case .translate(_, _):
                let expected = CGAffineTransform(a: 1.0, b: 0.0, c: -0.0, d: -1.0, tx: 0.0, ty: 100.0).concatenating(testCase.expect)
                XCTAssertEqual(actual, expected, String(line))
            case .rotate(_):
                let expected = CGAffineTransform(a: 1.0, b: 0.0, c: -0.0, d: -1.0, tx: 0.0, ty: 0.0).concatenating(testCase.expect.concatenating(CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 100.0)))
                XCTAssertEqual(actual, expected, String(line))
            }
        }
    }

    struct TestCase {
        let description: String
        let transform: Transform
        let expect: CGAffineTransform

        init(
            description: String,
            transform: Transform,
            expect: CGAffineTransform
            ) {
            self.description = description
            self.transform = transform
            self.expect = expect
        }
    }
}
