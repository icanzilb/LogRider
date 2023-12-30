//
//  Print.swift
//  Tile
//
//  Created by Marin Todorov on 10/31/22.
//

import Foundation
import os

func print(_ text: String) {
    #if DEBUG
    //os_log("\(text, privacy: .public)")
    Swift.print(text)
    #endif
}
