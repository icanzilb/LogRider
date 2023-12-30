//
//  ActivityMenuButton.swift
//  Tile
//
//  Created by Marin Todorov on 3/23/23.
//

import Foundation
import SwiftUI

struct ActivityMenuButton: View {
    let config: Configuration

    let action: (ActivityMenuButton) -> Void
    let onHover: ((Bool) -> Void)?
    let isToggleButton: Bool

    let imageName: String
    let imageAlternateName: String?

    @State var isHovered = false
    @Binding var isAlternateState: Bool

    init(config: Configuration, action: @escaping (ActivityMenuButton) -> Void, onHover: ((Bool) -> Void)? = nil, isToggleButton: Bool = false, imageName: String, imageAlternateName: String? = nil, isHovered: Bool = false, isAlternateState: Binding<Bool> = .constant(false)) {
        self.config = config
        self.action = action
        self.onHover = onHover
        self.isToggleButton = isToggleButton
        self.imageName = imageName
        self.imageAlternateName = imageAlternateName
        self.isHovered = isHovered
        self._isAlternateState = isAlternateState
    }

    var body: some View {
        Button(action: {
            if isToggleButton {
                isAlternateState.toggle()
            }
            action(self)
        }) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? config.backdropColor : .clear)
                .frame(width: 20, height: 18)
                .overlay(alignment: .center) {

                    Image(systemName: isAlternateState ? imageAlternateName! : imageName)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(config.strokeColor)
                        .opacity(isAlternateState ? 0.8 : 1.0)
                }
        }
        .buttonStyle(.borderless)
        .onHover { hovering in
            isHovered = hovering
            onHover?(hovering)
        }
    }

    struct Configuration {
        let strokeColor: Color
        let backdropColor: Color

        static let activityToolbar = Configuration(strokeColor: .controlDrawnGlyphs, backdropColor: Color.controlShadow.opacity(0.5))
        static let consoleToolbar = Configuration(strokeColor: .primary, backdropColor: Color.controlShadow.opacity(0.2))
    }
}
