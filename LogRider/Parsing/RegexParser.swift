//
//  RegexParser.swift
//  Tile
//
//  Created by Marin Todorov on 10/28/22.
//

import Foundation

class RegexParser {
    let ranges: [Range<String.Index>]
    let nsRanges: [NSRange]

    init(pattern: String) {
        var ranges = [Range<String.Index>]()
        var lastChar = Character(" ")
        var openRangesLowerBounds = [String.Index]()

        var index = pattern.startIndex
        while index < pattern.endIndex {
            let char = pattern[index]
            defer {
                lastChar = char
                index = pattern.index(after: index)
            }
            
            // Open a new capture group
            if char == "(" && lastChar != "\\" {
                openRangesLowerBounds.append(index)
            }

            // Revert open group if first char is ?
            if char == "?" && lastChar == "(" {
                openRangesLowerBounds.removeLast()
            }

            // Close the last capture group
            if !openRangesLowerBounds.isEmpty && char == ")" && lastChar != "\\" {
                ranges.append(openRangesLowerBounds.removeLast()..<pattern.index(after: index))
            }
        }

        self.ranges = ranges
        self.nsRanges = ranges.map {
            NSRange($0, in: pattern)
        }
    }
}
