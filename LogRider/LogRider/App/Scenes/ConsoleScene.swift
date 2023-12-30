//
//  ConsoleScene.swift
//  Tile
//
//  Created by Marin Todorov on 3/25/23.
//

import Foundation
import SwiftUI

struct ConsoleArguments: Codable, Hashable {
    let processName: String

    var options: [Option: String] = [:]

    enum Option: String, Codable {
        case buildDirectory
        case subsystem
    }
}

struct ConsoleScene: Scene {
    static let id = "console"
    static let title = "Console"

    let preferences: PreferencesModel
    let arguments = ConsoleArguments(processName: "Test")

    var body: some Scene {
        WindowGroup(ConsoleScene.title, id: ConsoleScene.id) {
            ConsoleWindow(arguments: arguments)
                .onAppear {
                    print()
                }
                .frame(minWidth: 600, minHeight: 380)
                .environmentObject(preferences)
                .environmentObject(AlertQueue.shared)
        }
        .contentResizable()
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))

        // URL path
        .handlesExternalEvents(matching: Set(arrayLiteral: Self.id))
    }
}
