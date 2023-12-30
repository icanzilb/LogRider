//
//  ConsoleProgressView.swift
//  Tile
//
//  Created by Marin Todorov on 4/9/23.
//

import SwiftUI

struct ConsoleProgressView: View {
    private func percentageAsDouble(_ value: String) -> Double {
        guard let value = try? Double(value, format: .percent) else {
            return 0.0
        }
        return value
    }

    var item: ConsoleValueModel {
        didSet {
            print("Changed item")
        }
    }
    @State var isHovered = true

    @State var progressValue: Double = 0.0 {
        didSet {
            print("WHAT: \(progressValue)")
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            ProgressView(value: progressValue)
                .onReceive(item.$value, perform: { value in
                    print("RECEIVE")
                    progressValue = percentageAsDouble(value)
                })

            if isHovered {
                Text(item.value)
                    .frame(width: 28, alignment: .trailing)
                    .font(.caption.monospaced())
                    .opacity(isHovered ? 1 : 0)
            }
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
