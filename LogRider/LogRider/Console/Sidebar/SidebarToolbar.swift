//
//  ConsoleToolbar.swift
//  Tile
//
//  Created by Marin Todorov on 3/25/23.
//

import Foundation
import SwiftUI

struct SidebarToolbar: View {
    @EnvironmentObject var preferences: PreferencesModel
    @ObservedObject var model: SidebarModel

    @State private var queryText = ""
    @State private var isFilteringByType = false

    init(model: SidebarModel) {
        _model = .init(wrappedValue: model)
    }

    var body: some View {
        HStack {

            HStack(alignment: .center, spacing: 2) {
                Menu {
                    Button {
                        model.query = .search("")
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                    }
                    Button {
                        model.query = .type(.all)
                    } label: {
                        HStack {
                            Image(systemName: "circle.grid.2x2")
                            Text("Type")
                        }
                    }
                } label: {
                    switch model.query {
                    case .search:
                        Image(systemName: "magnifyingglass")
                    case .type:
                        Image(systemName: "circle.grid.2x2")
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.visible)
                .controlSize(.regular)
                .frame(width: 32)
                .help(model.query.help)

                RoundedRectangle(cornerRadius: 5)
                    .stroke(isFilteringByType || !queryText.isEmpty ? .blue : .gray, lineWidth: 1)
                    .padding(.leading, 3)
                    .padding(.vertical, 5)
                    .overlay {

                        switch model.query {
                        case .search:
                            TextField("Value", text: $queryText)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 7)
                                .controlSize(.small)
                                .onChange(of: queryText) { newValue in
                                    model.query.updateText(newValue)
                                }
                        case .type:
                            Menu {
                                Button("All types", action: { model.query = .type(.all) })
                                Button("Text", action: { model.query = .type(.text) })
                                Button("Toggle", action: { model.query = .type(.bool) })
                                Button("Progress", action: { model.query = .type(.progress) })
                                Button("Timer", action: { model.query = .type(.timer) })
                            } label: {
                                Text(model.query.text)
                            }
                            .menuStyle(.borderlessButton)
                            .menuIndicator(.visible)
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                        }
                    }

                if let note = model.queryNote {
                    Text("\(note)")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.primary.opacity(0.9))
                        .padding(.leading, 2)
                }
            }
            .frame(width: 120, alignment: .leading)
            .padding(.leading, 6)

            Spacer()

            HStack {
                Text("\(model.displayTrackedValues.count) items")
                    .font(.callout.monospacedDigit())
                    .foregroundColor(.primary.opacity(0.9))

                ActivityMenuButton(
                    config: .consoleToolbar,
                    action: { _ in
                        //model.clear()
                        // sort the model here
                    },
                    imageName: "arrow.up.and.down.text.horizontal",
                    isAlternateState: .constant(false)
                )
                .help("Sort by most recent")


                ActivityMenuButton(
                    config: .consoleToolbar,
                    action: { _ in
                        model.clear()
                    },
                    imageName: "trash",
                    isAlternateState: .constant(false)
                )
                .opacity(model.trackedValues.isEmpty ? 0.5 : 1.0)
                .disabled(model.trackedValues.isEmpty)
                .help("Clear variables")
            }
            .padding(.trailing, 6)
        }
        .padding(.horizontal, 4)
        .frame(height: 28)
        .overlay(alignment: .top) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.1))
        }
        .onReceive(model.$query) { newValue in
            if case SidebarFilter.type(let item) = newValue {
                isFilteringByType = item != .all
            } else {
                isFilteringByType = false
            }
        }
    }
}
