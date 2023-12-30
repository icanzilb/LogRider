//
//  Process.swift
//  Tile
//
//  Created by Marin Todorov on 1/1/23.
//

import Foundation

class ProcessRunner {
    var handleOutput: ((String) -> Void)?
    var handleError: ((Process, String?) -> Void)?

    private var errorOutput = Pipe()
    private var errorReadSource: DispatchSourceRead!

    private var output = Pipe()
    private var outputReadSource: DispatchSourceRead!

    private var process: Process!

    //@DiskStored(key: "XcodeInstance", defaultValue: nil) var xcode: XcodeInstance?

    init(url: URL, arguments: [String]? = nil) {
        process = Process()
        process.executableURL = url
        process.launchPath = url.path
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe

        let errorPipe = Pipe()
        process.standardError = errorPipe
    }

    @inlinable @inline(__always) func run() throws -> String {
        print("[Process.run] \(String(describing: process.launchPath!)) \(process.arguments?.joined(separator: " ") ?? "")")

        var errorMessage = ""
        var outputContent = ""
        var failedDueToSandbox = false

        // Stream errors
        let errorReadSource = DispatchSource.makeReadSource(fileDescriptor: errorOutput.fileHandleForReading.fileDescriptor)
        errorReadSource.setEventHandler { [errorOutput] in
            let data = errorOutput.fileHandleForReading.availableData
            let message = String(data: data, encoding: .utf8)
                ?? "<\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)) of non-utf8 data>"
            self.errorReadSource?.cancel()

            // Handle errors
            errorMessage = message
            print("ERROR: \(message)")

            if message.contains("sandbox access") {
                // Sandbox access issue, throw out of method
                failedDueToSandbox = true
                //self.process.interrupt()
            }
        }
        errorReadSource.resume()
        self.errorReadSource = errorReadSource
        process.standardError = errorOutput

        process.terminationHandler = { process in

            self.errorReadSource?.cancel()
            self.errorReadSource = nil
            self.errorOutput = Pipe()

            self.outputReadSource?.cancel()
            self.outputReadSource = nil
            self.output = Pipe()

            if self.process.isRunning {
                self.process.terminate()
            }
        }

        let outputReadSource = DispatchSource.makeReadSource(fileDescriptor: self.output.fileHandleForReading.fileDescriptor)
        outputReadSource.setEventHandler { [weak self] in
            guard let self else { return }

            let data = self.output.fileHandleForReading.availableData
            guard !data.isEmpty else { return }
            let message = String(data: data, encoding: .utf8)
            ?? "<\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)) of non-utf8 data>"

            outputContent += message
        }
        outputReadSource.resume()
        self.outputReadSource = outputReadSource
        process.standardOutput = output

        do {
            try process.run()
        } catch let error as CocoaError {
            print(error)
            print()
        }

        process.waitUntilExit()

        if failedDueToSandbox {
            throw SandboxError(path: process.launchPath!, message: errorMessage)
        }

        guard process.terminationStatus == EXIT_SUCCESS else {
            throw errorMessage
        }

        return outputContent.trimmingCharacters(in: .newlines)
    }
}

struct SandboxError: Error, Equatable {
    let path: String
    let message: String
}
