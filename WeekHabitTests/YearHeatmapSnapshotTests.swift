import SwiftData
import XCTest
@testable import WeekHabit

/// `YearHeatmapSnapshot` es lo único del widget "Año de constancia" que se puede probar: la
/// vista vive en la extensión, donde este target no llega. Toda la agregación por día está
/// acá y se prueba acá.
///
/// Las fechas usan junio de 2026, cuyo día 1 cae lunes: los días 1, 8, 15 y 22 son lunes, así
/// que las ventanas de N semanas caen limpias sobre los días del mes.
@MainActor
final class YearHeatmapSnapshotTests: XCTestCase {

    /// Lunes 2026-06-22. Con `weeks: 4` la ventana va del 2026-06-01 al 2026-06-28.
    private let reference = TestFactory.date(day: 22)

    private func dailyHabit(createdOn day: Int = 1) -> Habit {
        TestFactory.habit(schedule: .daily, createdAt: TestFactory.date(day: day))
    }

    private func day(_ dayNumber: Int, in snapshot: YearHeatmapSnapshot) -> YearHeatmapDay {
        let target = TestFactory.date(day: dayNumber)
        let match = snapshot.weeks.flatMap(\.days).first { AppCalendar.isSameDay($0.date, target) }
        return match ?? YearHeatmapDay(
            date: target, scheduledCount: -1, completedCount: -1, intensity: -1, kind: .outOfRange
        )
    }

    // MARK: - Intensidad

    func testPartialCompletionYieldsFractionalIntensity() throws {
        let habits = (0..<4).map { _ in dailyHabit() }
        TestFactory.entry(.completed, habit: habits[0], date: TestFactory.date(day: 10), value: 1)

        let snapshot = YearHeatmapSnapshot(habits: habits, referenceDate: reference, weeks: 4)
        let d = day(10, in: snapshot)

        XCTAssertEqual(d.scheduledCount, 4)
        XCTAssertEqual(d.completedCount, 1)
        XCTAssertEqual(d.intensity, 0.25, accuracy: 0.0001)
        XCTAssertEqual(d.kind, .done(level: 1), "un cuarto cae en el primer balde")
    }

