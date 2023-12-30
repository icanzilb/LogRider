//
//  Scene.swift
//  LogRider
//
//  Created by Marin Todorov on 8/30/23.
//

import SwiftUI

extension Scene {
  func contentResizable() -> some Scene {
      if #available(macOS 13.0, *) {
          return windowResizability(.contentSize)
      } else {
          return self
      }
  }
}

func toggleSidebar() {
    #if os(iOS)
    #else
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    #endif
}
