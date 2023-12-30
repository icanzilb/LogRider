//
//  ConsoleView.swift
//  Tile
//
//  Created by Marin Todorov on 3/25/23.
//

import Foundation
import SwiftUI
import Combine

let defaultPadding: CGFloat = 16.0

var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()

private var openTiles = Set<String>() {
    didSet {
        print(openTiles)
    }
}

struct ConsoleWindow: View {
    static var instances = [String: ConsoleWindow]()

    private let uuid = UUID()

    let arguments: ConsoleArguments

    var title: String {
        Self.title(forName: arguments.processName)
    }

    static func title(forName name: String) -> String {
        "Console: \(name.components(separatedBy: "/").last!)"
    }

    static func open(processName: String, closeIfVisible: Bool) {
//        if closeIfVisible && instances.keys.contains(title(forName: processName)) {
//            NSApp.closeWindows(withTitlePrefix: title(forName: processName))
//            return
//        }

        openAppWindow(
            id: ConsoleScene.id,
            argument: ConsoleArguments(processName: processName),
            singleInstance: false
        )
    }

    @EnvironmentObject var preferences: PreferencesModel
    @EnvironmentObject var alertQueue: AlertQueue

    @StateObject var appModel = AppModel()

    @ObservedObject var consoleModel = ConsoleModel()

    @State var isPinned = false {
        didSet {
            NSApp.windowsWithTitlePrefix(title) { window in
                window.level = isPinned ? .floating : .normal
            }
        }
    }

    let font: Font = .callout
    let textSpacing: CGFloat = 2.0
    let isBold = true

    let prependTime = true

    var styledFont: Font {
        if isBold {
            return font.bold()
        } else {
            return font
        }
    }

    init(arguments: ConsoleArguments) {
        self.arguments = arguments
    }

    func handleOutput(_ line: String) {
        guard !consoleModel.paused else {
            return
        }

        for var line in line.components(separatedBy: .newlines) {
            line = line.trimmingCharacters(in: .whitespaces)

            guard !line.hasPrefix("$sys:") else {
                continue
            }

            var handled = false
            for value in sidebarModel.trackedValues {
                if !handled {
                    handled = value.handleOutput(line) || handled
                    if handled {
                        print("Sidebar handled '\(line)' by '\(value.type)'")
                    }
                }
            }

            if prependTime {
                line = "[" + timeFormatter.string(from: .now) + "] " + line
            }

            consoleModel.append("\(line)\n")
        }
    }

    @ObservedObject var sidebarModel = SidebarModel()

    func updateTrackedValues() {
        let current = sidebarModel.trackedValues

        sidebarModel.trackedValues = appModel.tiles
            .filter({ $0.tileType != .activity })
            .sorted(by: { $0.headline < $1.headline })
            .map { tile in
                print("type \(tile.tileType)")

                if let existing = current.first(where: { model in
                    model.name == tile.autoCaptureHeadline ?? "Untitled"
                }) {
                    return existing
                }

                return ConsoleValueModel(
                    name: tile.autoCaptureHeadline ?? "Untitled",
                    value: tile.value,
                    type: tile.tileType,
                    regexCompiled: tile.regexComplied
                )
            }
    }

    @State var selectedItem: ConsoleValueModel.ID?
    @State var scrollToBottom = false
    @State var showNewProcess = true

    func startModel() {
        appModel.outputHandlers[uuid] = handleOutput
        Self.instances[title] = self

        appModel.withoutUpdating { am in
            am.processName = arguments.processName
            am.preferences = preferences
            am.alertQueue = alertQueue

            if arguments.processName.hasPrefix("/") {
                // System log reader
                am.setInputProvider(
                    provider: FileStreamInputProvider(
                        configuration: LogInputConfiguration(
                            appName: arguments.processName,
                            subsystem: arguments.options[.subsystem],
                            preferences: preferences
                        )
                    )
                )
            } else {
                // System log reader
                am.setInputProvider(
                    provider: SystemLogInputProvider(
                        configuration: LogInputConfiguration(
                            appName: arguments.processName,
                            subsystem: arguments.options[.subsystem],
                            preferences: preferences
                        )
                    )
                )
            }

            am.setup()
        }
        appModel.run()

        // Track the process
        openTiles.insert(appModel.processName!)

    }

    var body: some View {
        NavigationView {
            SidebarView(
                selectedItem: $selectedItem
            )
            .environmentObject(sidebarModel)
            .onAppear {
                updateTrackedValues()
            }
            .onChange(of: appModel.tiles) { _ in
                updateTrackedValues()
            }

            // Console view
            VStack {
                GeometryReader { geometry in
                    ScrollViewReader { reader in
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            ZStack(alignment: .leading) {
                                EditorView(
                                    text: $consoleModel.displayText,
                                    isScrollingToBottom: $consoleModel.isScrollingToBottom,
                                    scrollToBottom: $scrollToBottom,
                                    isEditable: false,
                                    font: NSFont.labelFont(ofSize: NSFont.labelFontSize),
                                    onEditingChanged: { },
                                    onCommit: { },
                                    onTextChange: { _ in }
                                )
                                .font(styledFont.monospaced())
                                .lineSpacing(textSpacing)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                                .lineLimit(nil)
                                .id(1)
                                .padding(4)
                                .frame(maxHeight: .infinity)

                                VStack(alignment: .trailing) {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        if !consoleModel.isScrollingToBottom {
                                            Button {
                                                scrollToBottom = true
                                            } label: {
                                                Image(systemName: "arrow.down.to.line")
                                            }
                                        }
                                    }
                                }
                                .padding(.trailing, 32)
                                .padding(.bottom, 16)
                            }
                            .frame(
                                minWidth: geometry.size.width,
                                maxWidth: .infinity,
                                minHeight: geometry.size.height,
                                maxHeight: .infinity,
                                alignment: .topLeading
                            )
                        }
                    }
                }
                .coordinateSpace(name: "scroll")

                ConsoleToolbar(model: consoleModel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .sheet(isPresented: $showNewProcess) {
                NewProcessView(preferences: preferences, onSelectSource: { processName in
                    appModel.processName = processName
                    startModel()
                })
                .frame(width: 450, height: 150, alignment: .center)
            }
            .background(.white)
            .frame(minWidth: 200)
            .onAppear {
                startModel()
            }
            .onDisappear {
                appModel.outputHandlers.removeValue(forKey: uuid)
                Self.instances.removeValue(forKey: title)
                openTiles.remove(appModel.processName!)
            }
            .navigationTitle(title)
            .navigationSplitViewStyle(.prominentDetail)
            .toolbar {
//                ToolbarItem(placement: .navigation) {
//                    Button(action: toggleSidebar, label: {
//                        Image(systemName: "sidebar.leading")
//                    })
//                }
//
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        isPinned.toggle()
                    }, label: {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                    })
                    .help("Show on top of other windows")
                }

                ToolbarItem(placement: .automatic) {
                    Button(action: {}, label: {
                        Image(systemName: "line.3.horizontal")
                    })
                }

                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showNewProcess.toggle()
                    }, label: {
                        Image(systemName: "rectangle.and.text.magnifyingglass")
                    })
                }
            }
        }
    }
}
