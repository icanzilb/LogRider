//
//  ConsoleFilter.swift
//  dataFude for Simulator
//
//  Created by Marin Todorov on 4/14/23.
//

import Foundation

enum ConsoleFilter {
    case search(String)
    case filter(String)
    case beep(String)

    var text: String {
        switch self {
        case .search(let text): return text
        case .filter(let text): return text
        case .beep(let text): return text
        }
    }

    var help: String {
        switch self {
        case .search: return "Search"
        case .filter: return "Filter"
        case .beep: return "Sound"
        }
    }

    mutating func updateText(_ text: String) {
        switch self {
        case .search: self = .search(text)
        case .filter: self = .filter(text)
        case .beep: self = .beep(text)
        }
    }
}
