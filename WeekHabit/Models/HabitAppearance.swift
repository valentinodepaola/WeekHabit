//
//  HabitAppearance.swift
//  WeekHabit
//

import SwiftUI

struct HabitIconGroup: Identifiable {
    let id: String
    let title: String
    let iconNames: [String]
}

enum HabitAppearance {
    static let defaultIconName = "sparkles"
    static let defaultColorHex = "#c2573c"

    static let iconGroups: [HabitIconGroup] = [
        HabitIconGroup(
            id: "general",
            title: "General",
            iconNames: [
                "sparkles", "star.fill", "flag.fill", "target", "trophy.fill", "medal.fill",
                "checkmark.seal.fill", "checkmark.circle.fill", "bolt.fill", "flame.fill",
                "timer", "alarm.fill", "clock.fill", "hourglass", "calendar", "list.bullet.clipboard.fill"
            ]
        ),
        HabitIconGroup(
            id: "health",
            title: "Salud",
            iconNames: [
                "heart.fill", "cross.case.fill", "pills.fill", "stethoscope", "bandage.fill",
                "lungs.fill", "brain.head.profile", "medical.thermometer", "drop.fill",
                "bed.double.fill", "figure.mind.and.body", "waveform.path.ecg", "syringe.fill",
                "facemask.fill", "allergens", "microbe.fill", "ivfluid.bag.fill"
            ]
        ),
        HabitIconGroup(
            id: "hygiene",
            title: "Higiene",
            iconNames: [
                "mouth.fill", "teeth.fill", "hands.sparkles.fill", "shower.fill",
                "bathtub.fill", "sink.fill", "toilet.fill", "bubbles.and.sparkles.fill",
                "spray.sparkle.fill", "comb.fill", "mustache.fill", "eyebrow",
                "eye.fill", "ear.fill", "nose.fill", "bandage.fill"
            ]
        ),
        HabitIconGroup(
            id: "fitness",
            title: "Movimiento",
            iconNames: [
                "figure.walk", "figure.run", "figure.hiking", "figure.strengthtraining.traditional",
                "figure.core.training", "figure.cooldown", "figure.pool.swim", "figure.outdoor.cycle",
                "dumbbell.fill", "bicycle", "sportscourt.fill", "soccerball", "basketball.fill",
                "tennisball.fill", "baseball.fill", "volleyball.fill", "football.fill",
                "skateboard.fill", "skis.fill", "snowboard.fill", "surfboard.fill",
                "shoeprints.fill", "figure.yoga", "figure.pilates", "figure.dance"
            ]
        ),
        HabitIconGroup(
            id: "food",
            title: "Comida y agua",
            iconNames: [
                "fork.knife", "cup.and.saucer.fill", "mug.fill", "waterbottle.fill",
                "takeoutbag.and.cup.and.straw.fill", "carrot.fill", "leaf.fill",
                "birthday.cake.fill", "wineglass.fill", "refrigerator.fill", "frying.pan.fill",
                "popcorn.fill", "fish.fill", "birthday.cake.fill", "water.waves"
            ]
        ),
        HabitIconGroup(
            id: "learning",
            title: "Aprendizaje",
            iconNames: [
                "book.fill", "books.vertical.fill", "text.book.closed.fill", "graduationcap.fill",
                "pencil", "pencil.and.outline", "highlighter", "bookmark.fill", "newspaper.fill",
                "doc.text.fill", "doc.richtext.fill", "character.book.closed.fill", "globe", "lightbulb.fill"
            ]
        ),
        HabitIconGroup(
            id: "work",
            title: "Trabajo",
            iconNames: [
                "briefcase.fill", "laptopcomputer", "desktopcomputer", "keyboard.fill",
                "calendar.badge.clock", "envelope.fill", "tray.full.fill", "folder.fill",
                "archivebox.fill", "chart.bar.fill", "chart.line.uptrend.xyaxis",
                "person.crop.circle.badge.checkmark", "phone.fill", "building.2.fill"
            ]
        ),
        HabitIconGroup(
            id: "mind",
            title: "Mente y descanso",
            iconNames: [
                "leaf.fill", "moon.fill", "sun.max.fill", "cloud.sun.fill", "wind",
                "brain", "brain.head.profile", "face.smiling", "hands.sparkles.fill",
                "figure.mind.and.body", "eye.fill", "zzz", "bell.slash.fill"
            ]
        ),
        HabitIconGroup(
            id: "home",
            title: "Casa",
            iconNames: [
                "house.fill", "bed.double.fill", "sofa.fill", "washer.fill", "dishwasher.fill",
                "dryer.fill", "toilet.fill", "shower.fill", "bathtub.fill", "sink.fill",
                "trash.fill", "cart.fill", "basket.fill", "wrench.and.screwdriver.fill",
                "hammer.fill", "paintbrush.pointed.fill", "lightbulb.fill", "lock.fill", "key.fill",
                "door.left.hand.open", "curtains.open", "chair.lounge.fill", "lamp.desk.fill"
            ]
        ),
        HabitIconGroup(
            id: "money",
            title: "Finanzas",
            iconNames: [
                "dollarsign.circle.fill", "creditcard.fill", "banknote.fill", "building.columns.fill",
                "chart.pie.fill", "chart.bar.xaxis", "wallet.pass.fill", "receipt.fill",
                "percent", "plus.forwardslash.minus", "shippingbox.fill"
            ]
        ),
        HabitIconGroup(
            id: "creative",
            title: "Creatividad",
            iconNames: [
                "paintbrush.fill", "paintpalette.fill", "camera.fill", "video.fill",
                "microphone.fill", "music.note", "music.quarternote.3", "guitars.fill",
                "theatermasks.fill", "scissors", "scribble.variable", "wand.and.sparkles",
                "photo.fill", "film.fill"
            ]
        ),
        HabitIconGroup(
            id: "social",
            title: "Social",
            iconNames: [
                "person.fill", "person.2.fill", "person.3.fill", "message.fill", "bubble.left.and.bubble.right.fill",
                "phone.fill", "gift.fill", "heart.text.square.fill", "hand.thumbsup.fill",
                "figure.2.and.child.holdinghands", "shared.with.you"
            ]
        ),
        HabitIconGroup(
            id: "travel",
            title: "Salidas",
            iconNames: [
                "airplane", "car.fill", "bus.fill", "tram.fill", "ferry.fill",
                "map.fill", "location.fill", "suitcase.fill", "fuelpump.fill",
                "figure.walk.departure", "mappin.and.ellipse"
            ]
        ),
        HabitIconGroup(
            id: "digital",
            title: "Digital",
            iconNames: [
                "wifi", "antenna.radiowaves.left.and.right", "app.badge.fill", "iphone",
                "ipad", "macbook", "display", "gamecontroller.fill", "headphones",
                "speaker.wave.2.fill", "icloud.fill", "lock.shield.fill", "qrcode"
            ]
        )
    ]

    static var iconNames: [String] {
        Array(
            iconGroups
                .flatMap(\.iconNames)
                .reduce(into: [String]()) { result, iconName in
                    if !result.contains(iconName) {
                        result.append(iconName)
                    }
                }
        )
    }

    static let colorHexes: [String] = [
        "#c2573c", "#d66b7d", "#b85c9e", "#8b7fb0", "#6f7fc8", "#5c89a8",
        "#4f9a8b", "#5e8c61", "#7fa774", "#9aa85d", "#c0a24c", "#c89046",
        "#b86f3d", "#8f6b55", "#6d7a82", "#4e6f8f", "#6b6458", "#1f8a70",
        "#b94848", "#7952b3", "#2f80ed", "#27ae60", "#f2994a", "#eb5757"
    ]

    static func color(for hex: String) -> Color {
        Color(hex: hex)
    }
}

enum LegacyHabitArea: String, Codable {
    case health
    case work
    case personal
    case learning

    var iconName: String {
        switch self {
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .learning: return "book.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .health: return "#7fa774"
        case .work: return "#8b7fb0"
        case .personal: return "#c89046"
        case .learning: return "#5c89a8"
        }
    }
}
