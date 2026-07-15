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

enum LessonState: String, Codable, CaseIterable, Identifiable {
    case scheduled = "Programmata", cancelled = "Annullata", completed = "Completata", recovery = "Recupero"
    var id: String { rawValue }
}

struct CourseLesson: Identifiable, Codable, Equatable {
    var id = UUID()
    var courseID: UUID
    var start: Date
    var durationMinutes: Int = 75
    var room: String
    var teacherID: UUID?
    var state: LessonState = .scheduled
    var note: String = ""
}

enum AttendanceState: String, Codable, CaseIterable, Identifiable {
    case present = "Presente", absent = "Assente", justified = "Giustificato", trial = "Prova"
    var id: String { rawValue }
}

struct LessonAttendance: Identifiable, Codable, Equatable {
    var id = UUID()
    var lessonID: UUID
    var studentID: UUID
    var state: AttendanceState
    var note: String = ""
    var recordedBy: String
    var updatedAt: Date = Date()
}

enum FeeType: String, Codable, CaseIterable, Identifiable {
    case monthly = "Mensile", quarterly = "Trimestrale", annual = "Annuale", registration = "Iscrizione", recital = "Saggio", costume = "Costume", privateLesson = "Lezione privata"
    var id: String { rawValue }
}

struct PaymentRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var studentID: UUID
    var courseID: UUID?
    var type: FeeType
    var title: String
    var amount: Double
    var paidAmount: Double
    var dueDate: Date
    var status: PaymentStatus
    var method: String = "Da definire"
    var receiptNumber: String = ""
    var note: String = ""
}

enum DocumentReviewStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "Da verificare", approved = "Approvato", rejected = "Rifiutato"
    var id: String { rawValue }
}

struct SchoolDocument: Identifiable, Codable, Equatable {
    var id = UUID()
    var studentID: UUID
    var title: String
    var kind: String
    var issueDate: Date
    var expiryDate: Date?
    var reviewStatus: DocumentReviewStatus
    var rejectionReason: String = ""
    var hasAttachment: Bool = false
}

struct DanceEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var location: String
    var courseIDs: [UUID]
    var participantIDs: [UUID]
    var rehearsalDates: [Date]
    var fee: Double
    var costumeNote: String
    var performanceOrder: String
}

struct StaffPermissions: Codable, Equatable {
    var manageStudents = true
    var manageCourses = true
    var manageAttendance = true
    var managePayments = false
    var manageDocuments = true
    var sendAnnouncements = true
}
