//
//  FocusSequenceSetup.swift
//  WeekHabit
//
//  Configuración del modo secuencia: cada hábito es una píldora cuya altura es
//  proporcional al tiempo asignado. Un conector vertical une las píldoras como
//  una línea de tiempo para comunicar el orden. Cada píldora tiene una manija
//  (a la derecha) que se arrastra para reordenar, y un agarre inferior —que
//  aparece al seleccionarla— para ajustar su tiempo. El total de la sesión es
//  la suma de todas las píldoras.
//

import SwiftUI

struct FocusSequenceSetup: View {
    @Binding var items: [FocusSequenceItem]
    let habitsByID: [UUID: Habit]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedID: UUID?
    @State private var resizeBaseSeconds: Int?

    // Reordenamiento por arrastre desde la manija.
    @State private var draggingID: UUID?
    @State private var dragOffset: CGFloat = 0   // desplazamiento visual de la píldora arrastrada
    @State private var swapAccum: CGFloat = 0    // compensación acumulada por swaps ya aplicados

    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = 136

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack {
                Text("SECUENCIA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)

                Spacer()

                Text("Total \(totalMinutes) min")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            }

            VStack(spacing: AppSpacing.s) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    pill(index: index, item: item)
                }
            }

            Text("Toca para ajustar el tiempo. Arrastra desde la manija para cambiar el orden.")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var totalMinutes: Int {
        FocusSequence.totalSeconds(items) / 60
    }

    private func height(for seconds: Int) -> CGFloat {
        let span = Double(FocusSequence.maxSeconds - FocusSequence.minSeconds)
        let t = Double(seconds - FocusSequence.minSeconds) / span
        return minHeight + CGFloat(min(1, max(0, t))) * (maxHeight - minHeight)
    }

    @ViewBuilder
    private func pill(index: Int, item: FocusSequenceItem) -> some View {
        let habit = habitsByID[item.id]
        let isSelected = selectedID == item.id
        let isDragging = draggingID == item.id
        let isLast = index == items.count - 1

        ZStack(alignment: .bottom) {
            HStack(spacing: AppSpacing.m) {
                iconBadge(habit)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit?.title ?? "Hábito")
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    Text("\(item.seconds / 60) min")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                dragHandle(for: item, isDragging: isDragging)
            }
            .padding(.horizontal, AppSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height(for: item.seconds))
            .background(isSelected ? (habit?.habitColor.opacity(0.14) ?? AppColor.accentMuted) : AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                    .strokeBorder(isSelected ? (habit?.habitColor ?? AppColor.accent).opacity(0.5) : Color.clear, lineWidth: 1.5)
            )

            if isSelected {
                grabber(for: item)
            }
        }
        // Conector de secuencia: une el icono de esta píldora con el de la
        // siguiente, formando una línea de tiempo que comunica el orden.
        .background(alignment: .bottomLeading) {
            if !isLast {
                Rectangle()
                    .fill(AppColor.divider)
                    .frame(width: 2, height: AppSpacing.s + 4)
                    .offset(x: AppSpacing.m + 20 - 1, y: AppSpacing.s)
                    .opacity(isDragging ? 0 : 1)
            }
        }
        .scaleEffect(isDragging ? 1.03 : 1)
        .shadow(color: isDragging ? Color.black.opacity(0.18) : .clear,
                radius: isDragging ? 12 : 0, y: isDragging ? 6 : 0)
        .offset(y: isDragging ? dragOffset : 0)
        .zIndex(isDragging ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                selectedID = isSelected ? nil : item.id
            }
            AppHaptics.play(.selection)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit?.title ?? "Hábito"), \(item.seconds / 60) minutos, posición \(index + 1) de \(items.count)")
        .accessibilityAction(named: "Subir") { move(item.id, by: -1) }
        .accessibilityAction(named: "Bajar") { move(item.id, by: 1) }
    }

    private func iconBadge(_ habit: Habit?) -> some View {
        ZStack {
            Circle()
                .fill((habit?.habitColor ?? AppColor.accent).opacity(0.18))
            Image(systemName: habit?.iconName ?? "circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(habit?.habitColor ?? AppColor.accent)
        }
        .frame(width: 40, height: 40)
    }

    private func dragHandle(for item: FocusSequenceItem, isDragging: Bool) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isDragging ? AppColor.accent : AppColor.textTertiary)
            .frame(width: 34, height: 34)
            .contentShape(Rectangle())
            .highPriorityGesture(reorderGesture(for: item))
            .accessibilityHidden(true)
    }

    private func grabber(for item: FocusSequenceItem) -> some View {
        Capsule()
            .fill(AppColor.textTertiary)
            .frame(width: 40, height: 5)
            .padding(.bottom, AppSpacing.s)
            .frame(maxWidth: .infinity)
            .frame(height: 28, alignment: .bottom)
            .contentShape(Rectangle())
            .highPriorityGesture(resizeGesture(for: item))
            .accessibilityLabel("Ajustar tiempo de \(habitsByID[item.id]?.title ?? "hábito")")
    }

    private func resizeGesture(for item: FocusSequenceItem) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let base = resizeBaseSeconds ?? item.seconds
                if resizeBaseSeconds == nil { resizeBaseSeconds = base }

                let secondsPerPixel = Double(FocusSequence.maxSeconds - FocusSequence.minSeconds) / Double(maxHeight - minHeight)
                let raw = Double(base) + Double(value.translation.height) * secondsPerPixel
                let newValue = FocusSequence.clampedSeconds(Int(raw))

                guard let idx = items.firstIndex(where: { $0.id == item.id }), items[idx].seconds != newValue else { return }
                withAnimation(AppMotion.respectful(AppMotion.snap, reduceMotion)) {
                    items[idx].seconds = newValue
                }
                AppHaptics.play(.selection)
            }
            .onEnded { _ in
                resizeBaseSeconds = nil
            }
    }

    private func reorderGesture(for item: FocusSequenceItem) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if draggingID != item.id {
                    draggingID = item.id
                    swapAccum = 0
                    AppHaptics.play(.selection)
                }

                guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
                let effective = value.translation.height - swapAccum

                var didSwap = false
                if idx < items.count - 1 {
                    let neighbor = height(for: items[idx + 1].seconds) + AppSpacing.s
                    if effective > neighbor / 2 {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            items.swapAt(idx, idx + 1)
                        }
                        swapAccum += neighbor
                        AppHaptics.play(.selection)
                        didSwap = true
                    }
                }
                if !didSwap, idx > 0 {
                    let neighbor = height(for: items[idx - 1].seconds) + AppSpacing.s
                    if effective < -neighbor / 2 {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            items.swapAt(idx, idx - 1)
                        }
                        swapAccum -= neighbor
                        AppHaptics.play(.selection)
                    }
                }

                dragOffset = value.translation.height - swapAccum
            }
            .onEnded { _ in
                withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                    dragOffset = 0
                }
                draggingID = nil
                swapAccum = 0
            }
    }

    private func move(_ id: UUID, by offset: Int) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let target = idx + offset
        guard target >= 0, target < items.count else { return }
        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            items.swapAt(idx, target)
        }
        AppHaptics.play(.selection)
    }
}
