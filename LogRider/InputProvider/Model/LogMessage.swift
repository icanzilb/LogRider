//
//  LogMessage.swift
//  Tile
//
//  Created by Marin Todorov on 10/30/22.
//

import Foundation

enum EventType: String {
    case event, signpostEvent
}

struct LogMessage: Decodable {
    let eventType: String
    let eventMessage: String
    let subsystem: String
    let category: String
    let timestamp: String
    let processID: UInt
    let processImagePath: String
}

struct SignpostMessage: Decodable {
    let signpostType: String
    let signpostName: String
    let timestamp: String
}
