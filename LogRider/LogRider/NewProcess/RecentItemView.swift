//
//  RecentItemView.swift
//  Tile
//
//  Created by Marin Todorov on 1/1/23.
//

import Foundation
import SwiftUI

struct RecentItemView: View {
    let name: String
    var isRunning = false
    var verticalSpacing: CGFloat = 4
    var showIcon = true
    let action: (String) -> Void

    @State var isHovering = false

    var body: some View {
        Button {
            action(name)
        } label: {
            HStack(spacing: 2) {
                if showIcon {
                    if name.hasPrefix("/") {
                        Image(systemName: "doc")
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "macwindow")
                            .foregroundColor(.gray)
                    }
                }

                if isRunning {
                    Text(name)
                        .truncationMode(.middle)
                        .help(name)
                        .padding(.leading, 6)
                } else {
                    Text(name)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                        .help(name)
                        .padding(.leading, 6)
                }
            }
        }
        .lineLimit(1)
        .padding(.vertical, verticalSpacing)
        .onHover(perform: { isHovering in
            self.isHovering = isHovering
        })
        .foregroundColor(isHovering ? .controlText.opacity(0.8): .controlText)
    }
}
