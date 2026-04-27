//
//  SwipableRow.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 26/04/26.
//

import SwiftUI

struct SwipableRow<Content: View>: View {

    @Environment(\.colorScheme) private var colorScheme

    let content: Content
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool?

    private let revealWidth: CGFloat = 160
    private let actionWidth: CGFloat = 80
    private let cornerRadius: CGFloat = 18
    private let directionLockDistance: CGFloat = 18
    private let horizontalDominanceRatio: CGFloat = 1.35

    init(
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
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
                    color: Color(hex: "#5f93b4"),
                    action: onEdit
                )

                actionButton(
                    title: "Borrar",
                    icon: "trash",
                    color: Color(hex: "#cf453e"),
                    action: onDelete
                )
            }
            .frame(width: revealWidth)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            content
                .background(backgroundColor)
                .offset(x: offset + dragOffset)
                .simultaneousGesture(swipeGesture)

        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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

        if offset == 0 {
            dragOffset = min(0, width)
        } else {
            dragOffset = max(0, min(revealWidth, width))
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
            if offset == 0 {
                offset = translation < -threshold ? -revealWidth : 0
            } else {
                offset = translation > threshold ? 0 : -revealWidth
            }

            dragOffset = 0
        }
    }

    private func performAction(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            dragOffset = 0
        }

        isHorizontalDrag = nil
        action()
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
    SwipableRow(
        onEdit: { print("editar") },
        onDelete: { print("borrar") }
    ) {
        HabitCard(
            habit: Habit(
                title: "Leer 20 páginas",
                category: .learning,
                targetDaysPerWeek: 6,
                activeDaysOfWeek: [.monday, .tuesday, .wednesday]
            ),
            onTap: {}
        )
    }
}
