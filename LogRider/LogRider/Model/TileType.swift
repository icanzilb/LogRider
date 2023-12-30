//
//  TileType.swift
//  Tile
//
//  Created by Marin Todorov on 11/1/22.
//

import Foundation

enum TileType: String, Codable {
    case text, chart
    case activity
    case progressCircular
    case toggle
    case intervalTimer
}
