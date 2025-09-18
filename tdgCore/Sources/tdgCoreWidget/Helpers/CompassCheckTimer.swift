//
//  ReviewTimer.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 30/01/2024.
//

import Foundation
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: CompassCheckTimer.self)
)

public typealias OnCompassCheckTimer = @Sendable () -> Void

final public class CompassCheckTimer {
    public var timer: Timer? = nil

    public init() {

    }

    deinit {
        timer?.invalidate()
    }

    public func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    public func setTimer(forWhen fireAt: Date, onCompassCheckTimer: @escaping OnCompassCheckTimer) {
        cancelTimer()
        timer = Timer(fire: fireAt, interval: 1, repeats: false) { timer in
            logger.info("Time for Compass Check")
            onCompassCheckTimer()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }

    }
}
