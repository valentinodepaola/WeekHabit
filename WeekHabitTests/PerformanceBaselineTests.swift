import SwiftData
import XCTest
@testable import WeekHabit

/// Línea base de rendimiento del dominio.
///
/// Cada medición corre sobre dos tamaños de dataset y reporta el factor de crecimiento
/// entre ambos. Ese factor es lo que decide el arreglo: un crecimiento proporcional se
/// resuelve cacheando el resultado, uno cuadrático obliga a indexar las entradas por día.
///
/// Los números observados viven en `TESTING.md`. Los techos de acá están fijados en ~5×
/// lo observado: solo atrapan regresiones catastróficas, no la varianza normal entre
/// máquinas o corridas.
@MainActor
final class PerformanceBaselineTests: XCTestCase {

    /// Las métricas de colección escalan con la cantidad de hábitos; las métricas por
    /// hábito escalan con el largo del historial.
    private enum Size {
        static let fewHabits = 5
        static let manyHabits = 15
        static let shortHistoryDays = 365
        static let longHistoryDays = 1_095
    }

    /// Techo por medición, aplicado al tamaño grande. Fijados en ~5× lo medido con el
    /// índice por día; los números observados están en `TESTING.md`.
    ///
    /// A diferencia de la primera versión, estos sí protegen: el margen de 5× cubre la
    /// varianza entre máquinas, pero cualquier regresión que devuelva un escaneo por día
    /// al dominio los rompe por orden de magnitud.
    private enum Ceiling {
        static let insightSnapshot = Duration.milliseconds(650)
        static let insightReadinessAndConfidence = Duration.milliseconds(15)
        static let experimentSuggestions = Duration.milliseconds(250)
        static let urgeInsights = Duration.milliseconds(10)
        static let weekAggregates = Duration.milliseconds(300)
        static let todayCollections = Duration.milliseconds(250)
        static let bestStreak = Duration.milliseconds(50)
        static let currentStreakBreakdown = Duration.milliseconds(10)
        static let completionMatrix = Duration.milliseconds(15)
    }

    private let reference = TestFactory.date(day: 15)

    // MARK: - Familia A: métricas de colección

    func testCollectionMetricsScalingWithHabitCount() throws {
        let few = try makeStore(habitCount: Size.fewHabits, days: Size.shortHistoryDays)
        let many = try makeStore(habitCount: Size.manyHabits, days: Size.shortHistoryDays)

        measureScaling(
            "Insights snapshot",
            ceiling: Ceiling.insightSnapshot,
            smallLabel: "\(Size.fewHabits) hábitos",
            small: { _ = few.habits.globalInsightSnapshot(reference: self.reference) },
            largeLabel: "\(Size.manyHabits) hábitos",
            large: { _ = many.habits.globalInsightSnapshot(reference: self.reference) }
        )

        measureScaling(
            "Insights readiness + confianza",
            ceiling: Ceiling.insightReadinessAndConfidence,
            smallLabel: "\(Size.fewHabits) hábitos",
            small: {
                _ = few.habits.insightReadiness(reference: self.reference)
                _ = few.habits.rhythmConfidence(reference: self.reference)
            },
            largeLabel: "\(Size.manyHabits) hábitos",
            large: {
                _ = many.habits.insightReadiness(reference: self.reference)
                _ = many.habits.rhythmConfidence(reference: self.reference)
            }
        )

        measureScaling(
            "Sugerencias de experimentos",
            ceiling: Ceiling.experimentSuggestions,
            smallLabel: "\(Size.fewHabits) hábitos",
            small: {
                _ = few.buildHabits.rhythmExperimentSuggestions(reference: self.reference)
            },
            largeLabel: "\(Size.manyHabits) hábitos",
            large: {
                _ = many.buildHabits.rhythmExperimentSuggestions(reference: self.reference)
            }
        )

        measureScaling(
            "Insights de urges",
            ceiling: Ceiling.urgeInsights,
            smallLabel: "\(Size.fewHabits) hábitos",
            small: {
                _ = few.breakHabits.urgePeakHourInsight(reference: self.reference)
                _ = few.breakHabits.urgeHourBuckets(reference: self.reference)
            },
            largeLabel: "\(Size.manyHabits) hábitos",
            large: {
                _ = many.breakHabits.urgePeakHourInsight(reference: self.reference)
                _ = many.breakHabits.urgeHourBuckets(reference: self.reference)
            }
        )

        measureScaling(
            "Agregados de Week",
            ceiling: Ceiling.weekAggregates,
            smallLabel: "\(Size.fewHabits) hábitos",
            small: { self.computeWeekAggregates(for: few.habits) },
            largeLabel: "\(Size.manyHabits) hábitos",
            large: { self.computeWeekAggregates(for: many.habits) }
        )

        measureScaling(
            "Colecciones de Today",
            ceiling: Ceiling.todayCollections,
            smallLabel: "\(Size.fewHabits) hábitos",
            small: { self.computeTodayCollections(for: few.habits) },
            largeLabel: "\(Size.manyHabits) hábitos",
            large: { self.computeTodayCollections(for: many.habits) }
        )
    }

    // MARK: - Familia B: métricas por hábito

