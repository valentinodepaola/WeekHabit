//
//  AppPerformance.swift
//  WeekHabit
//

import Foundation

#if DEBUG
import os
#endif

enum AppPerformance {
    static func measure<T>(_ name: String, operation: () -> T) -> T {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let elapsedMilliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1_000
        logger.debug("\(name, privacy: .public): \(elapsedMilliseconds, privacy: .public) ms")
        return result
        #else
        return operation()
        #endif
    }

    #if DEBUG
    private static let logger = Logger(subsystem: "WeekHabit", category: "Performance")
    #endif
}
