//
//  SidebarModel.swift
//  Tile
//
//  Created by Marin Todorov on 4/23/23.
//

import Foundation
import SwiftUI
import Combine

enum SidebarItemType {
    case all
    case text, progress, timer, bool

    var text: String {
        switch self {
        case .all: return "All types"
        case .text: return "Text"
        case .bool: return "Toggle"
        case .progress: return "Progress"
        case .timer: return "Timer"
        }
    }

    func isTileType(_ tileType: TileType) -> Bool {
        switch self {
        case .all: return true
        case .text: return tileType == .text || tileType == .chart
        case .bool: return tileType == .toggle
        case .progress: return tileType == .progressCircular
        case .timer: return tileType == .intervalTimer
        }
    }
}

enum SidebarFilter {
    case search(String)
    case type(SidebarItemType)

    var text: String {
        switch self {
        case .search(let text): return text
        case .type(let type): return type.text
        }
    }

    var help: String {
        switch self {
        case .search: return "Search"
        case .type: return "Type"
        }
    }

    mutating func updateText(_ text: String) {
        switch self {
        case .search: self = .search(text)
        case .type: break
        }
    }
}

class SidebarModel: ObservableObject {
    @Published var trackedValues = [ConsoleValueModel]() {
        didSet {
            print("Tracked values \(trackedValues.count)")
        }
    }
    @Published var displayTrackedValues = [ConsoleValueModel]()

    @Published var query: SidebarFilter = .search("")
    @Published var queryNote: String?

    private var subscriptions = [AnyCancellable]()

    init() {
        $trackedValues.eraseToAnyPublisher()
            .combineLatest($query.eraseToAnyPublisher())
            .throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.updateDisplayTrackedVariables()
            }
            .store(in: &subscriptions)
    }

    func clear() {
        trackedValues = []
        query.updateText("")
    }

    private func updateDisplayTrackedVariables() {
        guard !query.text.isEmpty else {
            displayTrackedValues = trackedValues
            queryNote = nil
            return
        }

        switch query {
        case .search(let queryText):
            let query = queryText.lowercased()

            self.displayTrackedValues = self.trackedValues.filter({ variable in
                return variable.name.lowercased().contains(query)
            })

        case .type(let type):
            self.displayTrackedValues = self.trackedValues.filter({ variable in
                return type.isTileType(variable.type)
            })
        }
    }
}

