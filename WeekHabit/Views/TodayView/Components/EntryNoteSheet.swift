//
//  EntryNoteSheet.swift
//  WeekHabit
//
//  Mini-prompt opcional tras marcar una entrada de hábito.
//  La nota se guarda al cerrar si quedó texto; si quedó vacía, se limpia.
//

import SwiftUI
import SwiftData

struct EntryNoteSheet: View {
    let entry: HabitEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var noteText: String
    @FocusState private var isFocused: Bool

    init(entry: HabitEntry) {
        self.entry = entry
        _noteText = State(initialValue: entry.note ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Una nota opcional")
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)

                    if let title = entry.habit?.title, !title.isEmpty {
                        Text(title)
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                TextField(
                    "¿Cómo te sentiste?",
                    text: $noteText,
                    axis: .vertical
                )
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2...4)
                .focused($isFocused)
                .padding(AppSpacing.m)
                .background(AppColor.bgSunken.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.bgElevated)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                    .tint(AppColor.accent)
                }
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.bgElevated)
        .onAppear {
            isFocused = true
        }
        .onDisappear {
            commit()
        }
    }

    private func commit() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue = trimmed.isEmpty ? nil : trimmed
        guard entry.note != newValue else { return }
        entry.note = newValue
        try? modelContext.save()
    }
}
