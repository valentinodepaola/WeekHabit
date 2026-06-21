//
//  FocusSequenceSetup.swift
//  WeekHabit
//
//  Configuración del modo secuencia: cada hábito es una píldora cuya altura es
//  proporcional al tiempo asignado. Al tocar una píldora se revela un agarre
//  para arrastrar y ajustar su tiempo, además de controles para moverla en la
//  secuencia. El total de la sesión es la suma de todas las píldoras.
//

import SwiftUI

struct FocusSequenceSetup: View {
    @Binding var items: [FocusSequenceItem]
    let habitsByID: [UUID: Habit]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedID: UUID?
    @State private var resizeBaseSeconds: Int?

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

            Text("Toca una píldora para ajustar su tiempo o moverla en la secuencia.")
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

                if isSelected {
                    HStack(spacing: AppSpacing.s) {
                        controlButton("chevron.up", disabled: index == 0) {
                            move(item.id, by: -1)
                        }
                        controlButton("chevron.down", disabled: index == items.count - 1) {
                            move(item.id, by: 1)
                        }
                    }
                } else {
                    Text("\(index + 1)")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: 22)
                }
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
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                selectedID = isSelected ? nil : item.id
            }
            AppHaptics.play(.selection)
        }
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

    private func controlButton(_ icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(disabled ? AppColor.textTertiary : AppColor.accent)
                .frame(width: 34, height: 34)
                .background(AppColor.bgSunken)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
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
