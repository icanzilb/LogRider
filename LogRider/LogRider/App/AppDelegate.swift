//
//  AppDelegate.swift
//  LogRider
//
//  Created by Marin Todorov on 8/30/23.
//

import Foundation
import Cocoa
import SwiftUI
import Combine

extension Notification.Name {
    static let openProcessName: Notification.Name = .init(rawValue: "openProcessName")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {

    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])
        DispatchQueue.main.async { [weak self] in
            self?.appDidStart()
        }
    }

    func appDidStart() {
        print("Started")
    }

    func closeApp() {
        NSApplication.shared.terminate(nil)
    }
}
