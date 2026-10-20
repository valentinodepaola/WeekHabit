//
//  WHListRow.swift
//  WeekHabit
//
//  Fila estandarizada con leading/trailing genéricos. Reemplaza implementaciones
//  ad-hoc de filas en TodayView, WeekView, planes, etc.
//

import SwiftUI

struct WHListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { rowContent }
                    .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            leading()

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: AppSpacing.s)

            trailing()
        }
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
}

extension WHListRow where Leading == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = { EmptyView() }
        self.trailing = trailing
        self.onTap = onTap
    }
}

extension WHListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = { EmptyView() }
        self.onTap = onTap
    }
}

extension WHListRow where Leading == EmptyView, Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = { EmptyView() }
        self.trailing = { EmptyView() }
        self.onTap = onTap
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        WHListRow(title: "Leer", subtitle: "10 páginas · todos los días")

        WHListRow(title: "Meditar", subtitle: "5 días por semana") {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(AppColor.accent)
                .frame(width: 32, height: 32)
                .background(AppColor.accentMuted)
                .clipShape(Circle())
        } trailing: {
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColor.textTertiary)
        }

        WHListRow(
            title: "Caminar",
            trailing: {
                Text("3/5")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            },
            onTap: {}
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
