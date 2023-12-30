//
//  NSAlert.swift
//  Tile
//
//  Created by Marin Todorov on 11/2/22.
//

import Foundation
import Cocoa

class AlertQueue: ObservableObject {
    static let shared = AlertQueue()

    private var alerts = [Alert]()
    private var isRunning = false {
        didSet {
            if isRunning == false, !alerts.isEmpty {
                DispatchQueue.main.async {
                    self.run()
                }
            }
        }
    }

    func add(_ alert: Alert) {
        guard alerts.count < 5 else { return }
        alerts.append(alert)
        if !isRunning { run() }
    }

    func run() {
        if !alerts.isEmpty {
            isRunning = true
            let next = alerts.removeFirst()
            next.show {  [weak self] in
                guard let self else { return }
                self.isRunning = false
            }
        }
    }
}

struct Alert {
    let message: String
    let handlers: [[String: () -> Void]]

    let alert: NSAlert

    init(title: String, message: String, handlers: [[String: () -> Void]]) {
        self.message = message
        self.handlers = handlers

        self.alert = NSAlert()
        self.alert.messageText = title
        self.alert.informativeText = message
        for handler in handlers {
            self.alert.addButton(withTitle: handler.first!.key)
        }
    }

    func show(callback: @escaping () -> Void) {
        DispatchQueue.main.async {
            let result = alert.runModal()

            switch result {
            case .alertFirstButtonReturn:
                self.handlers[0].first!.value()
            case .alertSecondButtonReturn:
                self.handlers[1].first!.value()
            case .alertThirdButtonReturn:
                self.handlers[2].first!.value()
            default: break
            }

            callback()
        }
    }
}
