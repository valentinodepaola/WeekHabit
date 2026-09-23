//
//  DailyNoticeView.swift
//  WeekHabit
//
//  Configuración del aviso diario. La hora la elige siempre el usuario: el selector arranca
//  en una hora fija y la sugerencia basada en sus datos solo aparece como dato al lado.
//
//  Cada cambio vuelve a agendar los avisos acá mismo, en vez de esperar al próximo cambio de
//  fase, para que un error del sistema se vea en el momento en que el usuario tocó algo.
//

import SwiftData
import SwiftUI
import UserNotifications

struct DailyNoticeView: View {
    @AppStorage(DailyNoticeService.isEnabledKey) private var isEnabled = false
    @AppStorage(DailyNoticeService.hourKey) private var hour = DailyNotice.defaultHour
    @AppStorage(DailyNoticeService.minuteKey) private var minute = DailyNotice.defaultMinute
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    /// `nil` hasta la primera lectura: así no parpadea el banner equivocado al abrir.
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var isTimeSensitiveDisabled = false
    @State private var failureMessage: String?

    private var suggestedWindow: HourWindow? {
        habits.dailyNoticeSuggestedWindow()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header

                if let authorizationStatus {
                    content(for: authorizationStatus)
                }
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.bgCanvas)
        .task { await refreshPermissionState() }
        .onChange(of: scenePhase) { _, newValue in
            // Vuelve de Ajustes: el permiso pudo cambiar y la pantalla tiene que decir la verdad.
            guard newValue == .active else { return }
            Task { await refreshPermissionState() }
        }
        .onChange(of: isEnabled) { _, _ in reschedule() }
        .onChange(of: hour) { _, _ in reschedule() }
        .onChange(of: minute) { _, _ in reschedule() }
        .alert(
            "No se pudo programar el aviso",
            isPresented: Binding(
                get: { failureMessage != nil },
                set: { if !$0 { failureMessage = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(failureMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Aviso diario")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text("Un solo aviso al día con lo que te queda. Llega aunque tengas un modo de concentración activo, y no llega si ya cerraste el día.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func content(for status: UNAuthorizationStatus) -> some View {
        switch status {
        case .authorized, .provisional, .ephemeral:
            // Solo los controles van en tarjeta: el banner de permiso ya trae su propio fondo.
            WHCard {
                authorizedContent
            }
        case .notDetermined:
            NotificationPermissionBanner(
                icon: "bell.badge",
                iconColor: AppColor.accent,
                tint: AppColor.accentMuted,
                title: "Activa las notificaciones",
                message: "Para que pueda avisarte a la hora que elijas.",
                actionTitle: "Activar aviso",
                action: requestAuthorization
            )
        case .denied:
            deniedBanner
        @unknown default:
            deniedBanner
        }
    }

    private var deniedBanner: some View {
        NotificationPermissionBanner(
            icon: "bell.slash",
            iconColor: AppColor.warning,
            tint: AppColor.warning.opacity(0.14),
            title: "Notificaciones deshabilitadas",
            message: "Las apagaste antes. Puedes reactivarlas en Ajustes.",
            actionTitle: "Abrir Ajustes",
            action: { NotificationPermissionBanner.openSettings() }
        )
    }

    private var authorizedContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Toggle("Avisarme lo que me queda", isOn: $isEnabled)
                .font(AppFont.body)
                .tint(AppColor.accent)

            if isEnabled {
                DatePicker(
                    "Hora",
                    selection: timeBinding,
                    displayedComponents: .hourAndMinute
                )
                .font(AppFont.body)
                .tint(AppColor.accent)

                if let suggestedWindow, suggestedWindow.startHour != hour || minute != 0 {
                    NoticeHourSuggestion(window: suggestedWindow) {
                        hour = suggestedWindow.startHour
                        minute = 0
                    }
                }

                if isTimeSensitiveDisabled {
                    timeSensitiveNote
                }
            }
        }
    }

    private var timeSensitiveNote: some View {
        Label {
            Text("Las notificaciones urgentes están apagadas en Ajustes: el aviso llega, pero no atraviesa un modo de concentración.")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "moon")
                .font(AppFont.iconSmall)
                .foregroundStyle(AppColor.textTertiary)
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                AppCalendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
            },
            set: { newValue in
                let components = AppCalendar.current.dateComponents([.hour, .minute], from: newValue)
                hour = components.hour ?? hour
                minute = components.minute ?? minute
            }
        )
    }

    private func refreshPermissionState() async {
        authorizationStatus = await HabitReminderService.authorizationStatus()
        isTimeSensitiveDisabled = await DailyNoticeService.isTimeSensitiveDisabled()
    }

    private func requestAuthorization() {
        Task {
            let granted = await HabitReminderService.requestAuthorization()
            await refreshPermissionState()
            if granted {
                isEnabled = true
            }
        }
    }

    private func reschedule() {
        let habits = habits
        let isEnabled = isEnabled
        let hour = hour
        let minute = minute
        Task {
            do {
                try await DailyNoticeService.refresh(
                    habits: habits,
                    isEnabled: isEnabled,
                    hour: hour,
                    minute: minute
                )
            } catch {
                failureMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    DailyNoticeView()
}
