//
//  ConsoleValueModel.swift
//  dataFude for Simulator
//
//  Created by Marin Todorov on 4/14/23.
//

import SwiftUI

class ConsoleValueModel: ObservableObject, Identifiable, Equatable {
    static func == (lhs: ConsoleValueModel, rhs: ConsoleValueModel) -> Bool {
        return lhs.id == rhs.id
    }

    var id: String { name }
    var name = ""
    @Published var value = ""
    var type: TileType
    var regexComplied: NSRegularExpression?

    init(name: String, value: String, type: TileType, regexCompiled: NSRegularExpression?) {
        self.name = name
        self.value = value
        self.type = type
        self.regexComplied = regexCompiled
    }

    // Handling output
    func handleOutput(_ text: String) -> Bool {
        guard let regexComplied, regexComplied.numberOfCaptureGroups > 0 else {
            return false
        }

        var result = false

        for line in text.components(separatedBy: .newlines).filter({ !$0.isEmpty }) {
            if let match = regexComplied.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                if match.numberOfRanges > 1 {
                    let value = (line as NSString).substring(with: match.range(at: 1))
                    result = true
                    if type == .progressCircular {
                        print("Handling progress: \(value)")
                    }
                    //DispatchQueue.main.async {
                        self.value = value
                    //}
                }
            }
        }

        return result
    }
}
