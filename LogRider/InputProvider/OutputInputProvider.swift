//
//  StdOutProvider.swift
//  Tile
//
//  Created by Marin Todorov on 10/29/22.
//

import Foundation

struct OutputInputConfiguration {
    let buildDirectory: String
    let appName: String
}

class OutputInputProvider: InputProvider {
    let launchURL: URL
    
    private let errorOutput = Pipe()
    private var errorReadSource: DispatchSourceRead!
    
    private let output = Pipe()
    private var outputReadSource: DispatchSourceRead!
    
    var process: Process!
    
    var handleOutput: ((String) -> Void)?
    var handleError: ((Process, String?) -> Void)?
    var handleTermination: ((Int32) -> Void)?
    var handleConnected: (() -> Void)?
    
    required init(configuration: OutputInputConfiguration) {
        
        launchURL = URL(fileURLWithPath: configuration.buildDirectory)
            .appendingPathComponent(configuration.appName)
            .appendingPathExtension("app")
            .appendingPathComponent("Contents/MacOS")
            .appendingPathComponent(configuration.appName)
        
        print("Will Launch: \(launchURL.path)")
    }
    
    func run() {
        // Stream errors
        let errorReadSource = DispatchSource.makeReadSource(fileDescriptor: errorOutput.fileHandleForReading.fileDescriptor)
        errorReadSource.setEventHandler {// [errorOutput] in
//            let data = errorOutput.fileHandleForReading.availableData
//            let errorMessage = String(data: data, encoding: .utf8)
//            ?? "<\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)) of non-utf8 data>"
            
            // Handle errors
        }
        errorReadSource.resume()
        self.errorReadSource = errorReadSource
        
        // Launch process
        
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", launchURL.path]
        process.standardOutput = output
        process.standardError = errorOutput
        process.launch()
        
        self.process = process
        
        print("Started process \(process.processIdentifier)")
        
        let outputReadSource = DispatchSource.makeReadSource(fileDescriptor: self.output.fileHandleForReading.fileDescriptor)
        outputReadSource.setEventHandler { [weak self] in
            guard let self else { return }
            
            let data = self.output.fileHandleForReading.availableData
            guard !data.isEmpty else { return }
            let message = String(data: data, encoding: .utf8)
            ?? "<\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)) of non-utf8 data>"
            
            if let handleOutput = self.handleOutput {
                DispatchQueue.main.async {
                    handleOutput(message)
                }
            }
        }
        outputReadSource.resume()
        self.outputReadSource = outputReadSource
    }
    
    func stop() {
        self.process?.interrupt()
        self.process?.terminate()
    }
    
    deinit {
        print("Deinit: \(Self.self)")
    }
}
