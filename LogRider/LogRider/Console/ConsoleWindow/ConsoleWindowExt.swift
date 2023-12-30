//
//  ConsoleWindowExt.swift
//  Tile
//
//  Created by Marin Todorov on 4/23/23.
//

import SwiftUI

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
