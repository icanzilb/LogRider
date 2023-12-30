//
//  SimCtl.swift
//  Tile
//
//  Created by Marin Todorov on 1/1/23.
//

import Foundation

#if PRO

extension URL {
    var simctlInXcodeBundleURL: URL {
        return
            appendingPathComponent("Contents")
            .appendingPathComponent("Developer")
            .appendingPathComponent("usr")
            .appendingPathComponent("bin")
            .appendingPathComponent("simctl")
    }
}

struct SimulatorEnvironment: Codable {
    var identifier: String
    var name: String
    var version: String
    var udid: String
}

class SimControl {
    @DiskStored(key: "XcodeInstance", defaultValue: nil) var xcode: XcodeInstance?

    func bootedEnvironment() throws -> SimulatorEnvironment {
        guard let xcode = xcode, let xcodeURL = xcode.url else {
            throw("ERROR: No Xcode path set.")
        }
        guard xcodeURL.startAccessingSecurityScopedResource() else {
            throw "Could not access '\(xcodeURL.path)'"
        }

        defer {
            print("Stop secure scope")
            xcodeURL.stopAccessingSecurityScopedResource()
        }

        let name = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "getenv", "booted", "SIMULATOR_DEVICE_NAME"
        ]).run()
        let version = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "getenv", "booted", "SIMULATOR_RUNTIME_VERSION"
        ]).run()
        let udid = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "getenv", "booted", "SIMULATOR_UDID"
        ]).run()
        let identifier = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "getenv", "booted", "SIMULATOR_MODEL_IDENTIFIER"
        ]).run()

        return SimulatorEnvironment(identifier: identifier, name: name, version: version, udid: udid)
    }

    func list() throws -> ListOutput {
        guard let xcode = xcode, let xcodeURL = xcode.url else {
            throw("ERROR: No Xcode path set.")
        }

        // Get device list
        // xcrun simctl list -v -j

        guard xcodeURL.startAccessingSecurityScopedResource() else {
            throw "Could not access '\(xcodeURL.path)'"
        }

        defer {
            print("Stop secure scope")
            xcodeURL.stopAccessingSecurityScopedResource()
        }

        let output = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "list",
            "--json"
        ]).run()

        return try JSONDecoder()
            .decode(ListOutput.self, from: Data(output.utf8))
    }

    func apps() throws -> AppsOutput {
        guard let xcode = xcode, let xcodeURL = xcode.url else {
            throw("ERROR: No Xcode path set.")
        }

        // Get device list
        // xcrun simctl listapps

        guard xcodeURL.startAccessingSecurityScopedResource() else {
            throw "Could not access '\(xcodeURL.path)'"
        }

        defer {
            print("Stop secure scope")
            xcodeURL.stopAccessingSecurityScopedResource()
        }

        let output = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "listapps",
            "booted"
        ]).run()

        let regex = try! NSRegularExpression(pattern: "ApplicationType = User;[^\\{]+CFBundleExecutable = ([^;]+)[^\\{]*CFBundleIdentifier = \"(.+?)\"", options: .dotMatchesLineSeparators)

        var apps = [InstalledApp]()

        regex.enumerateMatches(in: output, range: NSRange(location: 0, length: output.count)) { result, flags, stop in
            if let result {
                let name = (output as NSString).substring(with: result.range(at: 1)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let id = (output as NSString).substring(with: result.range(at: 2))
                apps.append(InstalledApp(executableName: name, identifier: id))
            }
        }

        return AppsOutput(apps: apps)
    }

    func runningAppsIdentifiersBlob() throws -> String {
        guard let xcode = xcode, let xcodeURL = xcode.url else {
            throw("ERROR: No Xcode path set.")
        }

        // Get device list
        // xcrun simctl listapps

        guard xcodeURL.startAccessingSecurityScopedResource() else {
            throw "Could not access '\(xcodeURL.path)'"
        }

        defer {
            print("Stop secure scope")
            xcodeURL.stopAccessingSecurityScopedResource()
        }

        // Get user id
        let output = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "spawn",
            "booted",
            "launchctl",
            "print",
            "system"
        ]).run()

        let regex = try! NSRegularExpression(pattern: "user/(\\d+)", options: .dotMatchesLineSeparators)
        guard let match = regex.firstMatch(in: output, range: NSRange(location: 0, length: output.count)) else {
            throw "No Matches"
        }
        let uid = (output as NSString).substring(with: match.range(at: 1))

        // Get apps in user domain

        let output2 = try ProcessRunner(url: xcodeURL.simctlInXcodeBundleURL, arguments: [
            "spawn",
            "booted",
            "launchctl",
            "print",
            "user/\(uid)"
        ]).run()

        let parts = output2.components(separatedBy: "services = {")
        guard parts.count > 1 else { return "" }

        let blob = parts[1]
            .components(separatedBy: "}")[0]

        return blob
    }
}

#endif
