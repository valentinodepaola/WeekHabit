//
//  PreviewSampleData.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

/// Contenedor en memoria con un set de datos de muestra, para los previews de Xcode.
///
/// Nunca abre el almacén del App Group: `isStoredInMemoryOnly` garantiza que el canvas no lee
/// ni escribe lo que la app guarda de verdad. Se usa con `#Preview(traits: .sampleData)`.
///
/// No va bajo `#if DEBUG`: los `#Preview` también se compilan en Release, así que cada uno
/// tendría que envolverse a mano. Solo lo referencian los previews.
struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let container = try PreviewSamples.makeContainer()
        PreviewSamples.insert(into: container.mainContext)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

/// El mismo contenedor en memoria, sin datos: para ver los estados vacíos.
struct EmptyData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        try PreviewSamples.makeContainer()
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    /// Hábitos, plan, experimento y comodín de muestra en un contenedor en memoria.
    static var sampleData: Self { .modifier(SampleData()) }

    /// Contenedor en memoria vacío.
    static var emptyData: Self { .modifier(EmptyData()) }
}

/// Datos de muestra coherentes entre sí, relativos a hoy.
///
/// Un solo set compartido para que todas las pantallas cuenten la misma historia: si cada
/// preview inventara sus hábitos, comparar Hoy con Semana o Insights dejaría de decir nada.
/// Cada hábito cubre un caso que cambia cómo se dibuja la interfaz.
enum PreviewSamples {

    // MARK: - Contenedor

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV17.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func insert(into context: ModelContext) {
        let reading = readingHabit()
        let water = waterHabit()
        let running = runningHabit()
        let meditation = meditationHabit()
        let phone = phoneInBedHabit()

        for habit in [reading, water, running, meditation, phone] {
            context.insert(habit)
        }

        let plan = activePlan(habits: [reading, running])
        context.insert(plan)

        context.insert(
            HabitExperiment(
                habit: meditation,
                experimentTargetDaysPerWeek: 3,
                experimentActiveDaysOfWeek: [.monday, .wednesday, .friday],
                suggestedStartHour: 7,
                baselineConsistency: 0.45,
                startedAt: day(-2)
            )
        )

        // Revisiones semanales ya hechas: sin ellas `ContentView` abriría la revisión
        // semanal encima de cualquier preview, según el día en que se mire.
        for weekOffset in [0, -7] {
            let weekStart = AppCalendar.weekRange(containing: day(weekOffset)).lowerBound
            context.insert(WeeklyReview(weekStart: weekStart, reviewedAt: day(weekOffset)))
        }
    }

    // MARK: - Hábitos

    /// Check diario con racha larga, recordatorio y un comodín que cubrió un día.
    static func readingHabit() -> Habit {
        let habit = Habit(
            title: "Leer 20 páginas",
            note: "Antes de dormir, sin celular cerca.",
            cue: "Después de lavarme los dientes",
            minimumViableTitle: "Leer una página",
            iconName: "book.fill",
            colorHex: "#5c89a8",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            scheduleKind: .daily,
            isReminderEnabled: true,
            reminderTime: time(hour: 21),
            createdAt: day(-60)
        )

        let frozenDay = -12
        for offset in -60 ... -1 where offset != frozenDay {
            addEntry(offset % 17 == 0 ? .minimum : .completed, to: habit, on: offset, hour: 21)
        }
        habit.streakFreezes.append(
            StreakFreeze(habit: habit, protectedDate: day(frozenDay), usedAt: day(frozenDay + 1))
        )
        return habit
    }

    /// Cantidad diaria (vasos de agua), con hoy a medias y ayer sin registrar: candidato a
    /// recuperación cualquier día de la semana, porque la recuperación solo mira ayer.
    static func waterHabit() -> Habit {
        let habit = Habit(
            title: "Tomar agua",
            iconName: "drop.fill",
            colorHex: "#4f9db0",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            trackingKind: .quantity,
            measurementUnit: .glasses,
            targetValuePerSession: 8,
            scheduleKind: .daily,
            createdAt: day(-30)
        )

        for offset in -30 ... -2 {
            addEntry(.completed, to: habit, on: offset, hour: 18, value: Double(6 + (offset * -1) % 4))
        }
        addEntry(.completed, to: habit, on: 0, hour: 12, value: 5)
        return habit
    }

