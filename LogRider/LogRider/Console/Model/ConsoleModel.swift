//
//  ConsoleModel.swift
//  Tile
//
//  Created by Marin Todorov on 3/26/23.
//

import Foundation
import SwiftUI
import Combine

class ConsoleModel: ObservableObject {
    @Published private (set) var text = ""
    @Published var displayText = NSAttributedString()
    @Published var query: ConsoleFilter = .search("")
    @Published var queryNote: String?

    @Published var isScrollingToBottom = true

    var paused = false

    private var lastProcessedIndex: String.Index = "".startIndex

    private var subscriptions = [AnyCancellable]()

    init() {
        $text.eraseToAnyPublisher()
            .combineLatest($query.eraseToAnyPublisher())
            .sink { [weak self] _ in
                self?.updateDisplayText()
            }
            .store(in: &subscriptions)
    }

    func append(_ item: String) {
        guard !paused else { return }
        text += item
    }

    func clear() {
        text = ""
        lastProcessedIndex = text.startIndex
    }

    private func updateDisplayText() {
        guard !query.text.isEmpty else {
            displayText = NSAttributedString(string: text)
            //print(displayText)
            queryNote = nil
            return
        }
        //print("Filtering for '\(query)'")

        let clippedText = self.text.components(separatedBy: .newlines)
            .suffix(1000)
            .joined(separator: "\n")

        switch query {
        case .search(let queryText):
            DispatchQueue.global().async {
                let attributedString = NSMutableAttributedString(string: clippedText)
                let _ = attributedString.setBackgroundFor(queryText.lowercased(), with: .systemYellow)
                let count = (self.text as NSString).matchesCount(queryText.lowercased())
                DispatchQueue.main.async { [weak self] in
                    self?.displayText = attributedString
                    self?.queryNote = "\(count) matches"
                }
            }

        case .filter(let queryText):
            DispatchQueue.global().async {
                let queryText = queryText.lowercased()
                let attributed = NSMutableAttributedString(
                    string: clippedText.components(separatedBy: .newlines)
                        .filter({ $0.lowercased().contains(queryText) })
                        .joined(separator: "\n")
                )
                let count = attributed.setBackgroundFor(queryText, with: .systemYellow)

                DispatchQueue.main.async { [weak self] in
                    self?.displayText = attributed
                    self?.queryNote = "\(count) matches"
                }
            }

        case .beep(let queryText):
            let lastProcessedIndex = self.lastProcessedIndex
            let queryText = queryText.lowercased()
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                guard let _ = clippedText.range(of: queryText, options: .caseInsensitive, range: lastProcessedIndex..<clippedText.endIndex) else {
                    DispatchQueue.main.async {
                        self.displayText = NSAttributedString(string: clippedText)
                        self.queryNote = nil
                    }
                    return
                }
                let head = NSMutableAttributedString(string: String(clippedText[...lastProcessedIndex]))
                let tail = NSMutableAttributedString(string: String(clippedText[clippedText.index(after: lastProcessedIndex)...]))
                _ = tail.setBackgroundFor(queryText, with: .systemYellow)
                head.append(tail)

                DispatchQueue.main.async {
                    self.displayText = head
                    self.queryNote = "match"
                    __NSBeep()
                }
            }
        }

        lastProcessedIndex = text.endIndex
    }
}
