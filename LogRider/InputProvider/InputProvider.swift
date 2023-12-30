//
//  InputProvider.swift
//  Tile
//
//  Created by Marin Todorov on 10/29/22.
//

import Foundation

protocol InputProvider {
    associatedtype InputConfiguration
    init(configuration: InputConfiguration)
    func run()
    func stop()

    var handleOutput: ((String) -> Void)? { get set }
    var handleError: ((Process, String?) -> Void)? { get set }
    var handleTermination: ((Int32) -> Void)? { get set }
    var handleConnected: (() -> Void)? { get set }
}

struct LogInputConfiguration {
    let appName: String
    let subsystem: String?
    let preferences: PreferencesModel
}