    func testPerHabitMetricsScalingWithHistoryLength() throws {
        let shortHistory = try makeStore(habitCount: 1, days: Size.shortHistoryDays)
        let longHistory = try makeStore(habitCount: 1, days: Size.longHistoryDays)

        let shortHabit = try XCTUnwrap(shortHistory.habits.first)
        let longHabit = try XCTUnwrap(longHistory.habits.first)

        measureScaling(
            "bestStreak",
            ceiling: Ceiling.bestStreak,
            smallLabel: "\(Size.shortHistoryDays) días",
            small: { _ = shortHabit.bestStreak(reference: self.reference) },
            largeLabel: "\(Size.longHistoryDays) días",
            large: { _ = longHabit.bestStreak(reference: self.reference) }
        )

        measureScaling(
            "currentStreakBreakdown",
            ceiling: Ceiling.currentStreakBreakdown,
            smallLabel: "\(Size.shortHistoryDays) días",
            small: { _ = shortHabit.currentStreakBreakdown(reference: self.reference) },
            largeLabel: "\(Size.longHistoryDays) días",
            large: { _ = longHabit.currentStreakBreakdown(reference: self.reference) }
        )

        measureScaling(
            "completionMatrix (10 semanas)",
            ceiling: Ceiling.completionMatrix,
            smallLabel: "\(Size.shortHistoryDays) días",
            small: { _ = shortHabit.completionMatrix(weeks: 10, reference: self.reference) },
            largeLabel: "\(Size.longHistoryDays) días",
            large: { _ = longHabit.completionMatrix(weeks: 10, reference: self.reference) }
        )
    }

    // MARK: - Dataset

    /// Un store sembrado más los cortes de hábitos que las métricas necesitan.
    private struct Dataset {
        let store: TestStore
        let habits: [Habit]

        var buildHabits: [Habit] { habits.filter { !$0.isBreakHabit } }
        var breakHabits: [Habit] { habits.filter(\.isBreakHabit) }
    }

    private func makeStore(habitCount: Int, days: Int) throws -> Dataset {
        let store = try TestStore()
        let habits = try TestHistoryFactory.seedHistory(
            habitCount: habitCount,
            days: days,
            reference: reference,
            in: store
        )
        return Dataset(store: store, habits: habits)
    }

    // MARK: - Réplicas de lo que calculan las vistas

    /// Equivale a `visibleHabits`, `totalGoal`, `completedThisWeek` y los 7 `dayPulse`
    /// de `WeekView`.
    private func computeWeekAggregates(for habits: [Habit]) {
        let weekRange = AppCalendar.weekRange(containing: reference)
        let daysInWeek = (0..<7).compactMap {
            AppCalendar.current.date(byAdding: .day, value: $0, to: weekRange.lowerBound)
        }

        let visibleHabits = habits.filter { habit in
            daysInWeek.contains { habit.isLoggable(on: $0) || habit.isCompleted(on: $0) }
        }

        _ = visibleHabits.reduce(0) { $0 + $1.targetDaysPerWeek }
        _ = visibleHabits.reduce(0) { $0 + $1.completedDaysThisWeek(reference: reference) }

        for day in daysInWeek {
            let scheduled = visibleHabits.filter { $0.isLoggable(on: day) }
            _ = scheduled.filter { $0.isCompleted(on: day) }.count
        }
    }

    /// Equivale a `todayHabits` y sus cuatro particiones en `TodayView`, que es
    /// exactamente lo que la Fase 3 va a reescribir.
    private func computeTodayCollections(for habits: [Habit]) {
        let todayHabits = habits.loggableToday(on: reference)
        _ = todayHabits.pendingToday(on: reference)
        _ = todayHabits.completedToday(on: reference)
        _ = todayHabits.skippedToday(on: reference)
        _ = todayHabits.slippedToday(on: reference)
    }

    // MARK: - Medición

    /// Mide la misma métrica en dos tamaños, reporta ambos y el factor de crecimiento,
    /// y asierta el tamaño grande contra el techo.
    private func measureScaling(
        _ name: String,
        ceiling: Duration,
        smallLabel: String,
        small: () -> Void,
        largeLabel: String,
        large: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let smallAverage = averageDuration(of: small)
        let largeAverage = averageDuration(of: large)

        let smallMilliseconds = milliseconds(smallAverage)
        let largeMilliseconds = milliseconds(largeAverage)
        let growth = smallMilliseconds > 0 ? largeMilliseconds / smallMilliseconds : 0

        // El reporte completo va en el mensaje de la aserción a propósito: cuando un techo
        // se rompe, lo primero que hace falta es ver cómo escala, no solo el número que falló.
        let report = String(
            format: "[perf] %@ | %@: %.2f ms | %@: %.2f ms | factor %.1fx",
            name, smallLabel, smallMilliseconds, largeLabel, largeMilliseconds, growth
        )
        print(report)

        // El print solo se ve corriendo desde Xcode. El attachment queda dentro del
        // .xcresult, así que el número también se puede leer desde consola o CI sin
        // tener que romper el test para verlo.
        let attachment = XCTAttachment(string: report)
        attachment.name = "perf: \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertLessThan(
            largeAverage,
            ceiling,
            report,
            file: file,
            line: line
        )
    }

    /// Descarta la primera pasada como calentamiento y promedia las siguientes.
    ///
    /// Tres iteraciones alcanzan para un promedio estable y mantienen la suite en un
    /// tiempo razonable: con la línea base actual, cada pasada de Insights cuesta segundos.
    private func averageDuration(of operation: () -> Void, iterations: Int = 3) -> Duration {
        operation()

        let clock = ContinuousClock()
        var total = Duration.zero
        for _ in 0..<iterations {
            total += clock.measure(operation)
        }

        return total / iterations
    }

    private func milliseconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) * 1_000
            + Double(components.attoseconds) / 1_000_000_000_000_000
    }
}
