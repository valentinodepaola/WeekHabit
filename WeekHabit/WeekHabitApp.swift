//
//  WeekHabitApp.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

@main
struct WeekHabitApp: App {
    let container: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV17.self)
        // La base vive en el App Group para que la extensión del widget pueda leerla. La app
        // es la única que la migra: ver `AppGroupStore`.
        let config = AppGroupStore.appConfiguration(schema: schema)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: HabitMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to load ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppLaunchView {
                RootView()
            }
        }
        .modelContainer(container)
    }
}

private struct RootView: View {
    @AppStorage("hasCompletedAppOnboarding") private var hasCompletedAppOnboarding = false
    @AppStorage("weeklyReviewWeekdayRaw") private var weeklyReviewWeekdayRaw: Int = Weekday.sunday.rawValue
    @AppStorage("weeklyReviewHour") private var weeklyReviewHour: Int = 19
    @AppStorage("weeklyReviewMinute") private var weeklyReviewMinute: Int = 0
    @AppStorage(DailyNoticeService.isEnabledKey) private var isDailyNoticeEnabled = false
    @AppStorage(DailyNoticeService.hourKey) private var dailyNoticeHour = DailyNotice.defaultHour
    @AppStorage(DailyNoticeService.minuteKey) private var dailyNoticeMinute = DailyNotice.defaultMinute
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    var body: some View {
        Group {
            if hasCompletedAppOnboarding {
                ContentView()
            } else {
                OnboardingView {
                    hasCompletedAppOnboarding = true
                }
            }
        }
        .task {
            await refreshHabitRemindersIfNeeded()
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                Task {
                    await refreshHabitRemindersIfNeeded()
                }
            } else if oldValue == .active {
                // Al salir de primer plano los widgets pasan a ser lo único que el usuario ve
                // de la app. Ver `WidgetRefreshService` para por qué se refresca acá y no en
                // cada mutación.
                WidgetRefreshService.reloadWidgets()
                // Y el aviso diario se recalcula con lo registrado en esta visita: si el día
                // quedó cerrado, el de hoy se cancela antes de que suene.
                Task {
                    await refreshDailyNoticeIfNeeded()
                }
            }
        }
    }

    private func refreshHabitRemindersIfNeeded() async {
        guard hasCompletedAppOnboarding else { return }
        await HabitReminderService.refreshAllReminders(for: habits)
        await WeeklyReviewService.refreshReviewReminder(
            weekday: Weekday(rawValue: weeklyReviewWeekdayRaw) ?? .sunday,
            hour: weeklyReviewHour,
            minute: weeklyReviewMinute
        )
        await refreshDailyNoticeIfNeeded()
    }

    private func refreshDailyNoticeIfNeeded() async {
        guard hasCompletedAppOnboarding else { return }
        // En segundo plano no hay dónde mostrar el error: la pantalla de avisos lo muestra
        // cuando el usuario cambia algo, que es cuando puede hacer algo al respecto.
        try? await DailyNoticeService.refresh(
            habits: habits,
            isEnabled: isDailyNoticeEnabled,
            hour: dailyNoticeHour,
            minute: dailyNoticeMinute
        )
    }
}
