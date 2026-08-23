//
//  ComponentsGalleryView.swift
//  WeekHabit
//
//  Galería interna de componentes WH*. No está cableada en el shell de la app.
//  Sirve para validación visual mediante el #Preview de Xcode en modo oscuro y
//  modo claro. Cuando se rediseñen pantallas, esta galería sirve como referencia
//  del sistema en uso.
//

import SwiftUI

struct ComponentsGalleryView: View {
    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                    Text("Galería del sistema")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.textPrimary)

                    buttonsSection
                    cardsSection
                    listRowSection
                    emptyStateSection
                    progressSection
                    chipsSection
                    weekGridSection
                    sectionHeaderSection
                    formSection
                    confidenceSection
                    dayBadgeSection
                }
                .padding(AppSpacing.l)
            }
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        gallerySection(title: "Buttons") {
            VStack(spacing: AppSpacing.s) {
                WHButton(title: "Primary", variant: .primary) {}
                WHButton(title: "Secondary", icon: "plus", variant: .secondary) {}
                WHButton(title: "Ghost", variant: .ghost) {}
                WHButton(title: "Destructive", variant: .destructive) {}
                HStack(spacing: AppSpacing.s) {
                    WHButton(title: "Compact", size: .compact, fullWidth: false) {}
                    WHButton(title: "Disabled", isDisabled: true) {}
                }
                HStack(spacing: AppSpacing.s) {
                    WHCircleButton(systemName: "questionmark") {}
                    WHCircleButton(systemName: "chevron.left") {}
                    WHCircleButton(systemName: "chevron.right") {}
                    Spacer()
                }
            }
        }
    }

    // MARK: - Cards

    private var cardsSection: some View {
        gallerySection(title: "Cards") {
            VStack(spacing: AppSpacing.m) {
                WHCard(variant: .elevated) {
                    cardSample("Elevated", subtitle: "Tarjeta principal con sombra suave.")
                }
                WHCard(variant: .flat) {
                    cardSample("Flat", subtitle: "Mismo color que el canvas.")
                }
                WHCard(variant: .sunken) {
                    cardSample("Sunken", subtitle: "Hundida — para inputs.")
                }
            }
        }
    }

    private func cardSample(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)
            Text(subtitle)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    // MARK: - List rows

    private var listRowSection: some View {
        gallerySection(title: "List rows") {
            VStack(spacing: AppSpacing.s) {
                WHListRow(
                    title: "Leer 10 minutos",
                    subtitle: "después de cenar",
                    leading: {
                        Image(systemName: "book")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColor.accent)
                            .frame(width: 36, height: 36)
                            .background(AppColor.accentMuted)
                            .clipShape(Circle())
                    },
                    trailing: {
                        Image(systemName: "circle")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(AppColor.textTertiary)
                    },
                    onTap: {}
                )

                WHListRow(
                    title: "Caminar 30 min",
                    subtitle: "5 días seguidos",
                    leading: {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColor.success)
                            .frame(width: 36, height: 36)
                            .background(AppColor.success.opacity(0.15))
                            .clipShape(Circle())
                    },
                    trailing: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColor.success)
                    },
                    onTap: {}
                )
            }
        }
    }

    // MARK: - Empty state

    private var emptyStateSection: some View {
        gallerySection(title: "Empty state") {
            WHCard(variant: .flat, padding: 0) {
                WHEmptyState(
                    icon: "leaf",
                    title: "Hoy toca descansar",
                    message: "No tienes hábitos programados para hoy. Mañana te esperan dos.",
                    primaryAction: WHEmptyStateAction(label: "Crear un hábito", perform: {})
                )
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        gallerySection(title: "Progress") {
            VStack(spacing: AppSpacing.l) {
                HStack(spacing: AppSpacing.l) {
                    WHProgressRing(progress: 0.66) {
                        VStack(spacing: 0) {
                            Text("2/3")
                                .font(AppFont.bodyEmphasis)
                                .foregroundStyle(AppColor.textPrimary)
                            Text("hoy")
                                .font(AppFont.label)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    WHProgressRing(progress: 0.25, progressColor: AppColor.warning, center: { EmptyView() })
                    WHProgressRing(progress: 1.0, progressColor: AppColor.success, center: { EmptyView() })
                }

                VStack(alignment: .leading, spacing: AppSpacing.s) {
                    WHProgressBar(progress: 0.4)
                    WHProgressBar(progress: 0.7, progressColor: AppColor.success, goalMarker: 0.8)
                }
            }
        }
    }

    // MARK: - Chips

    private var chipsSection: some View {
        gallerySection(title: "Chips") {
            HStack(spacing: AppSpacing.s) {
                WHChip(label: "Idle", action: {})
                WHChip(label: "Selected", icon: "checkmark", isSelected: true, action: {})
                WHChip(label: "Disabled", isDisabled: true, action: {})
            }
        }
    }

    // MARK: - Week grid

    private var weekGridSection: some View {
        gallerySection(title: "Week grid states") {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                ForEach(WeekGridCellFamily.allCases) { family in
                    VStack(alignment: .leading, spacing: AppSpacing.s) {
                        Text(family.title)
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textSecondary)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 104), spacing: AppSpacing.s)],
                            alignment: .leading,
                            spacing: AppSpacing.s
                        ) {
                            ForEach(family.states, id: \.self) { state in
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    WeekGridCell(
                                        state: state,
                                        habitColor: AppColor.accent,
                                        isInteractive: false,
                                        onTap: {},
                                        onSkip: {}
                                    )
                                    Text(state.legendTitle)
                                        .font(AppFont.micro)
                                        .foregroundStyle(AppColor.textSecondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section headers

    private var sectionHeaderSection: some View {
        gallerySection(title: "Section headers") {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                WHSectionHeader(title: "Hábitos de hoy")
                WHSectionHeader(
                    title: "Planes",
                    subtitle: "Lo que sostienen tus hábitos",
                    action: WHSectionHeaderAction(label: "Ver todos", perform: {})
                )
            }
        }
    }

    // MARK: - Form

    private var formSection: some View {
        gallerySection(title: "Form") {
            WHCard(variant: .elevated) {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    WHFormSection(title: "Acción", helper: "Específica y suficientemente pequeña para repetirse.") {
                        Text("Leer 10 minutos")
                            .font(AppFont.body)
                            .padding(AppSpacing.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.bgSunken)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m))
                    }
                    WHFormSection(title: "Después de…", helper: "Una señal te ayuda más que la fuerza de voluntad.") {
                        Text("cenar")
                            .font(AppFont.body)
                            .padding(AppSpacing.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.bgSunken)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m))
                    }
                }
            }
        }
    }

    // MARK: - Confidence

    private var confidenceSection: some View {
        gallerySection(title: "Confidence tags") {
            HStack(spacing: AppSpacing.s) {
                WHConfidenceTag(confidence: .low)
                WHConfidenceTag(confidence: .medium)
                WHConfidenceTag(confidence: .high)
            }
        }
    }

    // MARK: - Day badges

    private var dayBadgeSection: some View {
        gallerySection(title: "Day badges") {
            HStack(spacing: AppSpacing.s) {
                ForEach(Array(["L", "M", "M", "J", "V", "S", "D"].enumerated()), id: \.offset) { index, letter in
                    WHDayBadge(
                        initial: letter,
                        isSelected: index == 0,
                        isToday: index == 1,
                        isCompleted: index == 2,
                        action: {}
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func gallerySection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text(title.uppercased())
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)
            content()
        }
    }
}

#Preview("Dark") {
    ComponentsGalleryView()
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    ComponentsGalleryView()
        .preferredColorScheme(.light)
}
