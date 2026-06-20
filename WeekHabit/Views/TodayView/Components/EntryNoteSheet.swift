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
    @State private var saveFailure: EntryNoteSaveFailure?
    @State private var didAttemptCommit = false
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
                        commitAndDismiss()
                    }
                    .tint(AppColor.accent)
                }
            }
        }
        .alert(item: $saveFailure) { failure in
            Alert(
                title: Text("No se pudo guardar"),
                message: Text(failure.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
        .whKeyboardDoneToolbar()
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.bgElevated)
        .onDisappear {
            commitIfNeeded()
        }
    }

    private func commitAndDismiss() {
        guard commitIfNeeded() else { return }
        dismiss()
    }

    @discardableResult
    private func commitIfNeeded() -> Bool {
        guard !didAttemptCommit else { return true }
        didAttemptCommit = true

        do {
            try EntryNoteService.saveNote(noteText, for: entry, modelContext: modelContext)
            return true
        } catch {
            didAttemptCommit = false
            saveFailure = EntryNoteSaveFailure(message: error.localizedDescription)
            return false
        }
    }
}

private struct EntryNoteSaveFailure: Identifiable {
    let id = UUID()
    let message: String
}
