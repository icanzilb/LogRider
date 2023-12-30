//
//  ProcessesModel.swift
//  Tile
//
//  Created by Marin Todorov on 3/20/23.
//

import Foundation
import Combine
import AppKit

final class ProcessesModel: ObservableObject {
    @Published var query: String = ""
    @Published var suggestionGroups: [SuggestionGroup<String>] = []

    private let preferences: PreferencesModel
    private var subscriptions: Set<AnyCancellable> = []
    private let welcomeModel = WelcomeModel()

    init(preferences: PreferencesModel) {
        self.preferences = preferences
        
        #if PRO
        self.welcomeModel.load(preferences: preferences, includingSimulatorApps: true)
        #endif
        #if MAX
        self.welcomeModel.load(preferences: preferences, includingSimulatorApps: false)
        #endif

        self.$query
            //.debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { processName -> [SuggestionGroup<String>] in
                let needle = processName.lowercased()

                var result = [SuggestionGroup<String>]()

                // Recents
                let recents = self.welcomeModel.recentProcesses.filter({
                    $0.name.lowercased().hasPrefix(needle)
                }).reduce(into: [String: String]()) { results, process in
                    results[process.name.lowercased()] = process.name
                }

                if !recents.isEmpty {
                    result.append(
                        SuggestionGroup(
                            title: "Recent apps (\(recents.count))",
                            suggestions: recents.keys.sorted().map({
                                Suggestion(text: recents[$0]!, value: $0)
                            })
                        )
                    )
                }

                #if MAX
                // Running apps
                var apps = [String: String]()

                for name in NSWorkspace.shared.runningApplications
                    .map(\.executableURL)
                    .compactMap({
                        $0?.lastPathComponent
                    }) {
                    let lowName = name.lowercased()
                    if lowName.hasPrefix(needle) && !recents.keys.contains(name.lowercased()) {
                        apps[lowName] = name
                    }
                }

                if !apps.isEmpty {
                    result.append(
                        SuggestionGroup(
                            title: "Running apps (\(apps.count))",
                            suggestions: apps.keys.sorted().map({
                                Suggestion(text: apps[$0]!, value: $0)
                            })
                        )
                    )
                }
                #endif

                #if PRO
                // Installed processes
                let installed = self.welcomeModel.installedApps.filter({
                    $0.executableName.lowercased().hasPrefix(needle)
                }).reduce(into: [String: String]()) { results, process in
                    results[process.executableName.lowercased()] = process.executableName
                }

                if !installed.isEmpty {
                    result.append(
                        SuggestionGroup(
                            title: "Simulator apps (\(installed.count))",
                            suggestions: installed.keys.sorted().map({
                                Suggestion(text: installed[$0]!, value: $0)
                            })
                        )
                    )
                }
                #endif

                return result
            }
            .assign(to: \Self.suggestionGroups, on: self)
            .store(in: &subscriptions)
    }
}
