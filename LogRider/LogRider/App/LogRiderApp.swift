//
//  LogRiderApp.swift
//  LogRider
//
//  Created by Marin Todorov on 8/30/23.
//

import SwiftUI

@main
struct LogRiderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var preferencesModel: PreferencesModel

    init() {
        // Create the preferences
        preferencesModel = PreferencesModel(

        )
    }

    var body: some Scene {
        ConsoleScene(
            preferences: preferencesModel
        )
    }
}
