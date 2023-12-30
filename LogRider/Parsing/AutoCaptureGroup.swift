//
//  AutoCaptureGroup.swift
//  Tile
//
//  Created by Marin Todorov on 10/29/22.
//

import Foundation

struct AutoCaptureGroup: Codable, Identifiable {
    var id: String
    var regex: String
    var name: String
    var description: String
    var examples: [String]
    var displayText: String

    var isEnabled = false

    enum TokenType: String, Codable {
        case value, heading
    }
    var tokenTypes: [TokenType]

    func displayRegex(withMatch match: NSTextCheckingResult, in string: String) -> (displayText: String, headline: String)? {
        var displayRegex = regex
        let parser = RegexParser(pattern: regex)
        var headline = ""

        for rangeIndex in 1 ..< match.numberOfRanges {
            guard rangeIndex-1 < tokenTypes.count && tokenTypes[rangeIndex-1] == .heading else {
                continue
            }
            guard rangeIndex < parser.ranges.count else {
                continue
            }

            let groupPattern = regex[parser.ranges[rangeIndex]]
            let matchedHeadline = (string as NSString).substring(with: match.range(at: rangeIndex))

            if let replaceRange: Range<String.Index> = displayRegex.range(of: groupPattern) {
                displayRegex = displayRegex.replacingCharacters(in: replaceRange, with: matchedHeadline)
            }

            headline = matchedHeadline

            return (displayText: displayRegex, headline: headline)
        }

        return nil
    }
}
