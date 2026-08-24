import XCTest
@testable import WeekHabit

/// `TodayWidgetSnapshot` es lo único del widget que se puede probar: sus vistas viven en la
/// extensión, donde este target no llega. Por eso toda la derivación está acá y no allá.
///
/// Las fechas usan junio de 2026, cuyo día 1 cae lunes: así los días 1 a 7 son una semana
/// completa y las pruebas de agenda flexible no dependen de dónde caiga el corte semanal.
@MainActor
final class TodayWidgetSnapshotTests: XCTestCase {

    private func makeSnapshot(habits: [Habit], on date: Date) -> TodayWidgetSnapshot {
        TodayWidgetSnapshot(habits: habits, referenceDate: date)
    }

    private func namedHabit(_ title: String, colorHex: String = "#c2573c") -> Habit {
        let habit = TestFactory.habit()
        habit.title = title
        habit.colorHex = colorHex
        return habit
    }

    // MARK: - Los cuatro estados

    func testPendingStateCountsWhatIsMissing() throws {
        let day = TestFactory.date(day: 3)
        let habits = (0..<5).map { namedHabit("Hábito \($0)") }
        TestFactory.entry(.completed, habit: habits[0], date: day, value: 1)
        TestFactory.entry(.completed, habit: habits[1], date: day, value: 1)

        let snapshot = makeSnapshot(habits: habits, on: day)

        XCTAssertEqual(snapshot.state, .pending)
        XCTAssertEqual(snapshot.pendingCount, 3)
        XCTAssertEqual(snapshot.completedCount, 2)
        XCTAssertEqual(snapshot.activeCount, 5)
        XCTAssertEqual(snapshot.scheduledCount, 5)
        XCTAssertEqual(snapshot.progress, 0.4, accuracy: 0.0001)
    }

    func testAllDoneStateWhenNothingIsPending() throws {
        let day = TestFactory.date(day: 3)
        let habits = (0..<2).map { namedHabit("Hábito \($0)") }
        for habit in habits {
            TestFactory.entry(.completed, habit: habit, date: day, value: 1)
        }

        let snapshot = makeSnapshot(habits: habits, on: day)

        XCTAssertEqual(snapshot.state, .allDone)
        XCTAssertEqual(snapshot.pendingCount, 0)
        XCTAssertEqual(snapshot.progress, 1, accuracy: 0.0001)
        XCTAssertTrue(snapshot.listedPending.isEmpty)
    }

    /// Nada programado hoy: el hábito existe pero su agenda no lo incluye.
    func testRestStateWhenNothingIsScheduledToday() throws {
        let wednesday = TestFactory.date(day: 3)
        let habit = TestFactory.habit(schedule: .specificDays, activeDays: [.monday])

        let snapshot = makeSnapshot(habits: [habit], on: wednesday)

        XCTAssertEqual(snapshot.state, .rest)
        XCTAssertEqual(snapshot.scheduledCount, 0)
        XCTAssertFalse(
            snapshot.restedEverythingScheduled,
            "Sin nada programado no se descansó nada: el detalle no debe decir lo contrario."
        )
    }

    /// El otro camino al descanso: sí había hábitos, y el usuario los marcó como descanso.
    func testRestStateWhenEverythingScheduledWasRested() throws {
        let day = TestFactory.date(day: 3)
        let habits = (0..<2).map { namedHabit("Hábito \($0)") }
        for habit in habits {
            TestFactory.entry(.skipped, habit: habit, date: day)
        }

        let snapshot = makeSnapshot(habits: habits, on: day)

        XCTAssertEqual(snapshot.state, .rest)
        XCTAssertEqual(snapshot.scheduledCount, 2)
        XCTAssertEqual(snapshot.activeCount, 0)
        XCTAssertTrue(snapshot.restedEverythingScheduled)
    }

    func testEmptyStateWithoutAnyHabit() throws {
        let snapshot = makeSnapshot(habits: [], on: TestFactory.date(day: 3))

        XCTAssertEqual(snapshot.state, .empty)
        XCTAssertEqual(snapshot.pendingCount, 0)
        XCTAssertEqual(snapshot.scheduledCount, 0)
    }

    // MARK: - Reglas de pendientes

    func testRestedHabitsDoNotCountAsPending() throws {
        let day = TestFactory.date(day: 3)
        let pending = namedHabit("Pendiente")
        let rested = namedHabit("Descansado")
        TestFactory.entry(.skipped, habit: rested, date: day)

        let snapshot = makeSnapshot(habits: [pending, rested], on: day)

        XCTAssertEqual(snapshot.state, .pending)
        XCTAssertEqual(snapshot.pendingCount, 1)
        XCTAssertEqual(snapshot.listedPending.map(\.title), ["Pendiente"])
        XCTAssertEqual(
            snapshot.activeCount,
            1,
            "El descansado sale del denominador: si no, el progreso nunca llegaría a uno."
        )
    }

