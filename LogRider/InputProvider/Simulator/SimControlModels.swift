//
//  SimControlModels.swift
//  Tile
//
//  Created by Marin Todorov on 1/1/23.
//

import Foundation

typealias RuntimeIdentifier = String

struct ListOutput: Codable {
    var devicetypes: [DeviceType]
    var runtimes: [Runtime]
    var devices: [RuntimeIdentifier: [Device]]
}

struct DeviceType: Codable {
    var productFamily: String
    var identifier: RuntimeIdentifier
    var modelIdentifier: String
    var name: String
}

struct Runtime: Codable {
    var platform: String
    var identifier: String
    var version: String
    var name: String
}

struct Device: Codable {
    var dataPath: String
    var logPath: String
    var udid: String
    var isAvailable: Bool
    var deviceTypeIdentifier: String
    var state: String
    var name: String

    var isRunning: Bool { state == "Booted" }
}

struct AppsOutput: Codable {
    var apps: [InstalledApp]
}

struct InstalledApp: Codable, Identifiable {
    var id: String { executableName }
    var executableName: String
    var identifier: String
    var isRunning = false
}
