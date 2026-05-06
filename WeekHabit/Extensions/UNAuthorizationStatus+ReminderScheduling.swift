//
//  UNAuthorizationStatus+ReminderScheduling.swift
//  WeekHabit
//

import UserNotifications

extension UNAuthorizationStatus {
    var allowsReminderScheduling: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
}
