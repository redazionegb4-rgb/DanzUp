import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var isOnboarded: Bool {
        didSet { UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded") }
    }
    @Published var schoolName: String {
        didSet { UserDefaults.standard.set(schoolName, forKey: "schoolName") }
    }
    @Published var ownerName: String {
        didSet { UserDefaults.standard.set(ownerName, forKey: "ownerName") }
    }
    @Published var trialStart: Date {
        didSet { UserDefaults.standard.set(trialStart, forKey: "trialStart") }
    }
    @Published var selectedPlan: SubscriptionPlan = .pro
    @Published var appearance: AppAppearance = .system
    @Published var courses: [DanceCourse]
    @Published var students: [Student]
    @Published var announcements: [Announcement]

    init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        self.schoolName = UserDefaults.standard.string(forKey: "schoolName") ?? "DanzUp Academy"
        self.ownerName = UserDefaults.standard.string(forKey: "ownerName") ?? "Amministratore"
        self.trialStart = UserDefaults.standard.object(forKey: "trialStart") as? Date ?? Date()

        self.courses = [
            DanceCourse(title: "Danza Classica", teacher: "Giulia Ferri", day: "Lunedì", time: "17:00", room: "Sala Étoile", enrolled: 18, capacity: 22, style: "Classica"),
            DanceCourse(title: "Hip Hop Teen", teacher: "Marco De Luca", day: "Martedì", time: "18:30", room: "Sala Urban", enrolled: 24, capacity: 26, style: "Urban"),
            DanceCourse(title: "Latino Avanzato", teacher: "Sara Conti", day: "Mercoledì", time: "20:00", room: "Sala Ritmo", enrolled: 16, capacity: 20, style: "Latino"),
            DanceCourse(title: "Propedeutica", teacher: "Elena Rossi", day: "Giovedì", time: "16:30", room: "Sala Étoile", enrolled: 12, capacity: 16, style: "Bambini")
        ]

        self.students = [
            Student(name: "Alice Romano", course: "Danza Classica", age: 14, paymentStatus: .paid, medicalStatus: .valid, attendanceRate: 96),
            Student(name: "Matteo Bianchi", course: "Hip Hop Teen", age: 16, paymentStatus: .due, medicalStatus: .expiring, attendanceRate: 88),
            Student(name: "Sofia Ricci", course: "Propedeutica", age: 8, paymentStatus: .paid, medicalStatus: .valid, attendanceRate: 100),
            Student(name: "Luca Esposito", course: "Latino Avanzato", age: 23, paymentStatus: .late, medicalStatus: .expired, attendanceRate: 73)
        ]

        self.announcements = [
            Announcement(title: "Prove saggio estivo", body: "Le prove generali si terranno sabato alle 15:00. Presentarsi 20 minuti prima.", audience: "Tutti i corsi"),
            Announcement(title: "Chiusura festività", body: "La scuola resterà chiusa lunedì. Le lezioni saranno recuperate.", audience: "Tutta la scuola")
        ]
    }

    var trialDaysRemaining: Int {
        let elapsed = Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0
        return max(0, 14 - elapsed)
    }

    var trialProgress: Double {
        Double(14 - trialDaysRemaining) / 14.0
    }

    func completeOnboarding(school: String, owner: String) {
        schoolName = school.isEmpty ? "La mia scuola" : school
        ownerName = owner.isEmpty ? "Amministratore" : owner
        trialStart = Date()
        isOnboarded = true
    }

    func resetDemo() {
        isOnboarded = false
        UserDefaults.standard.removeObject(forKey: "trialStart")
    }
}
