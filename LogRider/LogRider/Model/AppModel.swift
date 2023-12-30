//
//  TileModel.swift
//  Tile
//
//  Created by Marin Todorov on 10/26/22.
//

import Foundation
import Combine
import Cocoa
import SwiftUI
import os

// Allowed headline characters
let headlineCharset = CharacterSet.alphanumerics
    .union(CharacterSet.whitespaces)
    .union(CharacterSet(charactersIn: "_-$"))

enum TileAddingPosition {
    case sameRowAs(TileModel)
    case below(TileModel)
}

class AppModel: ObservableObject {
    static weak var latest: AppModel?
    private static var appModels = [WeakAppModel]()

    private struct WeakAppModel {
        weak var model: AppModel?
    }

    static func withName(_ name: String) -> AppModel? {
        return Self.appModels.first(where: { $0.model?.processName == name })?.model
    }

    private var willTerminateSubscription: AnyCancellable?

    @Published var update = false

    @Published var processName: String?  { didSet { onUpdate() } }

    var preferences: PreferencesModel!

    private var inputProvider: (any InputProvider)?

    private var activatedAutoCaptures = [String]()

    static var counter = 0
    private var __id: Int = 0

    weak var alertQueue: AlertQueue?

    var tiles = [TileModel]()

    deinit {
        Self.appModels.removeAll(where: { $0.model?.processName == processName })
        print("Deinit appModel \(__id)")
    }

    var outputHandlers = [UUID: (String) -> Void]()

    func addTile(newTile: TileModel? = nil, initialOutput: String) {
        let new = newTile ?? TileModel()
        _ = new.handleOutput(initialOutput)
        new.tileType = TileModel.autodetectTileType(initialValue: new.value)
//        DispatchQueue.main.async {

            print("Autodetect from '\(new.value)'")
            self.tiles.append(new)
//        }
    }

    // Don't add parameters here because it makes initialization very difficult.
    init() {
        Self.latest = self

        DispatchQueue.main.async {
            if let latest = Self.latest {
                Self.appModels.append(WeakAppModel(model: latest))
            }
        }

        // Handle reopens
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.subscribeForResets()
        }
    }

    func subscribeForResets() {
        reopenSubscription?.cancel()
        reopenSubscription = NotificationCenter.default.publisher(for: .openProcessName, object: nil)
            .sink(receiveValue: { [weak self] notification in
                guard let processName = notification.userInfo?["name"] as? String,
                      processName == self?.processName, let self else { return }

                for tile in self.tiles {
                    tile.reset()
                }
            })
    }

    private var reopenSubscription: AnyCancellable?

    func setInputProvider(provider: any InputProvider) {
        Self.counter += 1
        self.__id = Self.counter
        print("Init appModel \(__id)")

        self.inputProvider = provider

        self.inputProvider!.handleOutput = { [weak self] message in
            guard let self else { return }
            self.handleOutput(message)
        }

        self.inputProvider!.handleError = { process, errorMessage in
            if let errorMessage {
                print(" --- log error --- ")
                print(errorMessage)
            }
        }

        self.inputProvider!.handleTermination = { exitCode in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.restart()
            }
        }

        willTerminateSubscription = NotificationCenter.default
            .publisher(for: NSApplication.willTerminateNotification, object: nil)
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                self.inputProvider?.stop()
            })

        // TODO: Add support for a project config file by reading the TARGET_BUILD_DIR env and looking for a config file there.
    }

    func setup() {

    }

    func run() {
        inputProvider!.run()
    }

    func restart() {
        withAnimation {
            tiles.first(where: { $0.tileType == .activity })?.autoCaptureHeadline = "Connecting..."
        }

        inputProvider!.stop()
        run()

        inputProvider?.handleConnected = { [weak self] in
            withAnimation {
                self?.tiles.first(where: { $0.tileType == .activity })?.autoCaptureHeadline = "Connected"
            }
        }
    }

    private let updateThrottle = Throttle(interval: .milliseconds(500))
    private var shouldUpdate = true

    func withoutUpdating(_ block: (AppModel) -> Void) {
        shouldUpdate = false
        block(self)
        shouldUpdate = true
    }

    func onUpdate() {
        guard shouldUpdate else { return }

        updateThrottle.schedule { [weak self] in
            guard let self else { return }
            self.save()
        }
    }

    func save() {

    }

    func addSignpostTile() {
        let defaultTile = TileModel()

        defaultTile.withoutUpdating { tile in
            tile.tileType = .intervalTimer
            tile.headline = "Timer"
            tile.regex = signpostAutoCaptureGroup.regex
            tile.autoCapture = signpostAutoCaptureGroup
            tile.autoCaptureString = " "

            tile.didUpdate = { [weak self] _ in self?.onUpdate() }
        }

        tiles.append(defaultTile)
    }

    func load() {

    }

    // Handle output
    private var regexCache = [String: NSRegularExpression]()

    func handleSystemEvent(_ message: String) {
        if message == "initialize" {
            tiles.forEach { $0.reset() }
        }
    }

    func handleOutput(_ message: String) {
        guard !message.isEmpty,
              message.first!.isWhitespace == false,
              !message.contains("\n") else { return }

        //print("Message '\(message)'")

        guard !message.hasPrefix("$sys:") else {
            handleSystemEvent(String(message.dropFirst(5)))
            return
        }

        let messageRange = NSRange(location: 0, length: message.count)

        var handled = false
        for tile in self.tiles {
            if !handled {
                handled = tile.handleOutput(message) || handled
                if handled {
                    print("Output '\(message)' handled by \(tile.tileType)")
                }
            }
        }

        for handler in outputHandlers.values {
            handler(message)
        }

        if !handled {
            // Auto capture
            for group in [signpostAutoCaptureGroup] + self.preferences.autoCapture {
                let rx: NSRegularExpression?
                if let cached = regexCache[group.regex] {
                    rx = cached
                } else if let newRx = try? NSRegularExpression(pattern: group.regex) {
                    regexCache[group.regex] = newRx
                    rx = newRx
                } else {
                    rx = nil
                }

                if let rx {
                    let matches = rx.matches(in: message, range: messageRange)
                    if !matches.isEmpty,
                        let matchResultDetails = group.displayRegex(withMatch: matches[0], in: message),

                        // TODO: Workaround for punctuation
                        matchResultDetails.headline.unicodeScalars.allSatisfy({ headlineCharset.contains($0) }) {

                        // Create a new tile
                        //self.activatedAutoCaptures.append(group.id)

                        let newTile = TileModel()

                        newTile.didUpdate = { [weak self] _ in self?.onUpdate() }
                        newTile.autoCapture = group
                        newTile.autoCaptureMatch = matches[0]
                        newTile.autoCaptureString = message
                        newTile.autoCaptureHeadline = matchResultDetails.headline

                        newTile.regex = matchResultDetails.displayText
                        newTile.tileType = .text

                        addTile(newTile: newTile, initialOutput: message)
                    }
                }
            }
        }
    }
}
