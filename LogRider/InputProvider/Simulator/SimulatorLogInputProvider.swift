//
//  LogInputProvider.swift
//  Tile
//
//  Created by Marin Todorov on 10/30/22.
//

// https://github.com/ctreffs/SwiftSimctl

// Read the version of the installed app
// defaults read "$(xcrun simctl get_app_container booted your.app.bundle.identifier)"/Info CFBundleVersion

// iSimulator: https://github.com/wigl/iSimulator
// openSim: https://github.com/luosheng/OpenSim
// simsim: https://github.com/dsmelov/simsim


import Foundation
import os
import SwiftUI

let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatter
}()

let jsonDecoder = JSONDecoder()
let jsonEncoder = JSONEncoder()

#if PRO

class SimulatorLogInputProvider: InputProvider {
    var handleOutput: ((String) -> Void)?
    var handleError: ((Process, String?) -> Void)?
    var handleTermination: ((Int32) -> Void)?
    var handleConnected: (() -> Void)?

    private var errorOutput = Pipe()
    private var errorReadSource: DispatchSourceRead!

    private var output = Pipe()
    private var outputReadSource: DispatchSourceRead!

    private var process: Process!

    private let configuration: LogInputConfiguration
    required init(configuration: LogInputConfiguration) {
        self.configuration = configuration
    }

    private var isRunning = false

    @DiskStored(key: "XcodeInstance", defaultValue: nil) var xcode: XcodeInstance?