    func testFlexibleHabitThatMetItsWeeklyTargetIsNotPending() throws {
        let wednesday = TestFactory.date(day: 3)
        let habit = TestFactory.habit(schedule: .timesPerWeek, targetDaysPerWeek: 2)
        TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 1), value: 1)
        TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 2), value: 1)

        let snapshot = makeSnapshot(habits: [habit], on: wednesday)

        XCTAssertEqual(snapshot.pendingCount, 0)
        XCTAssertEqual(snapshot.state, .allDone)
    }

    func testListedPendingIsTruncatedAndTheRestIsCounted() throws {
        let day = TestFactory.date(day: 3)
        let titles = ["Leer", "Correr", "Meditar", "Estirar", "Escribir"]
        let habits = titles.map { namedHabit($0) }

        let snapshot = makeSnapshot(habits: habits, on: day)

        XCTAssertEqual(snapshot.pendingCount, 5)
        XCTAssertEqual(snapshot.listedPending.count, TodayWidgetSnapshot.maxListedHabits)
        XCTAssertEqual(
            snapshot.listedPending.map(\.title),
            ["Leer", "Correr", "Meditar"],
            "El widget lista en el mismo orden que Hoy, no en uno propio."
        )
        XCTAssertEqual(snapshot.hiddenPendingCount, 2)
    }

    func testListedPendingCarriesTheHabitColor() throws {
        let day = TestFactory.date(day: 3)
        let habit = namedHabit("Leer", colorHex: "#5c89a8")

        let snapshot = makeSnapshot(habits: [habit], on: day)

        XCTAssertEqual(snapshot.listedPending.map(\.colorHex), ["#5c89a8"])
    }

    func testClosedDayListsWhatWasAchieved() throws {
        let day = TestFactory.date(day: 3)
        let titles = ["Leer", "Correr", "Meditar", "Estirar"]
        let habits = titles.map { namedHabit($0) }
        for habit in habits {
            TestFactory.entry(.completed, habit: habit, date: day, value: 1)
        }

        let snapshot = makeSnapshot(habits: habits, on: day)

        XCTAssertEqual(snapshot.state, .allDone)
        XCTAssertEqual(
            snapshot.listedCompleted.map(\.title),
            ["Leer", "Correr", "Meditar"],
            "El día cerrado muestra qué se logró, truncado al mismo máximo que los pendientes."
        )
        XCTAssertTrue(snapshot.listedPending.isEmpty)
    }

    func testCompletedListIsEmptyWhileNothingIsDone() throws {
        let day = TestFactory.date(day: 3)

        let snapshot = makeSnapshot(habits: [namedHabit("Leer")], on: day)

        XCTAssertEqual(snapshot.state, .pending)
        XCTAssertTrue(snapshot.listedCompleted.isEmpty)
    }

    // MARK: - Racha

    func testStreakIsOnlyResolvedWhenTheDayIsClosed() throws {
        let day = TestFactory.date(day: 3)
        let closed = namedHabit("Cerrado")
        for offset in 1...3 {
            TestFactory.entry(
                .completed,
                habit: closed,
                date: TestFactory.date(day: offset),
                value: 1
            )
        }

        let closedSnapshot = makeSnapshot(habits: [closed], on: day)
        XCTAssertEqual(closedSnapshot.state, .allDone)
        XCTAssertEqual(closedSnapshot.bestCurrentStreak, 3)

        // Un pendiente más y el estado deja de ser cerrado: la racha no se calcula, porque
        // ningún estado salvo el cerrado la muestra.
        let pendingSnapshot = makeSnapshot(habits: [closed, namedHabit("Pendiente")], on: day)
        XCTAssertEqual(pendingSnapshot.state, .pending)
        XCTAssertEqual(pendingSnapshot.bestCurrentStreak, 0)
    }

    func testStreakTakesTheLongestAmongTodayHabits() throws {
        let day = TestFactory.date(day: 3)
        let longer = namedHabit("Larga")
        let shorter = namedHabit("Corta")
        for offset in 1...3 {
            TestFactory.entry(.completed, habit: longer, date: TestFactory.date(day: offset), value: 1)
        }
        TestFactory.entry(.completed, habit: shorter, date: day, value: 1)

        let snapshot = makeSnapshot(habits: [longer, shorter], on: day)

        XCTAssertEqual(snapshot.state, .allDone)
        XCTAssertEqual(snapshot.bestCurrentStreak, 3)
    }

    // MARK: - Mañana

    func testTomorrowCountLooksAtTheNextDay() throws {
        let wednesday = TestFactory.date(day: 3)
        let onlyThursday = TestFactory.habit(schedule: .specificDays, activeDays: [.thursday])

        let snapshot = makeSnapshot(habits: [onlyThursday], on: wednesday)

        XCTAssertEqual(snapshot.state, .rest)
        XCTAssertEqual(snapshot.tomorrowCount, 1)
    }

    // MARK: - Coherencia con Hoy

    /// El widget y la pantalla de Hoy no pueden discrepar: si lo hicieran, el usuario vería
    /// un número en el bloqueo y otro distinto al entrar, que es exactamente la confianza
    /// que esta feature necesita no romper.
    func testSnapshotAgreesWithTodayViewData() throws {
        let day = TestFactory.date(day: 3)
        let habits = (0..<4).map { namedHabit("Hábito \($0)") }
        TestFactory.entry(.completed, habit: habits[0], date: day, value: 1)
        TestFactory.entry(.skipped, habit: habits[1], date: day)

        let snapshot = makeSnapshot(habits: habits, on: day)
        let todayData = TodayViewData(
            habits: habits,
            streakFreezes: [],
            weeklyReviews: [],
            weeklyReviewWeekday: .sunday,
            referenceDate: day
        )

        XCTAssertEqual(snapshot.pendingCount, todayData.remainingCount)
        XCTAssertEqual(snapshot.completedCount, todayData.partition.completedCount)
        XCTAssertEqual(snapshot.activeCount, todayData.partition.activeCount)
        XCTAssertEqual(snapshot.progress, todayData.partition.progress, accuracy: 0.0001)
        XCTAssertEqual(snapshot.tomorrowCount, todayData.tomorrowHabitsCount)
    }
}
