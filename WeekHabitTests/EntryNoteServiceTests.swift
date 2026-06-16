import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class EntryNoteServiceTests: XCTestCase {
    func testSaveNoteTrimsAndPersistsText() throws {
        let store = try TestStore()
        let entry = makeEntry(in: store)

        let didSave = try EntryNoteService.saveNote(
            "  Felt steady  ",
            for: entry,
            modelContext: store.context
        )

        let entries = try store.context.fetch(FetchDescriptor<HabitEntry>())
        XCTAssertTrue(didSave)
        XCTAssertEqual(entries.first?.note, "Felt steady")
    }

    func testSaveBlankNoteClearsExistingNote() throws {
        let store = try TestStore()
        let entry = makeEntry(in: store, note: "Keep me")

        let didSave = try EntryNoteService.saveNote(
            "   \n ",
            for: entry,
            modelContext: store.context
        )

        let entries = try store.context.fetch(FetchDescriptor<HabitEntry>())
        XCTAssertTrue(didSave)
        XCTAssertNil(entries.first?.note)
    }

    func testSaveUnchangedNoteSkipsPersistence() throws {
        let store = try TestStore()
        let entry = makeEntry(in: store, note: "Same")

        let didSave = try EntryNoteService.saveNote(
            "Same",
            for: entry,
            modelContext: store.context
        )

        XCTAssertFalse(didSave)
        XCTAssertEqual(entry.note, "Same")
    }

    private func makeEntry(
        in store: TestStore,
        note: String? = nil
    ) -> HabitEntry {
        let habit = TestFactory.habit()
        store.insert(habit)
        let entry = HabitEntry(
            date: TestFactory.date(day: 4),
            completedAt: TestFactory.date(day: 4),
            source: .today,
            kind: .completed,
            note: note,
            habit: habit
        )
        store.context.insert(entry)
        return entry
    }
}
