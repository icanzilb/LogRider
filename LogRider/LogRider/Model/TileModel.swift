//
//  TileModel.swift
//  Tile
//
//  Created by Marin Todorov on 10/27/22.
//

import Foundation
import Combine

extension String {
    var cocoaRange: NSRange { return NSRange(location: 0, length: count) }
}

class TileModel: ObservableObject, Codable, Identifiable, Equatable {
    static func == (lhs: TileModel, rhs: TileModel) -> Bool {
        return lhs.tileType == rhs.tileType
            && lhs.headline == rhs.headline
    }

    let id = UUID()

    @Published var tileType: TileType = .text { didSet { onUpdate() } }

    private var isInitialized = false
    @Published var value = "" {
        willSet {
            if !isInitialized {
                tileType = Self.autodetectTileType(initialValue: newValue)
                isInitialized = true
            }
        }
        didSet {
            updatesCount += 1
            if tileType != .intervalTimer {
                headline = "\(updatesCount) updates"
            }
        }
    }
    @Published var updatesCount = 0
    @Published var headline = "Waiting for input"
    @Published var regex = "" {
        didSet {
            do {
                regexComplied = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                regexInvalid = false
            } catch {
                regexInvalid = true
            }
            onUpdate()
        }
    }
    @Published var regexInvalid = false
    var regexComplied: NSRegularExpression?

    @Published var containerShouldChange = false

    @Published var autoCapture: AutoCaptureGroup? { didSet { onUpdate() } }
    var autoCaptureMatch: NSTextCheckingResult?
    var autoCaptureString: String? { didSet { onUpdate() } }
    @Published var autoCaptureHeadline: String?

    @Published var showsMatchField = true

    @Published var historyLength: Int = 0 {
        didSet {
            onUpdate()
        }
    }

    // Persistence
    private var shouldUpdate = true

    func withoutUpdating(_ block: (TileModel) throws -> Void) rethrows {
        shouldUpdate = false
        try block(self)
        shouldUpdate = true
    }

    public var didUpdate: ((TileModel) -> Void)!
    private func onUpdate() {
        guard shouldUpdate else { return }
        didUpdate(self)
    }

    // Codable conformance

    enum Keys: CodingKey {
        case tileType, tileSize
        case regex
        case autoCapture, autoCaptureString
        case backgroundColor
        case historyLength
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(tileType, forKey: .tileType)
        try container.encode(regex, forKey: .regex)
        try container.encode(autoCapture, forKey: .autoCapture)
        try container.encode(autoCaptureString, forKey: .autoCaptureString)
        // Don't encode the match, we derive it during decoding
        try container.encode(historyLength, forKey: .historyLength)
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: Keys.self)

        try withoutUpdating { model in
            model.tileType = try container.decode(TileType.self, forKey: .tileType)
            model.regex = try container.decode(String.self, forKey: .regex)
            model.autoCapture = try container.decodeIfPresent(AutoCaptureGroup.self, forKey: .autoCapture)
            model.autoCaptureString = try container.decodeIfPresent(String.self, forKey: .autoCaptureString)

            // Derive the first match

            if let autoCaptureString, let autoCapture {
                let groupRegex = try NSRegularExpression(pattern: autoCapture.regex)
                let matches = groupRegex.matches(in: autoCaptureString, range: autoCaptureString.cocoaRange)
                guard !matches.isEmpty else {
                    throw DecodingError.dataCorruptedError(
                        forKey: Keys.autoCapture,
                        in: container,
                        debugDescription: "Could not re-create the auto capture group first match"
                    )
                }
                model.autoCaptureMatch = matches[0]

                let matchResultDetails = autoCapture.displayRegex(withMatch: matches[0], in: autoCaptureString)
                model.autoCaptureHeadline = matchResultDetails?.headline
            }

            model.historyLength = try container.decodeIfPresent(Int.self, forKey: .historyLength) ?? 0

            // Custom property logic
            if model.tileType == .activity {
                model.headline = "Waiting for input"
            }
        }
    }

    // Handling output
    func handleOutput(_ text: String) -> Bool {
//        if tileType == .activity {
//            self.value = String((Int(self.value) ?? 0) + 1)
//            return false
//        }

        guard let regexComplied, regexComplied.numberOfCaptureGroups > 0 else {
            return false
        }

        var result = false

        for line in text.components(separatedBy: .newlines).filter({ !$0.isEmpty }) {
            if let match = regexComplied.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                if match.numberOfRanges > 1 {
                    let value = (line as NSString).substring(with: match.range(at: 1))
                    result = true
                    //DispatchQueue.main.async {
                        self.value = value
                    //}
                }
            }
        }

        return result
    }

    func copy() -> TileModel {
        let newTile = TileModel()

        newTile.withoutUpdating { model in
            model.didUpdate = self.didUpdate
            model.regex = self.regex
            model.autoCapture = self.autoCapture
            model.autoCaptureMatch = self.autoCaptureMatch
            model.autoCaptureString = self.autoCaptureString
            model.historyLength = self.historyLength

            if tileType == .activity {
                model.tileType = .text
                model.autoCapture = nil
            }
        }

        assert(newTile.didUpdate != nil)

        return newTile
    }

    func reset() {
        updatesCount = 0
        value = ""
        didReset = ()
    }

    @Published var didReset: Void = ()
}

extension Array<TileModel>: Identifiable {
    public var id: String { return reduce(into: "", { $0 += ":" + $1.id.uuidString }) }
}

extension TileModel {
    static func autodetectTileType(initialValue: String) -> TileType {
        // Check for a progress view
        let value = initialValue.trimmingCharacters(in: .whitespaces)
        if value.hasSuffix("%"), Double(value.dropLast()) != nil {
            return .progressCircular
        }

        if ["true", "false", "YES", "NO"].contains(value) {
            return .toggle
        }

        return .text
        
//        if let autoCaptureString, autoCaptureString.hasPrefix(EventType.signpostEvent.rawValue) == true {
//            tileType = .intervalTimer
//
//            let parts = autoCaptureString.components(separatedBy: ":")
//            if parts.count > 2 {
//                autoCaptureHeadline = parts[1]
//            }
//            return
//        }
    }
}
