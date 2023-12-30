//
//  ConsoleToolbar.swift
//  Tile
//
//  Created by Marin Todorov on 3/25/23.
//

import Foundation
import SwiftUI

struct ConsoleToolbar: View {
    @EnvironmentObject var preferences: PreferencesModel
    @ObservedObject var model: ConsoleModel

    @State private var queryText = ""
    @State private var isCopying = false

    init(model: ConsoleModel) {
        _model = .init(wrappedValue: model)
    }

    var body: some View {
        HStack {

            HStack(alignment: .center, spacing: 2) {
                Menu {
                    Button {
                        model.query = .search(model.query.text)
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                    }
                    Button {
                        model.query = .filter(model.query.text)
                    } label: {
                        HStack {
                            Image(systemName: "trapezoid.and.line.horizontal")
                            Text("Filter")
                        }
                    }
                    Button {
                        model.query = .beep(model.query.text)
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Sound")
                        }
                    }
                } label: {
                    switch model.query {
                    case .search:
                        Image(systemName: "magnifyingglass")
                    case .filter:
                        Image(systemName: "trapezoid.and.line.horizontal")
                    case .beep:
                        Image(systemName: "music.note")
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.visible)
                .controlSize(.regular)
                .frame(width: 32)
                .help(model.query.help)

                RoundedRectangle(cornerRadius: 5)
                    .stroke(.gray, lineWidth: 1)
                    .padding(.leading, 3)
                    .padding(.vertical, 5)
                    .overlay {
                        TextField("Value", text: $queryText)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 7)
                            .controlSize(.small)
                            .onChange(of: queryText) { newValue in
                                model.query.updateText(newValue)
                            }
                    }

                if let note = model.queryNote {
                    Text("\(note)")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.primary.opacity(0.9))
                        .padding(.leading, 2)
                }
            }
            .frame(width: 200, alignment: .leading)
            .padding(.leading, 6)

            Spacer()

            HStack {
                Text("\(model.text.count(of: "\n")) lines")
                    .font(.callout.monospacedDigit())
                    .foregroundColor(.primary.opacity(0.9))

                ActivityMenuButton(
                    config: .consoleToolbar,
                    action: { _ in
                        //model.paused.toggle()
                    },
                    isToggleButton: true,
                    imageName: "pause.circle",
                    imageAlternateName: "pause.circle.fill",
                    isAlternateState: $model.paused
                )
                .help("Pause console output")

                ActivityMenuButton(
                    config: .consoleToolbar,
                    action: { _ in
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(model.text, forType: .string)
                        isCopying = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isCopying = false
                        }
                    },
                    imageName: isCopying ? "doc.on.doc.fill" : "doc.on.doc"
                )
                .opacity(model.text.isEmpty ? 0.5 : 1.0)
                .disabled(model.text.isEmpty)
                .help("Copy contents")

                ActivityMenuButton(
                    config: .consoleToolbar,
                    action: { _ in
                        model.clear()
                    },
                    imageName: "trash"
                )
                .opacity(model.text.isEmpty ? 0.5 : 1.0)
                .disabled(model.text.isEmpty)
                .help("Clear console")
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
    }
}
