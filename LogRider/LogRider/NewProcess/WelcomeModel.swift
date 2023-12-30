//
//  WelcomeModel.swift
//  Tile
//
//  Created by Marin Todorov on 1/1/23.
//

import Foundation
import SwiftUI

struct RecentProcess: Identifiable, Codable {
    var id: String { name }
    var name: String
    var lastOpened: Date = .distantPast
}

class WelcomeModel: ObservableObject {
    @Published var message = ""

    @Published var recentProcesses: [RecentProcess] = []
    @Published var installedApps: [InstalledApp] = []
    @Published var simulatorConnectionFailed = false

    var runningIdentifiersBlob = ""
    @Published var isLoading = false

    var allApps = [InstalledApp]() {
        didSet {
            updateInstalledApps()
        }
    }

    @Published var sandboxError: SandboxError?

    func updateInstalledApps() {
        guard !runningIdentifiersBlob.isEmpty else {
            installedApps = allApps.reversed()
            return
        }

        var sortedApps = allApps

        for i in 0 ..< sortedApps.count {
            sortedApps[i].isRunning = runningIdentifiersBlob.contains(sortedApps[i].identifier)
        }

        sortedApps.sort { app1, app2 in
            return app1.isRunning
        }

        DispatchQueue.main.async {
            withAnimation(.easeIn) {
                self.installedApps = sortedApps
            }
        }
    }

    func load(preferences: PreferencesModel, includingSimulatorApps: Bool) {
        isLoading = includingSimulatorApps
        simulatorConnectionFailed = false

        recentProcesses = preferences.recent.map {
            RecentProcess(name: $0.name)
        }
    }
}
