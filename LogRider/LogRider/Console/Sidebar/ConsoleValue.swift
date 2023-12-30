//
//  ConsoleValue.swift
//  Tile
//
//  Created by Marin Todorov on 4/9/23.
//

import SwiftUI

struct ConsoleValue: View {
    @ObservedObject var item: ConsoleValueModel
    @Binding var selectedItem: ConsoleValueModel.ID?
    
    var body: some View {
        VStack {
            switch item.type {
            case .toggle:
                Toggle("", isOn: .constant(item.value == "true" || item.value == "YES"))
            case .progressCircular:
                // Here we should check for "signpostEvent" prefix and show timers
                ConsoleProgressView(item: item)
            case .intervalTimer:
                ConsoleTimerView(model: item)
            default:
                if let symbolName = item.value.symbolName() {
                    ConsoleSymbol(symbolName: symbolName, selected: selectedItem == item.id)
                } else {
                    Text(item.value)
                        .font(.callout.monospaced())
                }
            }
        }
    }
}
