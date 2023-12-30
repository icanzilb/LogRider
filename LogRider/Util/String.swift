//
//  String.swift
//  Tile
//
//  Created by Marin Todorov on 11/2/22.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

extension String {
    func escapedQuotes() -> String {
        return replacingOccurrences(of: "\"", with: "\\\"")
    }

    func escapedSpaces() -> String {
        return replacingOccurrences(of: " ", with: "\\ ")
    }

    func upToLength(_ max: Int) -> String {
        if count > max {
            return String(prefix(max)).appending("...")
        } else {
            return self
        }
    }

    var quoted: String { return "'\(self)'" }
    var doubleQuoted: String { return "\"\(self)\"" }

    func count(of needle: Character) -> Int {
        return reduce(0) {
            $1 == needle ? $0 + 1 : $0
        }
    }
}

extension String {
    func symbolName() -> String? {
        guard hasPrefix("$symbol("), hasSuffix(")") else { return nil }
        let start = index(startIndex, offsetBy: 8)
        let end = index(before: endIndex)
        return String(self[start..<end])
    }
}
