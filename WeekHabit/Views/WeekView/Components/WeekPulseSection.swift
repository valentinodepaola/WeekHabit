//
//  WeekPulseSection.swift
//  WeekHabit
//
//  Cabecera de datos de la semana: cada columna de día muestra, además de la
//  fecha, una barra con la fracción de hábitos completados ese día. Reemplaza
//  al strip de días pasivo — el encabezado cuenta la historia de la semana
//  antes de leer ninguna fila.
//

import SwiftUI

/// Resumen de un día de la semana visible: cuántos hábitos tocaban y cuántos
/// se completaron. Calculado por `WeekView`; la vista solo pinta.
struct WeekDayPulse: Identifiable {
    let date: Date
    let isToday: Bool
    let isFuture: Bool
    let completed: Int
    let scheduled: Int

    var id: Date { date }

    var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return min(1, Double(completed) / Double(scheduled))
    }
}

struct WeekPulseSection: View {
    let pulses: [WeekDayPulse]
    let completedThisWeek: Int
    let totalGoal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("PULSO DE LA SEMANA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Spacer()

                if totalGoal > 0 {
                    Text("\(completedThisWeek) de \(totalGoal) marcas")
                        .font(AppFont.label)
                        .monospacedDigit()
                        .foregroundStyle(completedThisWeek > 0 ? AppColor.accent : AppColor.textTertiary)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, AppSpacing.l)

            HStack(spacing: WeekGridLayout.cellSpacing) {
                ForEach(pulses) { pulse in
                    DayPulseColumn(pulse: pulse)
                }
            }
            .padding(.horizontal, WeekGridLayout.gridHorizontalInset)
        }
    }
}

private struct DayPulseColumn: View {
    let pulse: WeekDayPulse

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var dayAbbrev: String {
        AppCalendar.weekday(of: pulse.date)
            .shortName
            .uppercased(with: AppFormatters.esMXLocale)
    }

    private var dayNumber: String {
        String(AppCalendar.current.component(.day, from: pulse.date))
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(dayAbbrev)
                .font(AppFont.micro)
                .foregroundStyle(pulse.isToday ? .white.opacity(0.85) : AppColor.textSecondary)

            Text(dayNumber)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(pulse.isToday ? .white : AppColor.textPrimary)
                .monospacedDigit()

            pulseBar
        }
        .padding(.vertical, AppSpacing.s)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(pulse.isToday ? AppColor.accent : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var pulseBar: some View {
        Capsule()
            .fill(trackColor)
            .frame(height: 4)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(fillColor)
                        .frame(width: geo.size.width * pulse.ratio)
                        .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: pulse.ratio)
                }
            }
            .padding(.horizontal, AppSpacing.xs)
    }

    private var trackColor: Color {
        if pulse.isToday { return .white.opacity(0.3) }
        return AppColor.bgSunken
    }

    private var fillColor: Color {
        pulse.isToday ? .white : AppColor.accent
    }

    private var accessibilityLabel: String {
        let dayText = pulse.date.formatted(
            Date.FormatStyle(locale: AppFormatters.esMXLocale)
                .weekday(.wide)
                .day()
        )
        var parts = [dayText]
        if pulse.isToday {
            parts.append("hoy")
        }
        if pulse.scheduled > 0 {
            parts.append("\(pulse.completed) de \(pulse.scheduled) completados")
        } else {
            parts.append("sin hábitos programados")
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    let calendar = AppCalendar.current
    let weekStart = AppCalendar.weekRange(containing: .now).lowerBound
    let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

    return WeekPulseSection(
        pulses: days.enumerated().map { index, date in
            WeekDayPulse(
                date: date,
                isToday: AppCalendar.isSameDay(date, .now),
                isFuture: AppCalendar.startOfDay(for: date) > AppCalendar.startOfDay(for: .now),
                completed: [2, 3, 1, 0, 2, 0, 0][index],
                scheduled: [3, 3, 3, 2, 3, 2, 2][index]
            )
        },
        completedThisWeek: 8,
        totalGoal: 18
    )
    .padding(.vertical)
    .background(AppColor.bgCanvas)
}
