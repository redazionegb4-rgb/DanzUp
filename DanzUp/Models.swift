import SwiftUI

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case owner = "Proprietario"
    case secretary = "Segreteria"
    case teacher = "Insegnante"
    case parent = "Genitore"
    case student = "Allievo"
    var id: String { rawValue }
    var icon: String {
        switch self { case .owner: return "building.2.fill"; case .secretary: return "person.crop.rectangle.stack.fill"; case .teacher: return "figure.dance"; case .parent: return "figure.2.and.child.holdinghands"; case .student: return "person.fill" }
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
    case base = "Base", pro = "Pro", premium = "Premium"
    var id: String { rawValue }
    var monthlyPrice: String { switch self { case .base: return "€9,99"; case .pro: return "€19,99"; case .premium: return "€34,99" } }
    var subtitle: String { switch self { case .base: return "Per piccole scuole"; case .pro: return "Per scuole in crescita"; case .premium: return "Per più sedi" } }
    var features: [String] { switch self { case .base: return ["Fino a 100 allievi", "Corsi e presenze", "Comunicazioni"]; case .pro: return ["Allievi illimitati", "Quote e documenti", "Saggi ed eventi"]; case .premium: return ["Più sedi", "Più amministratori", "Statistiche avanzate"] } }
}

enum AppAppearance: String, CaseIterable, Identifiable, Codable { case system = "Automatico", light = "Chiaro", dark = "Scuro"; var id: String { rawValue }; var colorScheme: ColorScheme? { switch self { case .system: return nil; case .light: return .light; case .dark: return .dark } } }

struct DanceCourse: Identifiable, Codable { var id = UUID(); var title: String; var teacher: String; var day: String; var time: String; var room: String; var enrolled: Int; var capacity: Int; var style: String }

enum PaymentStatus: String, Codable { case paid = "Pagata", due = "Da pagare", late = "Scaduta"; var color: Color { switch self { case .paid: return .green; case .due: return .orange; case .late: return .red } } }
enum MedicalStatus: String, Codable { case valid = "Valido", expiring = "In scadenza", expired = "Scaduto"; var color: Color { switch self { case .valid: return .green; case .expiring: return .orange; case .expired: return .red } } }
struct Student: Identifiable, Codable {
    var id = UUID()
    var name: String
    var course: String
    var age: Int
    var paymentStatus: PaymentStatus
    var medicalStatus: MedicalStatus
    var attendanceRate: Int
    var familyCode: String?
}
struct Announcement: Identifiable, Codable { var id = UUID(); var title: String; var body: String; var audience: String; var date = Date() }

struct InviteCode: Identifiable, Codable, Equatable {
    var id = UUID()
    var code: String
    var role: UserRole
    var maxUses: Int
    var usedCount: Int = 0
    var isActive: Bool = true
    var createdAt: Date = Date()

    var remainingUses: Int { max(0, maxUses - usedCount) }
    var statusText: String {
        if !isActive { return "Disattivato" }
        if remainingUses == 0 { return "Esaurito" }
        return remainingUses == 1 ? "1 utilizzo rimasto" : "\(remainingUses) utilizzi rimasti"
    }
}


struct ParentInvitation: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var email: String
    var phone: String
    var relationship: String
    var studentIDs: [UUID]
    var code: String
    var isActive: Bool = true
    var createdAt: Date = Date()
}

struct SchoolMember: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var email: String
    var role: UserRole
    var inviteCode: String
    var joinedAt: Date = Date()
    var isActive: Bool = true
}


enum ChildLinkStatus: String, Codable { case pending = "In attesa", approved = "Approvata", rejected = "Rifiutata" }

struct ChildLinkRequest: Identifiable, Codable, Equatable {
    var id = UUID()
    var parentName: String
    var parentEmail: String
    var studentID: UUID
    var studentName: String
    var authorizationCode: String
    var status: ChildLinkStatus = .pending
    var createdAt: Date = Date()
}

enum ChildLinkResult: Equatable {
    case success
    case emptyCode
    case invalidCode
    case inactiveCode
    case exhaustedCode
    case wrongCodeRole
    case studentNotFound
    case alreadyLinked
    case alreadyPending
}

enum InviteUseResult: Equatable {
    case success(SchoolMember)
    case emptyFields
    case invalidCode
    case inactiveCode
    case exhaustedCode
    case incompatibleRole(expected: UserRole)
    case emailAlreadyRegistered
}
