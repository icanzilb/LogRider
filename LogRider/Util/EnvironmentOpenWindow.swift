//
//  Tile
//
//  Created by Marin Todorov on 12/28/22.
//

import Foundation
import Cocoa

enum Arguments {
    struct Argument {
        let id: String
        let argument: Any
    }
    static fileprivate let windowArguments = Synchronized([Argument]())

    static func set<T>(_ t: T) {
        let id = String(describing: T.self)
        windowArguments.sync { args in
            args.append(Argument(id: id, argument: t))
        }
    }

    static func get<T>(_ t: T.Type) -> T? {
        let id = String(describing: t)
        return windowArguments.sync({ args in
            if let index = args.firstIndex(where: { $0.id == id }) {
                return (args.remove(at: index).argument as! T)
            }
            return nil
        })
    }
}

fileprivate let windowIDs = Synchronized([String: String]())

func openAppWindow<T>(id: String, argument: T = Optional<String>(nil), singleInstance: Bool = true) {
    if singleInstance, let title = windowIDs.sync({ $0[id] }) {
        // Already open
        NSApp.windowsWithTitlePrefix(title) { window in
            window.makeKey()
            window.orderFrontRegardless()
        }
        return
    }
    Arguments.set(argument)
    NSWorkspace.shared.open(URL(string: "\(appURLScheme)://" + id)!)
}

func didShowWindow(id: String, title: String) {
    windowIDs.sync({ $0[id] = title })
}

func didHideWindow(id: String) {
    windowIDs.sync({ _ = $0.removeValue(forKey: id) })
}
