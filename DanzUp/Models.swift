import SwiftUI

struct DanceCourse: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var teacher: String
    var day: String
    var time: String
    var room: String
    var enrolled: Int
    var capacity: Int
    var style: String

    init(id: UUID = UUID(), title: String, teacher: String, day: String, time: String, room: String, enrolled: Int, capacity: Int, style: String) {
        self.id = id
        self.title = title
        self.teacher = teacher
        self.day = day
        self.time = time
        self.room = room
        self.enrolled = enrolled
        self.capacity = capacity
        self.style = style
    }
}

struct Student: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var course: String
    var age: Int
    var paymentStatus: PaymentStatus
    var medicalStatus: MedicalStatus
    var attendanceRate: Int

    init(id: UUID = UUID(), name: String, course: String, age: Int, paymentStatus: PaymentStatus, medicalStatus: MedicalStatus, attendanceRate: Int) {
        self.id = id
        self.name = name
        self.course = course
        self.age = age
        self.paymentStatus = paymentStatus
        self.medicalStatus = medicalStatus
        self.attendanceRate = attendanceRate
    }
}

enum PaymentStatus: String, Codable, CaseIterable {
    case paid = "Pagato"
    case due = "Da pagare"
    case late = "Scaduto"

    var color: Color {
        switch self {
        case .paid: return .green
        case .due: return .orange
        case .late: return .red
        }
    }
}

enum MedicalStatus: String, Codable, CaseIterable {
    case valid = "Valido"
    case expiring = "In scadenza"
    case expired = "Scaduto"

    var color: Color {
        switch self {
        case .valid: return .green
        case .expiring: return .orange
        case .expired: return .red
        }
    }
}

struct Announcement: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var date: Date
    var audience: String

    init(id: UUID = UUID(), title: String, body: String, date: Date = Date(), audience: String) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.audience = audience
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "Automatico"
    case light = "Chiaro"
    case dark = "Scuro"
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case base = "Base"
    case pro = "Pro"
    case premium = "Premium"
    var id: String { rawValue }

    var monthlyPrice: String {
        switch self {
        case .base: return "€9,99"
        case .pro: return "€19,99"
        case .premium: return "€34,99"
        }
    }

    var subtitle: String {
        switch self {
        case .base: return "Fino a 100 allievi"
        case .pro: return "Gestione completa"
        case .premium: return "Più sedi e statistiche"
        }
    }

    var features: [String] {
        switch self {
        case .base:
            return ["Corsi e calendario", "Presenze", "Comunicazioni", "Fino a 100 allievi"]
        case .pro:
            return ["Allievi illimitati", "Pagamenti e documenti", "Certificati medici", "Eventi e saggi"]
        case .premium:
            return ["Tutto del piano Pro", "Più sedi", "Più amministratori", "Statistiche avanzate"]
        }
    }
}
