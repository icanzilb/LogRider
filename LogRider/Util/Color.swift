//
//  Color.swift
//  Tile
//
//  Created by Marin Todorov on 11/9/22.
//

import Foundation
import SwiftUI

extension Color {
    static func named(_ name: String) -> Color {
        guard let color = NSColor(named: name) else {
            fatalError("Color \(name) not found")
        }
        return Color(nsColor: color)
    }

    static let tileRed = Color.named("TileRed")
    static let tileBlue = Color.named("TileBlue")
    static let tileGreen = Color.named("TileGreen")
    static let tilePurple = Color.named("TilePurple")
    static let tileTeal = Color.named("TileTeal")
    static let tileIndigo = Color.named("TileIndigo")
    static let tilePink = Color.named("TilePink")

    static let tileBorder = Color.named("TileBorder")

    static let controlShadow = Color.named("ControlShadow")
    static let controlShadowHighlight = Color.named("ControlShadowHighlight")
    static let controlOuterSelection = Color.named("ControlOuterSelection")
    static let controlBackground = Color.named("ControlBackground")
    static let controlText = Color.named("ControlText")

    static let textIndicator = Color.named("TextIndicator")
    static let chartBar = Color.named("ChartBar")
    static let controlDrawnGlyphs = Color.named("ControlDrawnGlyphs")

    static let tokenBackground = Color.named("TokenBackground")
    static let tokenText = Color.named("TokenText")

    static let customAccentColor = Color.named("CustomAccentColor")
}

