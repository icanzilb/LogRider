//
//  FileStreamInputProvider.swift
//  dataFude for Simulator
//
//  Created by Marin Todorov on 2/28/23.
//

import Foundation
import Cocoa
import os

class FileStreamInputProvider: InputProvider {
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

        // Launch process
        //tail -f [path]

        let process = Process()
        process.launchPath = "/usr/bin/env"

        var arguments = [String]()

        // Access the log stream of the sim
        arguments.append(
            contentsOf: [
                "tail",
                "-F",
                configuration.appName
            ]
        )
        process.arguments = arguments

        print("[log] \(process.launchPath!) \(process.arguments!.joined(separator: " "))")

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
        if let handleOutput = self.handleOutput {
            print("[log] message '\(message)'")
            DispatchQueue.main.async {
                handleOutput(message)
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
}

extension FileStreamInputProvider {
    static func selectLogFile() throws -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a lof file"
        openPanel.allowedContentTypes = [.text]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        //openPanel.directoryURL = URL(fileURLWithPath: "/Applications")

        guard openPanel.runModal() == .OK else {
            return nil
        }

        return openPanel.url
    }
}