    func testFullDayIsLevelThreeAndCountsAsPerfect() throws {
        let habits = (0..<3).map { _ in dailyHabit() }
        for habit in habits {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 9), value: 1)
        }

        let snapshot = YearHeatmapSnapshot(habits: habits, referenceDate: reference, weeks: 4)
        let d = day(9, in: snapshot)

        XCTAssertEqual(d.completedCount, 3)
        XCTAssertEqual(d.intensity, 1, accuracy: 0.0001)
        XCTAssertEqual(d.kind, .done(level: 3))
        // El 2026-06-01..06-22 son 22 días, todos con hábitos diarios programados.
        XCTAssertEqual(snapshot.trackedDays, 22)
        XCTAssertEqual(snapshot.perfectDays, 1)
        XCTAssertEqual(snapshot.completionRate, 1.0 / 22.0, accuracy: 0.0001)
    }

    func testScheduledButNothingDoneIsNotNothingScheduled() throws {
        let habits = (0..<2).map { _ in dailyHabit() }

        let snapshot = YearHeatmapSnapshot(habits: habits, referenceDate: reference, weeks: 4)
        let d = day(10, in: snapshot)

        XCTAssertEqual(d.scheduledCount, 2)
        XCTAssertEqual(d.completedCount, 0)
        XCTAssertEqual(d.intensity, 0)
        XCTAssertEqual(d.kind, .scheduledNothingDone)
    }

    func testDayWithNothingOnAFixedSchedule() throws {
        let onlyMonday = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday],
            createdAt: TestFactory.date(day: 1)
        )

        let snapshot = YearHeatmapSnapshot(habits: [onlyMonday], referenceDate: reference, weeks: 4)

        // 2026-06-10 es miércoles.
        let wednesday = day(10, in: snapshot)
        XCTAssertEqual(wednesday.scheduledCount, 0)
        XCTAssertEqual(wednesday.kind, .nothingScheduled)

        // 2026-06-08 es lunes: ahí sí está programado.
        let monday = day(8, in: snapshot)
        XCTAssertEqual(monday.scheduledCount, 1)
        XCTAssertEqual(monday.kind, .scheduledNothingDone)
    }

    // MARK: - Rango

    func testDaysBeforeTheFirstHabitAreOutOfRange() throws {
        let habit = dailyHabit(createdOn: 10)

        let snapshot = YearHeatmapSnapshot(habits: [habit], referenceDate: reference, weeks: 4)

        XCTAssertEqual(day(5, in: snapshot).kind, .outOfRange)
        XCTAssertEqual(day(10, in: snapshot).kind, .scheduledNothingDone, "el día de creación ya cuenta")
    }

    func testFutureDaysAreOutOfRange() throws {
        let habit = dailyHabit()
        // Jueves 2026-06-18. La última semana de la ventana llega hasta el domingo 06-21.
        let thursday = TestFactory.date(day: 18)

        let snapshot = YearHeatmapSnapshot(habits: [habit], referenceDate: thursday, weeks: 3)

        XCTAssertEqual(day(20, in: snapshot).kind, .outOfRange)
        XCTAssertEqual(day(18, in: snapshot).kind, .scheduledNothingDone)
    }

    func testSpecificDaysHabitOnlyCountsOnItsDays() throws {
        let daily = dailyHabit()
        let monWed = TestFactory.habit(
            schedule: .specificDays,
            activeDays: [.monday, .wednesday],
            createdAt: TestFactory.date(day: 1)
        )

        let snapshot = YearHeatmapSnapshot(habits: [daily, monWed], referenceDate: reference, weeks: 4)

        XCTAssertEqual(day(8, in: snapshot).scheduledCount, 2, "lunes: los dos")
        XCTAssertEqual(day(9, in: snapshot).scheduledCount, 1, "martes: solo el diario")
        XCTAssertEqual(day(10, in: snapshot).scheduledCount, 2, "miércoles: los dos")
    }

    // MARK: - Exclusiones

    func testFlexibleHabitIsExcludedFromTheGrid() throws {
        let flexible = TestFactory.habit(
            schedule: .timesPerWeek,
            targetDaysPerWeek: 2,
            createdAt: TestFactory.date(day: 1)
        )
        TestFactory.entry(.completed, habit: flexible, date: TestFactory.date(day: 8), value: 1)
        TestFactory.entry(.completed, habit: flexible, date: TestFactory.date(day: 9), value: 1)

        let snapshot = YearHeatmapSnapshot(habits: [flexible], referenceDate: reference, weeks: 4)

        XCTAssertTrue(snapshot.hasAnyHabit)
        XCTAssertEqual(snapshot.trackedDays, 0, "un flexible no aporta días a la grilla")
        XCTAssertEqual(day(8, in: snapshot).scheduledCount, 0)
        XCTAssertEqual(day(8, in: snapshot).kind, .nothingScheduled)
        XCTAssertFalse(snapshot.weeks.flatMap(\.days).contains { if case .done = $0.kind { return true } else { return false } })
    }

    func testFreezeProtectedHabitIsNeutral() throws {
        let store = try TestStore()
        let completed = dailyHabit()
        let frozen = dailyHabit()
        store.insert(completed)
        store.insert(frozen)

        let target = TestFactory.date(day: 10)
        TestFactory.entry(.completed, habit: completed, date: target, value: 1)
        store.context.insert(StreakFreeze(habit: frozen, protectedDate: target))
        try store.save()

        let snapshot = YearHeatmapSnapshot(habits: [completed, frozen], referenceDate: reference, weeks: 4)
        let d = day(10, in: snapshot)

        XCTAssertEqual(d.scheduledCount, 1, "el hábito con comodín sale del denominador")
        XCTAssertEqual(d.completedCount, 1)
        XCTAssertEqual(d.intensity, 1, accuracy: 0.0001)
        XCTAssertEqual(d.kind, .done(level: 3))
    }

    func testSkippedHabitIsNeutral() throws {
        let completed = dailyHabit()
        let rested = dailyHabit()

        let target = TestFactory.date(day: 10)
        TestFactory.entry(.completed, habit: completed, date: target, value: 1)
        TestFactory.entry(.skipped, habit: rested, date: target)

        let snapshot = YearHeatmapSnapshot(habits: [completed, rested], referenceDate: reference, weeks: 4)
        let d = day(10, in: snapshot)

        XCTAssertEqual(d.scheduledCount, 1, "el descanso sale del denominador, igual que en Hoy")
        XCTAssertEqual(d.completedCount, 1)
        XCTAssertEqual(d.intensity, 1, accuracy: 0.0001)
    }

    // MARK: - Forma de la ventana

    func testWindowShape() throws {
        let snapshot = YearHeatmapSnapshot(habits: [dailyHabit()], referenceDate: reference, weeks: 6)

        XCTAssertEqual(snapshot.weeks.count, 6)
        XCTAssertEqual(snapshot.weeks.first?.id, 0)
        XCTAssertEqual(snapshot.weeks.last?.id, 5)
        XCTAssertEqual(
            snapshot.weeks.last?.start,
            AppCalendar.weekRange(containing: reference).lowerBound
        )

        for week in snapshot.weeks {
            XCTAssertEqual(week.days.count, 7)
            XCTAssertEqual(AppCalendar.weekday(of: week.days[0].date), .monday)
            XCTAssertEqual(AppCalendar.weekday(of: week.days[6].date), .sunday)
        }
    }

    func testNoHabitsProducesAnEmptyGrid() throws {
        let snapshot = YearHeatmapSnapshot(habits: [], referenceDate: reference, weeks: 4)

        XCTAssertFalse(snapshot.hasAnyHabit)
        XCTAssertEqual(snapshot.weeks.count, 4)
        XCTAssertEqual(snapshot.trackedDays, 0)
        XCTAssertEqual(snapshot.perfectDays, 0)
        XCTAssertEqual(snapshot.completionRate, 0)
        XCTAssertTrue(snapshot.weeks.flatMap(\.days).allSatisfy { $0.kind == .outOfRange })
    }
}
