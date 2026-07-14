import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: UserRole = .owner
    @Published var schoolName = "DanzUp Academy"
    @Published var ownerName = "Demetrio"
    @Published var selectedPlan: SubscriptionPlan = .premium
    @Published var appearance: AppAppearance = .system
    @Published var trialStart = Date()
    @Published var courses: [DanceCourse] = [
        DanceCourse(title: "Danza Classica", teacher: "Giulia Ferri", day: "Lunedì", time: "17:00", room: "Sala Étoile", enrolled: 18, capacity: 22, style: "Classica"),
        DanceCourse(title: "Hip Hop Teen", teacher: "Marco De Luca", day: "Martedì", time: "18:30", room: "Sala Urban", enrolled: 24, capacity: 26, style: "Urban"),
        DanceCourse(title: "Latino Avanzato", teacher: "Sara Conti", day: "Mercoledì", time: "20:00", room: "Sala Ritmo", enrolled: 16, capacity: 20, style: "Latino")
    ]
    @Published var students: [Student] = [
        Student(name: "Alice Romano", course: "Danza Classica", age: 14, paymentStatus: .paid, medicalStatus: .valid, attendanceRate: 96),
        Student(name: "Matteo Bianchi", course: "Hip Hop Teen", age: 16, paymentStatus: .due, medicalStatus: .expiring, attendanceRate: 88),
        Student(name: "Sofia Ricci", course: "Danza Classica", age: 8, paymentStatus: .paid, medicalStatus: .valid, attendanceRate: 100),
        Student(name: "Luca Esposito", course: "Latino Avanzato", age: 23, paymentStatus: .late, medicalStatus: .expired, attendanceRate: 73)
    ]
    @Published var announcements: [Announcement] = [
        Announcement(title: "Prove saggio estivo", body: "Sabato alle 15:00. Presentarsi 20 minuti prima.", audience: "Tutti i corsi"),
        Announcement(title: "Recupero lezioni", body: "Aperte le prenotazioni per i recuperi di luglio.", audience: "Tutta la scuola")
    ]

    var trialDaysRemaining: Int { max(0, 14 - (Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0)) }
    var overduePaymentsCount: Int { students.filter { $0.paymentStatus == .late }.count }
    var medicalAlertsCount: Int { students.filter { $0.medicalStatus != .valid }.count }

    func enterDemo(role: UserRole) { userRole = role; isAuthenticated = true }
    func logout() { isAuthenticated = false }

    func setPayment(_ status: PaymentStatus, for studentID: UUID) {
        guard let index = students.firstIndex(where: { $0.id == studentID }) else { return }
        students[index].paymentStatus = status
    }

    func setMedical(_ status: MedicalStatus, for studentID: UUID) {
        guard let index = students.firstIndex(where: { $0.id == studentID }) else { return }
        students[index].medicalStatus = status
    }

    func addAnnouncement(title: String, body: String, audience: String) {
        announcements.insert(Announcement(title: title, body: body, audience: audience), at: 0)
    }
}
