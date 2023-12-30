//
//  PreferencesModel.swift
//  LogRider
//
//  Created by Marin Todorov on 8/30/23.
//

import Foundation
import Combine
import SwiftUI

class PreferencesModel: ObservableObject {
    @Published var autoCapture = defaultAutoCaptureGroups
    @Published var enableSignpostData = true
    @Published var ignoreLogsWithNoSubsystem = true

    @Published var recent: [RecentItem] = [] {
        didSet {
            recentData = try! JSONEncoder().encode(recent)
        }
    }

    @AppStorage("recent") var recentData = Data()
}
