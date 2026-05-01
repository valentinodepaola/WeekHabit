//
//  AppLaunchTiming.swift
//  WeekHabit
//

import SwiftUI

enum AppLaunchTiming {
    static func holdDuration(reduceMotion: Bool) -> UInt64 {
        reduceMotion ? 820_000_000 : 2_350_000_000
    }

    static func releaseDuration(reduceMotion: Bool) -> UInt64 {
        reduceMotion ? 260_000_000 : 640_000_000
    }

    static func contentAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.18)
            : .easeOut(duration: 0.42)
    }

    static func splashExitAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.22)
            : .easeInOut(duration: 0.62)
    }
}
