//
//  CaptureRenderer.swift
//  Tile
//
//  Created by Marin Todorov on 10/29/22.
//

import Foundation
import Cocoa

let recognizedTokens: Set<String> = [
    "Text", "Text or number", "Boolean", "Intervals"
]

class CaptureRenderer {

    let text: String
    let model: TileModel?
    let isInteractive: Bool

    init(text: String, tileModel: TileModel?, isInteractive: Bool) {
        self.text = text
        self.model = tileModel
        self.isInteractive = isInteractive
    }

    let defaultAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.controlTextColor
    ]

    func attributedString() -> NSAttributedString {
        var text = self.text

        if let sourceMatch = model?.autoCaptureMatch,
           let autoCaptureGroup = model?.autoCapture,
           let headline = model?.autoCaptureHeadline {

            assert(autoCaptureGroup.tokenTypes.count == sourceMatch.numberOfRanges - 1)

            for groupIndex in 1 ..< sourceMatch.numberOfRanges where autoCaptureGroup.tokenTypes[groupIndex - 1] == .heading {
                text = text.replacingOccurrences(
                    of: "(.heading)",
                    with: headline
                )
                break
            }
        } else {
            text = text.replacingOccurrences(
                of: "(.heading)",
                with: "Some text"
            )
        }

        let cocoaText = text as NSString

        var openingIndex: Int? = nil
        var lastCopyIndex = 0
        let result = NSMutableAttributedString()

        var tokenAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: NSColor(named: "TokenText")!.withAlphaComponent(0.9),
            .backgroundColor: NSColor(named: "TokenBackground")!,
            .underlineColor: NSColor.clear,
            .font: NSFont.boldSystemFont(ofSize: NSFont.labelFontSize + 1),
            .cursor: NSCursor.arrow
        ]

        if isInteractive {
            assert(false, "No link support")
            tokenAttributes[.link] = "http://yahoo.com"
            tokenAttributes[.cursor] = NSCursor.pointingHand
        }

        for offset in 0 ..< cocoaText.length {
            let char = cocoaText.substring(with: .init(location: offset, length: 1))

            if openingIndex != nil {
                if char == "]" {
                    let tokenText = cocoaText.substring(with: NSRange(location: lastCopyIndex + 1, length: offset - lastCopyIndex - 1))

                    if recognizedTokens.contains(tokenText)  {
                        result.append(
                            NSAttributedString(
                                string: " "
                                    + cocoaText.substring(with: NSRange(location: lastCopyIndex + 1, length: offset - lastCopyIndex - 1))
                                    + " ",
                                attributes: tokenAttributes
                            )
                        )
                        lastCopyIndex = offset
                    }
                    
                    openingIndex = nil
                }
            } else {
                if char == "[" {
                    result.append(
                        NSAttributedString(
                            string: cocoaText.substring(with: NSRange(location: lastCopyIndex, length: offset - lastCopyIndex)),
                            attributes: defaultAttributes
                        )
                    )
                    lastCopyIndex = offset
                    openingIndex = offset
                }
            }
        }

        if lastCopyIndex < cocoaText.length - 1 {
            result.append(
                NSAttributedString(
                    string: cocoaText.substring(with: NSRange(location: lastCopyIndex + 1, length: cocoaText.length - lastCopyIndex - 1)),
                    attributes: defaultAttributes
                )
            )
        }

        return result
    }
}
