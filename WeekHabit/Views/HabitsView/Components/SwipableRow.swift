//
//  SwipableRow.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 26/04/26.
//

import SwiftUI

struct SwipableRow<Content: View>: View {

    @Environment(\.colorScheme) private var colorScheme

    let id: UUID
    let content: Content
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Binding var openRowID: UUID?

    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool?

    private let revealWidth: CGFloat = 160
    private let actionWidth: CGFloat = 80
    private let cornerRadius: CGFloat = 18
    private let directionLockDistance: CGFloat = 18
    private let horizontalDominanceRatio: CGFloat = 1.35

    init(
        id: UUID,
        openRowID: Binding<UUID?>,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self._openRowID = openRowID
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                actionButton(
                    title: "Editar",
                    icon: "pencil",
                    color: AppColor.editAction,
                    action: onEdit
                )

                actionButton(
                    title: "Borrar",
                    icon: "trash",
                    color: AppColor.destructiveAction,
                    action: onDelete
                )
            }
            .frame(width: revealWidth)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)

            content
                .background(backgroundColor)
                .overlay {
                    if isOpen {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                closeRow()
                            }
                    }
                }
                .accessibilityAction(named: "Editar", onEdit)
                .accessibilityAction(named: "Borrar", onDelete)
                .offset(x: visualOffset)
                .simultaneousGesture(swipeGesture)

        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
    }

    private var isOpen: Bool {
        openRowID == id
    }

    private var visualOffset: CGFloat {
        (isOpen ? -revealWidth : 0) + dragOffset
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 22, coordinateSpace: .local)
            .onChanged { value in
                updateSwipe(with: value)
            }
            .onEnded { value in
                finishSwipe(with: value)
            }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? AppColor.bgDark : AppColor.bgLight
    }

    private func updateSwipe(with value: DragGesture.Value) {
        let width = value.translation.width
        let height = value.translation.height

        if isHorizontalDrag == nil {
            guard max(abs(width), abs(height)) > directionLockDistance else { return }
            isHorizontalDrag = abs(width) > abs(height) * horizontalDominanceRatio
        }

        guard isHorizontalDrag == true else { return }

        if isOpen {
            dragOffset = max(0, min(revealWidth, width))
        } else {
            dragOffset = min(0, width)
        }
    }

    private func finishSwipe(with value: DragGesture.Value) {
        defer { isHorizontalDrag = nil }

        guard isHorizontalDrag == true else {
            dragOffset = 0
            return
        }

        let translation = value.translation.width
        let threshold: CGFloat = revealWidth / 2

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if isOpen {
                openRowID = translation > threshold ? nil : id
            } else {
                openRowID = translation < -threshold ? id : nil
            }

            dragOffset = 0
        }
    }

    private func performAction(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = 0
            openRowID = nil
        }

        isHorizontalDrag = nil
        action()
    }

    private func closeRow() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = 0
            openRowID = nil
        }

        isHorizontalDrag = nil
    }

    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            performAction(action)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))

                Text(title)
                    .font(AppFont.captionApp)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(color)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SwipableRowPreview()
}

private struct SwipableRowPreview: View {
    @State private var openRowID: UUID?

    let habit = Habit(
        title: "Leer 20 páginas",
        category: .learning,
        targetDaysPerWeek: 6,
        activeDaysOfWeek: [.monday, .tuesday, .wednesday]
    )

    var body: some View {
        SwipableRow(
            id: habit.id,
            openRowID: $openRowID,
            onEdit: { print("editar") },
            onDelete: { print("borrar") }
        ) {
            HabitCard(
                habit: habit,
                onTap: {}
            )
        }
    }
}
