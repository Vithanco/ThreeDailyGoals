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
        category: String(describing: ReviewTimer.self)
    )

typealias OnReviewTimer = @Sendable () -> ()

final class ReviewTimer : Sendable {
    var timer: Timer? = nil
    
    init() {
        
    }
    
    deinit{
        timer?.invalidate()
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func setTimer( forWhen fireAt: Date, onReviewTimer: @escaping OnReviewTimer) {
        cancelTimer()
        timer = Timer(fire: fireAt, interval: 1, repeats:false) { timer in
            logger.info("Time for Review")
            onReviewTimer()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
    }
}
