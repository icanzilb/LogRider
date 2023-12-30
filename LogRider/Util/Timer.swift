//
//  Timer.swift
//  LogRider
//
//  Created by Marin Todorov on 8/30/23.
//

import Foundation

extension FloatingPoint {
    var whole: Self { modf(self).0 }
    var fraction: Self { modf(self).1 }
}

func timerFormatted(_ duration: TimeInterval) -> String {
    let minutes = (duration / 60.0).whole
    let seconds = duration.whole - (minutes * 60.0)
    return String(format: "%02.f:%02.f", minutes, seconds)
}
