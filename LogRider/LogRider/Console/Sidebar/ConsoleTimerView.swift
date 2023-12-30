//
//  ConsoleTimerView.swift
//  Tile
//
//  Created by Marin Todorov on 4/9/23.
//

import SwiftUI
import Combine

struct ConsoleTimerView: View {
    @ObservedObject var model: ConsoleValueModel

    @State var isRunning = false {
        didSet {
            if isRunning {
                timerPublisher = Timer.publish(every: 1, on: RunLoop.main, in: .default)
                    .autoconnect()
                    .sink(receiveValue: { date in
                        animationProxyDuration = date.timeIntervalSinceReferenceDate - start
                    })
            } else {
                timerPublisher?.cancel()
                timerPublisher = nil
            }
        }
    }
    @State var timerPublisher: AnyCancellable?

    @State var start: TimeInterval = 0.0
    @State var duration: TimeInterval = 0.0

    @State var animationProxyDuration: TimeInterval = 0.0 {
        willSet {
            duration = newValue
        }
    }

    @State var totalCompletedDuration: TimeInterval = 0.0

    @State var repetitions = 0

    var totalDisplayDuration: String {
        if isRunning {
            guard totalCompletedDuration > 0 else { return "00:00" }
            return timerFormatted(totalCompletedDuration + duration)
        } else {
            return timerFormatted(totalCompletedDuration)
        }
    }

    var displayDuration: String {
        guard duration > 0 else { return "00:00" }
        return timerFormatted(duration)
    }

    @State var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isRunning ? "play" : "pause")
                .font(.body)
                .padding(.top, 2)
                .frame(width: 20)
                .foregroundColor(isRunning ? Color.accentColor : Color.secondary)

            if repetitions < 2 || !isHovered {
                Text(displayDuration)
                    .foregroundColor(isRunning ? Color.accentColor : Color.secondary)
            }

            if repetitions > 1 {
                Text("(\(repetitions)x)")
                    .foregroundColor(Color.secondary)
            }
            if repetitions > 1 && isHovered {
                HStack(spacing: 3) {
                    Image(systemName: "sum")
                        .font(.caption.bold())
                        .padding(.top, 2)
                        .scaleEffect(x: 0.9, y: 0.9)

                    Text(totalDisplayDuration)
                }
                .font(.body.monospacedDigit())
                .foregroundColor(Color.secondary)
            }
            Spacer()
        }
        .onHover { isHovered in
            withAnimation {
                self.isHovered = isHovered
            }
        }
        .font(.body.monospacedDigit())
        .onReceive(model.$value, perform: { newValue in
            if newValue.hasPrefix("begin-"),
               let start = Double(newValue.components(separatedBy: "-").last!) {

                self.start = start
                duration = 0
                repetitions += 1
                withAnimation {
                    isRunning = true
                }
                return
            }
            if newValue.hasPrefix("end-"),
                let end = Double(newValue.components(separatedBy: "-").last!) {
                withAnimation {
                    isRunning = false
                }
                guard duration > 0 else { return }
                let final = end - start
                if Int(final) != Int(duration) {
                    withAnimation(nil) {
                        duration = end - start
                    }
                }
                totalCompletedDuration += duration
                return
            }
        })
    }
}
