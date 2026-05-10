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
        let schema = Schema(versionedSchema: SchemaV9.self)
        let config = ModelConfiguration(schema: schema)
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
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                Task {
                    await refreshHabitRemindersIfNeeded()
                }
            }
        }
    }

    private func refreshHabitRemindersIfNeeded() async {
        guard hasCompletedAppOnboarding else { return }
        await HabitReminderService.refreshAllReminders(for: habits)
    }
}
