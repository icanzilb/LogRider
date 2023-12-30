//
//  SystemLogInputProvider.swift
//  Tile
//
//  Created by Marin Todorov on 10/30/22.
//

import Foundation
import os

// TODO: https://samwize.com/2022/10/29/reduce-xcode-debugger-logs/?utm_source=swiftlee&utm_medium=swiftlee_weekly&utm_campaign=issue_139
// Add checks if the log is enabled or not.
// log stream --info --debug --predicate 'subsystem == "subsystem"' -process "LogWriterApp" --style json --source --no-backtrace

class SystemLogInputProvider: InputProvider {
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

        // Launch process
        // /usr/bin/log
        let process = Process()
        process.launchPath = "/usr/bin/env"

        var arguments = [String]()

        // Access the log stream of the sim
        arguments.append(
            contentsOf: [
                "log",
                "stream",
                "--info",
                "--debug"
                ]
            )

        if configuration.preferences.enableSignpostData {
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
           let logMessage = try? jsonDecoder.decode(LogMessage.self, from: Data(message.utf8)),
           !logMessage.subsystem.hasPrefix("com.apple") {

//            // Filter by subsystem
//            if let subsystem = self.configuration.subsystem,
//               logMessage.subsystem != subsystem {
//                // Not the subsystem the user wants
//                return
//            }

//            if self.configuration.preferences.ignoreLogsWithNoSubsystem && logMessage.subsystem.isEmpty {
//                return
//            }

//            print("[log] message '\(logMessage.eventMessage)'")

            DispatchQueue.main.async {
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
    }}
