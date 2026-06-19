//
//  EntryNoteService.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum EntryNoteService {
    @discardableResult
    static func saveNote(
        _ note: String,
        for entry: HabitEntry,
        modelContext: ModelContext
    ) throws -> Bool {
        let newValue = normalized(note)
        guard entry.note != newValue else { return false }

        entry.note = newValue
        try modelContext.save()
        return true
    }

    private static func normalized(_ note: String) -> String? {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? nil : note
    }
}
