//
//  NewProcess.swift
//  Tile
//
//  Created by Marin Todorov on 11/3/22.
//

import Foundation
import SwiftUI
import Combine

struct NewProcessView: View {
    @StateObject private var model: ProcessesModel
    @State var instructionsVisible = true
    @State var matches = [String]()

    @Environment(\.dismiss) var dismiss

    let onSelectSource: (String) -> Void

    init(preferences: PreferencesModel, onSelectSource: @escaping (String) -> Void) {
        _model = StateObject(
            wrappedValue: ProcessesModel(preferences: preferences)
        )
        self.onSelectSource = onSelectSource
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("App Name")

                SuggestionInput(
                    text: self.$model.query,
                    suggestionGroups: self.model.suggestionGroups,
                    didConfirmSelection: { text in
                        submit()
                    }
                )
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                DispatchQueue.main.async {
                    if let fileURL = try? FileStreamInputProvider.selectLogFile() {
                        NewProcessView.openNewProcessWithName(fileURL.path)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .symbolRenderingMode(.palette)
                        .foregroundColor(.blue)
                        .font(.body)

                    Text("Watch log file")
                }
                .font(.body)
                .padding(.vertical, 0)
            }
            .padding(.top)
            .offset(x: 2)
            .buttonStyle(.plain)


            if instructionsVisible || matches.isEmpty {
                Text("Write App Name")
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.callout.bold())
                    .foregroundColor(Color.controlOuterSelection)
                    .transition(.slide)
                    .padding(.top, 16)

            }

            Spacer()

            HStack(spacing: 20) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Cancel").frame(width: 80)
                })
                .keyboardShortcut(.escape)

                Button(action: {
                    submit()
                }, label: {
                    Text("Create").frame(width: 80)
                })
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .opacity(model.query.isEmpty ? 0.8 : 1.0)
                .allowsHitTesting(!model.query.isEmpty)
            }
        }
        .padding()
        .background(Color.controlBackground)
    }

    func submit() {
        guard !model.query.isEmpty else { return }
        dismiss()

        DispatchQueue.main.async {
            Self.openNewProcessWithName(model.query)
        }
    }

    static let openingTile = Synchronized<Bool>(false)

    static func openNewProcessWithName(_ processName: String) {
        print("Watching '\(processName)'")

    }
}

struct RecentList: View {
    @EnvironmentObject var preferences: PreferencesModel

    func recentItems(_ items: [RecentItem]) -> [RecentItem] {
        return items
    }

    var body: some View {
        if !preferences.recent.isEmpty {
            Menu("Recent") {
                ForEach(recentItems(preferences.recent)) { item in
                    RecentItemView(name: item.name, isRunning: true, showIcon: true) { processName in
                        NewProcessView.openNewProcessWithName(processName)

                        DispatchQueue.main.async {
                            NSApplication.shared.closeWindows(withTitlePrefix: "Welcome")
                        }
                    }
                    .transition(.slide)
                }
                Divider()
                Button("Clear Menu") {
                    self.preferences.clearRecentItems()
                }
            }
        }
    }
}

struct ProcessCommands: Commands {
    private let preferences: PreferencesModel

    init(preferences: PreferencesModel) {
        self.preferences = preferences
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button {
                //openAppWindow(id: NewScene.id)
            } label: {
                Label("Add App", systemImage: "plus")
            }
            .keyboardShortcut("N", modifiers: [.command])

            Button {
                if let fileURL = try? FileStreamInputProvider.selectLogFile() {
                    NewProcessView.openNewProcessWithName(fileURL.path)
                }
            } label: {
                Label("Add File", systemImage: "plus")
            }
            .keyboardShortcut("N", modifiers: [.command, .shift])

            RecentList()
                .environmentObject(preferences)
        }
    }
}
