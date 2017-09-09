//
//  Text.swift
//  ProcessingKit
//
//  Created by AtsuyaSato on 2017/08/13.
//  Copyright © 2017年 Atsuya Sato. All rights reserved.
//

import Foundation

class TextComponents {
    var textSize: CGFloat = 20.0
    var textFont: UIFont = UIFont.systemFont(ofSize: 20.0)
    var textAlignX: NSTextAlignment = .left
}

protocol TextModelContractor {
    func text(_ str: String, _ x: CGFloat, _ y: CGFloat)
    func text(_ str: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat)
    func textWidth(_ str: String) -> CGFloat
    mutating func textSize(_ size: CGFloat)
    mutating func textFont(_ font: UIFont)
    mutating func textAlign(_ allignX: NSTextAlignment)
}

struct TextModel: TextModelContractor {
    private var textComponents: TextComponents
    private var colorComponents: ColorComponents
    private var processingView: ProcessingView

    init(processingView: ProcessingView, textComponents: TextComponents, colorComponents: ColorComponents) {
        self.processingView = processingView
        self.textComponents = textComponents
        self.colorComponents = colorComponents
    }

    func text(_ str: String, _ x: CGFloat, _ y: CGFloat) {
        let width = self.textWidth(str)
        let height = str.height(withConstrainedWidth: width, font: self.textComponents.textFont)
        if self.textComponents.textAlignX == .center {
            self.text(str, x - width / 2, y, width, height)
            return
        }
        self.text(str, x, y, width, height)
    }

    func text(_ str: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        let g = UIGraphicsGetCurrentContext()

        g?.saveGState()

        g?.translateBy(x: 0, y: self.processingView.frame.size.height)
        g?.scaleBy(x: 1.0, y: -1.0)
        g?.textMatrix = CGAffineTransform.identity

        let path: CGMutablePath = CGMutablePath()
        let bounds: CGRect = CGRect(x: x, y: -y + self.processingView.frame.size.height, width: width, height: height)
        path.addRect(bounds)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.textComponents.textAlignX

        let attributes: [String : Any] = [NSParagraphStyleAttributeName: paragraph]

        let attrString = NSMutableAttributedString(string: str, attributes: attributes)

        // set font
        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, attrString.length), kCTFontAttributeName, self.textComponents.textFont)

        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, attrString.length), kCTForegroundColorAttributeName, self.colorComponents.fill.cgColor)

        let framesetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attrString)

        let frame: CTFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)

        // 上記の内容を描画します。
        CTFrameDraw(frame, g!)

        g?.restoreGState()
    }

    func textWidth(_ str: String) -> CGFloat {
        let size = str.size(attributes: [NSFontAttributeName : self.textComponents.textFont])
        return size.width
    }

    mutating func textSize(_ size: CGFloat) {
        self.textComponents.textSize = size
        self.textComponents.textFont = UIFont.systemFont(ofSize: size)
    }

    mutating func textFont(_ font: UIFont) {
        self.textComponents.textFont = font
        self.textComponents.textSize = font.pointSize
    }

    mutating func textAlign(_ allignX: NSTextAlignment) {
        self.textComponents.textAlignX = allignX
    }
}

extension ProcessingView: TextModelContractor {
    public func text(_ str: String, _ x: CGFloat, _ y: CGFloat) {
        self.textModel.text(str, x, y)
    }

    public func text(_ str: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        self.textModel.text(str, x, y, width, height)
    }

    public func textWidth(_ str: String) -> CGFloat {
        return self.textModel.textWidth(str)
    }

    public func textSize(_ size: CGFloat) {
        self.textModel.textSize(size)
    }

    public func textFont(_ font: UIFont) {
        self.textModel.textFont(font)
    }

    public func textAlign(_ allignX: NSTextAlignment) {
        self.textModel.textAlign(allignX)
    }
}
