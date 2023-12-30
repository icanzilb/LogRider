//
//  NSMutableAttributedString.swift
//  Tile
//
//  Created by Marin Todorov on 3/26/23.
//

import Foundation
import Cocoa

extension NSString {
    func matchesCount(_ needle: String) -> Int {
        let inputLength = self.length
        var range = NSRange(location: 0, length: self.length)
        var matches = 0
        while (range.location != NSNotFound) {
            range = self.range(of: needle, options: [.caseInsensitive], range: range)
            if (range.location != NSNotFound) {
                range = NSRange(location: range.location + range.length, length: inputLength - (range.location + range.length))
                matches += 1
            }
        }

        return matches
    }
}

extension NSMutableAttributedString {
    func setBackgroundFor(_ textToFind: String, with color: NSColor) -> Int {
        let inputLength = self.string.count
        let searchLength = textToFind.count
        var range = NSRange(location: 0, length: self.length)

        var matches = 0

        while (range.location != NSNotFound) {
            range = (self.string as NSString).range(of: textToFind, options: [.caseInsensitive], range: range)
            if (range.location != NSNotFound) {
                self.addAttribute(.backgroundColor, value: color, range: NSRange(location: range.location, length: searchLength))
                range = NSRange(location: range.location + range.length, length: inputLength - (range.location + range.length))
                matches += 1
            }
        }

        return matches
    }
}
