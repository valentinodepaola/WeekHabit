import SwiftData
import XCTest
@testable import WeekHabit

/// Los previews no corren en CI: si el set de muestra deja de guardarse (p. ej. tras un
/// `SchemaV*` nuevo) o deja de mostrar los estados que promete, se rompen todos los canvas a
/// la vez sin que nada avise. Esto lo avisa.
@MainActor
final class PreviewSamplesTests: XCTestCase {
    func testSampleDataSavesInMemoryContainer() throws {
        let container = try PreviewSamples.makeContainer()
        PreviewSamples.insert(into: container.mainContext)
        try container.mainContext.save()

        XCTAssertTrue(container.configurations.allSatisfy(\.isStoredInMemoryOnly))
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Habit>()), 5)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Plan>()), 1)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<HabitExperiment>()), 1)
    }

    func testSampleHabitsShowTheirIntendedStates() {
        let reading = PreviewSamples.readingHabit()
        XCTAssertGreaterThan(reading.displayStreak(), 30, "el comodín debe sostener la racha larga")

        let water = PreviewSamples.waterHabit()
        XCTAssertNotNil(water.recoveryPromptCandidate(), "debe ofrecer recuperación")

        let meditation = PreviewSamples.meditationHabit()
        XCTAssertEqual(meditation.displayStreak(), 0, "debe mostrar la racha rota")

        let plan = PreviewSamples.activePlan()
        XCTAssertFalse(plan.needsReview(), "no debe abrir el cierre del plan encima del preview")
    }
}
