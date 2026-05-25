//
//  EntryHistoryCard.swift
//  WeekHabit
//
//  Timeline de entradas completadas con su nota opcional.
//  Tap en una fila abre el sheet de edición para añadir o cambiar la nota.
//

import SwiftUI
import SwiftData

struct EntryHistoryCard: View {
    let habit: Habit

    @State private var editingEntry: HabitEntry?

    private static let rowLimit = 20

    private var entries: [HabitEntry] {
        habit.entries
            .filter { $0.kind == .completed }
            .sorted { lhs, rhs in
                let lhsMoment = lhs.completedAt ?? lhs.date
                let rhsMoment = rhs.completedAt ?? rhs.date
                return lhsMoment > rhsMoment
            }
    }

    private var visibleEntries: [HabitEntry] {
        Array(entries.prefix(Self.rowLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("HISTORIAL")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Spacer()

                if !entries.isEmpty {
                    Text("\(entries.count)")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .monospacedDigit()
                }
            }

            if visibleEntries.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppSpacing.s) {
                    ForEach(visibleEntries) { entry in
                        entryRow(entry)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
        .sheet(item: $editingEntry) { entry in
            EntryNoteSheet(entry: entry)
        }
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.textTertiary)
                .frame(width: 30, height: 30)
                .background(AppColor.bgSunken.opacity(0.65))
                .clipShape(Circle())

            Text("Aún no hay registros. Cuando marques un día, podrás dejar una nota corta sobre cómo te sentiste.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }

    private func entryRow(_ entry: HabitEntry) -> some View {
        Button {
            editingEntry = entry
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.m) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(habit.habitColor)
                    .frame(width: 30, height: 30)
                    .background(habit.habitColor.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(dateText(for: entry))
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)

                    if let note = trimmedNote(for: entry) {
                        Text(note)
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Sin nota")
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.m)
            .background(AppColor.bgSunken.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func trimmedNote(for entry: HabitEntry) -> String? {
        let trimmed = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func dateText(for entry: HabitEntry) -> String {
        let moment = entry.completedAt ?? entry.date
        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: moment)
    }
}
