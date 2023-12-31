//
//  SuggestionInput.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 13.12.20.
//

import SwiftUI

struct Suggestion<V: Equatable>: Equatable {
    var text: String = ""
    var value: V
    
    static func ==(_ lhs: Suggestion<V>, _ rhs: Suggestion<V>) -> Bool {
        return lhs.value == rhs.value
    }
}

struct SuggestionGroup<V: Equatable>: Equatable {
    var title: String?
    var suggestions: [Suggestion<V>]
    
    static func ==(_ lhs: SuggestionGroup<V>, _ rhs: SuggestionGroup<V>) -> Bool {
        return lhs.suggestions == rhs.suggestions
    }
}

struct SuggestionInput<V: Equatable>: View {
    @Binding var text: String
    var suggestionGroups: [SuggestionGroup<V>]
    
    @StateObject var model = SuggestionsModel<V>()
    let didConfirmSelection: (String) -> Void

    var body: some View {
        let model = self.model
        if model.suggestionGroups != self.suggestionGroups {
            model.suggestionGroups = self.suggestionGroups
            
            model.selectedSuggestion = nil
        }
        model.textBinding = self.$text
        
        return SuggestionTextField(text: self.$text, model: model)
            .borderlessWindow(isVisible: Binding<Bool>(get: { model.suggestionsVisible && !model.suggestionGroups.isEmpty && !model.suggestionGroups.first!.suggestions.isEmpty }, set: { model.suggestionsVisible = $0 }),
                              behavior: .semiTransient,
                              anchor: .bottomLeading,
                              windowAnchor: .topLeading,
                              windowOffset: CGPoint(x: -20, y: -16)
            ) {
                SuggestionPopup(model: model)
                    .frame(width: model.width)
                    .frame(alignment: .leading)
                    .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow, cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .foregroundColor(Color(white: 0.6, opacity: 0.2))
                    )
                    .shadow(color: Color(white: 0, opacity: 0.10),
                            radius: 5, x: 0, y: 2)
                    .padding(20)
            }
            .onReceive(model.$suggestionConfirmed) { newValue in
                if newValue, let text = model.textBinding?.wrappedValue {
                    didConfirmSelection(text)
                    DispatchQueue.main.async {
                        // TODO: Close the window
                        print("CONFIRM: \(newValue)")
                    }
                }
            }
    }
}