    func run() {
        print("Run, isRunning = \(isRunning)")

        guard !isRunning else { return }

        isRunning = true

        // Stream errors
        let errorReadSource = DispatchSource.makeReadSource(fileDescriptor: errorOutput.fileHandleForReading.fileDescriptor)
        errorReadSource.setEventHandler { [errorOutput] in
            let data = errorOutput.fileHandleForReading.availableData
            let errorMessage = String(data: data, encoding: .utf8)
                ?? "<\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)) of non-utf8 data>"
            self.errorReadSource.cancel()
            
            // Handle errors
            DispatchQueue.main.async { [weak self] in
                guard let self, let process = self.process else {
                    print("Error: \(errorMessage)")
                    return
                }
                self.handleError!(process, errorMessage.upToLength(100))
            }
        }
        errorReadSource.resume()
        self.errorReadSource = errorReadSource

        // Launch arguments

        //log stream --info --debug --predicate 'subsystem == "subsystem"' -process "LogWriterApp" --style json --source --no-backtrace

        guard let xcode = xcode, let xcodeURL = xcode.url else {
            // TODO: Add error handling here
            print("ERROR: No Xcode path set.")
            isRunning = false
            return
        }

        // Launch process
        // /Users/marin/Developer/Xcode-14.1.app/Contents/Developer/usr/bin/simctl
        let process = Process()
        process.launchPath = xcodeURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Developer")
            .appendingPathComponent("usr")
            .appendingPathComponent("bin")
            .appendingPathComponent("simctl")
            .path

        var arguments = [String]()

        // Access the current simulator
        arguments.append(
            contentsOf: [
                "spawn",
                "booted"
            ]
        )

        // Access the log stream of the sim
        arguments.append(
            contentsOf: [
                "log",
                "stream",
                "--info",
                "--debug"
            ]
        )

        if configuration.preferences.generalStorage.enableSignpostData {
            arguments.append(
                contentsOf: [
                    "--signpost", // track signpost data
                ]
            )
        }

        arguments.append(
            contentsOf: [
                "--process",
                "\(configuration.appName.escapedSpaces())",
                "--style",
                "ndjson",
                "--source",
                "--no-backtrace"
            ]
        )

        // Add subsystem filter, if needed
        if let subsystem = configuration.subsystem {
            arguments.append(
                contentsOf: [
                    "--predicate",
                    "'subsystem == \"\(subsystem.escapedQuotes())\"'",
                ]
            )
        }

        process.arguments = arguments

        //print("[log] \(process.launchPath!) \(process.arguments!.joined(separator: " "))")

        process.standardOutput = output
        process.standardError = errorOutput

        _ = xcodeURL.startAccessingSecurityScopedResource()

        process.launch()

        process.terminationHandler = { process in

            self.errorReadSource.cancel()
            self.errorReadSource = nil
            self.errorOutput = Pipe()

            self.outputReadSource.cancel()
            self.outputReadSource = nil
            self.output = Pipe()

            if self.process.isRunning {
                self.process.terminate()
            }

            if process.terminationStatus != 0 {
                print("[log] Terminated with: \(process.terminationStatus) \(process.terminationReason)")
                DispatchQueue.main.async {
                    self.handleTermination!(process.terminationStatus)
                }
            }

            self.process = nil

            xcodeURL.stopAccessingSecurityScopedResource()

            self.isRunning = false
        }

        self.process = process

        // print("[log] Started process \(process.processIdentifier)")

        let outputReadSource = DispatchSource.makeReadSource(fileDescriptor: self.output.fileHandleForReading.fileDescriptor)
        outputReadSource.setEventHandler { [weak self] in
            guard let self else { return }

            let data = self.output.fileHandleForReading.availableData
            guard !data.isEmpty else { return }
            let message = String(data: data, encoding: .utf8)
            ?? "<\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)) of non-utf8 data>"

            // Split the entry in case it's more messages in one go
            message
                .components(separatedBy: .newlines)
                .filter({ !$0.isEmpty })
                .forEach(self.handleLogLine)
        }
        outputReadSource.resume()
        self.outputReadSource = outputReadSource

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if self?.isRunning == true {
                self?.handleConnected?()
            }
        }
    }

    private func handleLogLine(_ message: String) {
        if let handleOutput = self.handleOutput,
           let logMessage = try? jsonDecoder.decode(LogMessage.self, from: Data(message.utf8)) {

            // Apple's logging
            guard !logMessage.subsystem.hasPrefix("com.apple") else {

                if logMessage.subsystem.hasPrefix("com.apple.runningboard") {
                    if let range = message.range(of: "eventMessage") {
                        if message[range.upperBound...].hasPrefix("\":\"Initializing connection") {
                            DispatchQueue.main.async {
                                handleOutput("$sys:initialize")
                            }
                        }
                    }
                }
                return
            }

            // Filter by subsystem
            if let subsystem = self.configuration.subsystem,
               logMessage.subsystem != subsystem {
                // Not the subsystem the user wants
                return
            }

            if self.configuration.preferences.generalStorage.ignoreLogsWithNoSubsystem && logMessage.subsystem.isEmpty {
                return
            }

            //print("[log] message '\(logMessage.eventMessage)'")

            DispatchQueue.main.async {
//                    print("Subsys: \(logMessage.subsystem)")
//                    print("Cat: \(logMessage.category)")
//                    print("PID: \(logMessage.processID)")
//                    print("Type: \(logMessage.eventType)")
//                    print("Raw: '\(logMessage.eventMessage)'")
//                    print("Path: \(logMessage.processImagePath)")

                if logMessage.eventType == EventType.signpostEvent.rawValue {

                    if let signpostMessage = try? jsonDecoder.decode(SignpostMessage.self, from: Data(message.utf8)),
                       let dateString = signpostMessage.timestamp.components(separatedBy: ".").first,
                       let date = dateFormatter.date(from: dateString) {

                        handleOutput("\(EventType.signpostEvent.rawValue):\(signpostMessage.signpostName):\(signpostMessage.signpostType)-\(date.timeIntervalSinceReferenceDate)")
                    }
                    return
                }

                handleOutput(logMessage.eventMessage)
            }
        } else {
//            print("[discarded] \(message)")
        }
    }

    func stop() {
        isRunning = false
        self.process?.interrupt()
        self.process?.terminate()
    }

    deinit {
        print("Deinit: \(Self.self)")
    }

    // MARK: - Selecting Xcode installation
    static func selectXcode() throws -> XcodeInstance? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select your Xcode.app"
        openPanel.allowedContentTypes = [.application]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")

        guard openPanel.runModal() == .OK else {
            return nil
        }

        if let url = openPanel.url,
           let data = saveBookmarkData(for: url) {

            let xcode = try XcodeInstance(url: url, bookmarkData: data)

            // Successfully selected the Xcode.app bundle, return the data
            return xcode
        }

        return nil
    }

    static private func saveBookmarkData(for url: URL) -> Data? {
        do {
            print(try FileManager.default.attributesOfItem(atPath: url.path))
            let bookmarkData = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            print("Bookmark saved: \(url.path)")
            return bookmarkData
        } catch {
            print("Failed to save bookmark data for \(url.path)", error)
        }
        return nil
    }

}
#endif
