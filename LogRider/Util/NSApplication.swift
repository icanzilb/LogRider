//
//  NSApplication.swift
//  Tile
//
//  Created by Marin Todorov on 11/12/22.
//

import Foundation
import AppKit

extension NSApplication {
    func closeWindows(withTitlePrefix prefix: String, max: Int = .max) {
        DispatchQueue.main.async {
            NSApplication.shared.windows.filter({ prefix.isEmpty ? true : $0.title.hasPrefix(prefix) })
                .prefix(max)
                .forEach { $0.close() }
        }
    }

    func windowsWithTitlePrefix(_ prefix: String, block: @escaping (NSWindow) -> Void) {
        //DispatchQueue.main.async {
            NSApplication.shared.windows.filter({ prefix.isEmpty ? true : $0.title.hasPrefix(prefix) })
                .forEach {
                    block($0)
                }
        //}
    }
}
