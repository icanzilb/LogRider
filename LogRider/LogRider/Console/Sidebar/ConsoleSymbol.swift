//
//  ConsoleSymbol.swift
//  Tile
//
//  Created by Marin Todorov on 5/6/23.
//

import SwiftUI
import os

struct ConsoleSymbol: View {
    let symbolName: String
    let selected: Bool

    @State var isHovered = false

    var body: some View {
        HStack {
            Image(systemName: symbolName)
                .font(.title2)
                .imageScale(.medium)
                .foregroundColor(
                    selected ? Color.controlDrawnGlyphs : Color.accentColor
                )
                .frame(height: 24)
                .help(symbolName)

            if isHovered {
                Text(symbolName)
                    .font(.caption.monospaced())
                    .opacity(isHovered ? 1 : 0)
            }

            Spacer()
        }
        .frame(height: 18)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered in
            withAnimation {
                self.isHovered = isHovered
            }
        }

    }
}
