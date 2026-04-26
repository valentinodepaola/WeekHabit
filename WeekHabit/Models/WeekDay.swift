//
//  WeekDay.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday    = 2
    case tuesday   = 3
    case wednesday = 4
    case thursday  = 5
    case friday    = 6
    case saturday  = 7
    case sunday    = 1

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday:    return "Lun"
        case .tuesday:   return "Mar"
        case .wednesday: return "Mié"
        case .thursday:  return "Jue"
        case .friday:    return "Vie"
        case .saturday:  return "Sáb"
        case .sunday:    return "Dom"
        }
    }
    
    var oneLetterName: String {
        switch self {
        case .monday:    return "L"
        case .tuesday:   return "M"
        case .wednesday: return "X"
        case .thursday:  return "J"
        case .friday:    return "V"
        case .saturday:  return "S"
        case .sunday:    return "D"
        }
    }

    // Orden visual L-D
    static var ordered: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
}
