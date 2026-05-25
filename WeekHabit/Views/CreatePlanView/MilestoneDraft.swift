//
//  MilestoneDraft.swift
//  WeekHabit
//

import Foundation

struct MilestoneDraft: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var targetDate: Date
}