    /// Flexible, tres veces por semana: corre lunes, miércoles y viernes.
    static func runningHabit() -> Habit {
        let habit = Habit(
            title: "Correr",
            cue: "Con la ropa lista desde la noche",
            iconName: "figure.run",
            colorHex: "#5e8c61",
            targetDaysPerWeek: 3,
            activeDaysOfWeek: Set(Weekday.ordered),
            trackingKind: .quantity,
            measurementUnit: .kilometers,
            targetValuePerSession: 5,
            scheduleKind: .timesPerWeek,
            createdAt: day(-35)
        )

        let runDays: Set<Weekday> = [.monday, .wednesday, .friday]
        for offset in -35 ... 0 where runDays.contains(AppCalendar.weekday(of: day(offset))) {
            addEntry(.completed, to: habit, on: offset, hour: 7, value: offset % 2 == 0 ? 5 : 6.2)
        }
        return habit
    }

    /// Lunes a viernes, sin marcas desde hace tres días: la racha queda rota cualquier día,
    /// porque en los últimos tres días siempre cae al menos un día hábil.
    static func meditationHabit() -> Habit {
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let habit = Habit(
            title: "Meditar",
            minimumViableTitle: "Tres respiraciones",
            iconName: "brain.head.profile",
            colorHex: "#8b7fb0",
            targetDaysPerWeek: 5,
            activeDaysOfWeek: weekdays,
            scheduleKind: .specificDays,
            createdAt: day(-40)
        )

        for offset in -40 ... -4 where weekdays.contains(AppCalendar.weekday(of: day(offset))) {
            if offset % 9 == 0 {
                addEntry(.missed, to: habit, on: offset, hour: 22, failureReason: .forgot)
            } else {
                addEntry(.completed, to: habit, on: offset, hour: 7)
            }
        }
        return habit
    }

    /// Hábito a dejar, con recaídas e impulsos registrados.
    static func phoneInBedHabit() -> Habit {
        let habit = Habit(
            title: "Celular en la cama",
            note: "Dejarlo cargando en la cocina.",
            iconName: "iphone.slash",
            colorHex: "#b07f5c",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            scheduleKind: .daily,
            direction: .break,
            createdAt: day(-25)
        )

        for offset in -25 ... -1 {
            if offset == -5 || offset == -16 {
                addEntry(.slip, to: habit, on: offset, hour: 23, slipTrigger: offset == -5 ? .fatigue : .boredom)
            } else {
                addEntry(.completed, to: habit, on: offset, hour: 23)
            }
            if offset % 4 == 0 {
                addEntry(.urge, to: habit, on: offset, hour: 22, slipTrigger: .craving)
            }
        }
        return habit
    }

    // MARK: - Plan

    /// Plan en curso con un hito cumplido y otro pendiente.
    static func activePlan(habits: [Habit] = []) -> Plan {
        let plan = Plan(
            title: "Mañanas con energía",
            motivation: "Quiero llegar al trabajo despierto y con la cabeza clara.",
            measurableOutcome: "Correr 10 km sin parar",
            startedAt: day(-21),
            endsAt: day(45),
            targetCompletionRate: 0.8,
            createdAt: day(-21)
        )
        plan.habits = habits
        plan.milestones = [
            PlanMilestone(title: "Primera semana completa", targetDate: day(-14), plan: plan),
            PlanMilestone(title: "Correr 5 km seguidos", targetDate: day(10), plan: plan)
        ]
        plan.milestones[0].completedAt = day(-14)
        return plan
    }

    // MARK: - Fechas

    /// Inicio del día a `offset` días de hoy.
    static func day(_ offset: Int) -> Date {
        let today = AppCalendar.startOfDay(for: .now)
        return AppCalendar.current.date(byAdding: .day, value: offset, to: today) ?? today
    }

    private static func time(hour: Int) -> Date {
        AppCalendar.current.date(byAdding: .hour, value: hour, to: day(0)) ?? day(0)
    }

    private static func addEntry(
        _ kind: EntryKind,
        to habit: Habit,
        on offset: Int,
        hour: Int,
        value: Double? = nil,
        failureReason: HabitFailureReason? = nil,
        slipTrigger: SlipTrigger? = nil
    ) {
        let date = day(offset)
        let completedAt = AppCalendar.current.date(byAdding: .hour, value: hour, to: date)
        habit.entries.append(
            HabitEntry(
                date: date,
                completedAt: completedAt,
                source: .today,
                kind: kind,
                completedCount: Int((value ?? 1).rounded()),
                value: value,
                failureReason: failureReason,
                slipTrigger: slipTrigger,
                habit: habit
            )
        )
    }
}
