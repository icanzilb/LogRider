//
//  RecentItem.swift
//  Tile
//
//  Created by Marin Todorov on 3/2/23.
//

import Foundation

struct RecentItem: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case processName, file
    }

    var id: String { name }
    let name: String
    var lastOpened: Date
    let kind: Kind

    static func kindFromName(_ name: String) -> Kind {
        return name.hasPrefix("/") ? .file : .processName
    }
}

private let maxRecentItems = 10

extension PreferencesModel {
    func addRecentItem(name: String) {
        if let index = recent.firstIndex(where: { $0.name == name }) {
            // Existing item
            var item = recent.remove(at: index)
            item.lastOpened = Date()
            recent.insert(item, at: 0)
        } else {
            // New item
            let item = RecentItem(name: name, lastOpened: Date(), kind: RecentItem.kindFromName(name))
            recent.insert(item, at: 0)
            prune()
        }
    }

    func prune() {
        if recent.count > maxRecentItems {
            recent = Array(recent.prefix(maxRecentItems))
        }
    }

    func clearRecentItems() {
        recent.removeAll()
    }
}
