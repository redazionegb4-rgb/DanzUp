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
    @Published var courses: [DanceCourse] = AppStore.demoCourses
    @Published var students: [Student] = AppStore.demoStudents
    @Published var announcements: [Announcement] = AppStore.demoAnnouncements
    @Published var attendanceByCourse: [String: Set<UUID>] = [:]
    @Published var lastSavedAt: Date?

    private let persistenceKey = "DanzUp.LocalData.v13"
    private var isRestoring = false

    init() {
        restoreLocalData()
    }

    var trialDaysRemaining: Int {
        max(0, 14 - (Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0))
    }
    var overduePaymentsCount: Int { students.filter { $0.paymentStatus == .late }.count }
    var duePaymentsCount: Int { students.filter { $0.paymentStatus == .due }.count }
    var medicalAlertsCount: Int { students.filter { $0.medicalStatus != .valid }.count }

    func enterDemo(role: UserRole) {
        userRole = role
        isAuthenticated = true
    }

    func logout() {
        saveLocalData()
        isAuthenticated = false
    }

    func setPayment(_ status: PaymentStatus, for studentID: UUID) {
        guard let index = students.firstIndex(where: { $0.id == studentID }) else { return }
        students[index].paymentStatus = status
        saveLocalData()
    }

    func setMedical(_ status: MedicalStatus, for studentID: UUID) {
        guard let index = students.firstIndex(where: { $0.id == studentID }) else { return }
        students[index].medicalStatus = status
        saveLocalData()
    }

    func addAnnouncement(title: String, body: String, audience: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, !cleanBody.isEmpty else { return }
        announcements.insert(Announcement(title: cleanTitle, body: cleanBody, audience: audience), at: 0)
        saveLocalData()
    }


    func courseID(named title: String) -> UUID? {
        courses.first(where: { $0.title == title })?.id
    }

    func studentsForCourse(_ courseID: UUID) -> [Student] {
        guard let title = courses.first(where: { $0.id == courseID })?.title else { return [] }
        return students.filter { $0.course == title }
    }

    func enrolledCount(for courseID: UUID) -> Int {
        studentsForCourse(courseID).count
    }

    func addCourse(_ course: DanceCourse) {
        courses.append(course)
        saveLocalData()
    }

    func deleteCourses(at offsets: IndexSet, from visibleCourses: [DanceCourse]) {
        let ids = offsets.compactMap { visibleCourses.indices.contains($0) ? visibleCourses[$0].id : nil }
        courses.removeAll { ids.contains($0.id) }
        saveLocalData()
    }

    func addStudent(_ student: Student) {
        students.append(student)
        saveLocalData()
    }

    func assignStudent(_ studentID: UUID, toCourseID courseID: UUID) {
        guard let studentIndex = students.firstIndex(where: { $0.id == studentID }),
              let course = courses.first(where: { $0.id == courseID }) else { return }
        students[studentIndex].course = course.title
        saveLocalData()
    }

    func removeStudent(_ studentID: UUID, fromCourseID courseID: UUID) {
        guard let studentIndex = students.firstIndex(where: { $0.id == studentID }),
              let course = courses.first(where: { $0.id == courseID }),
              students[studentIndex].course == course.title else { return }
        students[studentIndex].course = "Nessun corso"
        attendanceByCourse[course.title]?.remove(studentID)
        saveLocalData()
    }

    func isStudent(_ studentID: UUID, enrolledIn courseID: UUID) -> Bool {
        guard let student = students.first(where: { $0.id == studentID }),
              let course = courses.first(where: { $0.id == courseID }) else { return false }
        return student.course == course.title
    }

    func deleteStudents(at offsets: IndexSet, from visibleStudents: [Student]) {
        let ids = offsets.compactMap { visibleStudents.indices.contains($0) ? visibleStudents[$0].id : nil }
        students.removeAll { ids.contains($0.id) }
        for key in Array(attendanceByCourse.keys) {
            attendanceByCourse[key]?.subtract(ids)
        }
        saveLocalData()
    }

    func toggleAttendance(studentID: UUID, courseTitle: String) {
        var current = attendanceByCourse[courseTitle] ?? []
        if current.contains(studentID) { current.remove(studentID) } else { current.insert(studentID) }
        attendanceByCourse[courseTitle] = current
        saveLocalData()
    }

    func isPresent(studentID: UUID, courseTitle: String) -> Bool {
        attendanceByCourse[courseTitle, default: []].contains(studentID)
    }

    func resetDemoData() {
        courses = Self.demoCourses
        students = Self.demoStudents
        announcements = Self.demoAnnouncements
        attendanceByCourse = [:]
        trialStart = Date()
        saveLocalData()
    }

    func saveLocalData() {
        guard !isRestoring else { return }
        let snapshot = LocalSnapshot(
            schoolName: schoolName,
            ownerName: ownerName,
            selectedPlan: selectedPlan,
            appearance: appearance,
            trialStart: trialStart,
            courses: courses,
            students: students,
            announcements: announcements,
            attendanceByCourse: attendanceByCourse.mapValues(Array.init)
        )
        do {
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: persistenceKey)
            lastSavedAt = Date()
        } catch {
            // La build demo continua a funzionare anche se il salvataggio locale fallisce.
        }
    }

    private func restoreLocalData() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            let snapshot = try JSONDecoder().decode(LocalSnapshot.self, from: data)
            schoolName = snapshot.schoolName
            ownerName = snapshot.ownerName
            selectedPlan = snapshot.selectedPlan
            appearance = snapshot.appearance
            trialStart = snapshot.trialStart
            courses = snapshot.courses
            students = snapshot.students
            announcements = snapshot.announcements
            attendanceByCourse = snapshot.attendanceByCourse.mapValues(Set.init)
        } catch {
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        }
    }

    private struct LocalSnapshot: Codable {
        var schoolName: String
        var ownerName: String
        var selectedPlan: SubscriptionPlan
        var appearance: AppAppearance
        var trialStart: Date
        var courses: [DanceCourse]
        var students: [Student]
        var announcements: [Announcement]
        var attendanceByCourse: [String: [UUID]]
    }

    static let demoCourses: [DanceCourse] = [
        DanceCourse(title: "Danza Classica", teacher: "Giulia Ferri", day: "Lunedì", time: "17:00", room: "Sala Étoile", enrolled: 18, capacity: 22, style: "Classica"),
        DanceCourse(title: "Hip Hop Teen", teacher: "Marco De Luca", day: "Martedì", time: "18:30", room: "Sala Urban", enrolled: 24, capacity: 26, style: "Urban"),
        DanceCourse(title: "Latino Avanzato", teacher: "Sara Conti", day: "Mercoledì", time: "20:00", room: "Sala Ritmo", enrolled: 16, capacity: 20, style: "Latino")
    ]

    static let demoStudents: [Student] = [
        Student(name: "Alice Romano", course: "Danza Classica", age: 14, paymentStatus: .paid, medicalStatus: .valid, attendanceRate: 96),
        Student(name: "Matteo Bianchi", course: "Hip Hop Teen", age: 16, paymentStatus: .due, medicalStatus: .expiring, attendanceRate: 88),
        Student(name: "Sofia Ricci", course: "Danza Classica", age: 8, paymentStatus: .paid, medicalStatus: .valid, attendanceRate: 100),
        Student(name: "Luca Esposito", course: "Latino Avanzato", age: 23, paymentStatus: .late, medicalStatus: .expired, attendanceRate: 73)
    ]

    static let demoAnnouncements: [Announcement] = [
        Announcement(title: "Prove saggio estivo", body: "Sabato alle 15:00. Presentarsi 20 minuti prima.", audience: "Tutti i corsi"),
        Announcement(title: "Recupero lezioni", body: "Aperte le prenotazioni per i recuperi di luglio.", audience: "Tutta la scuola")
    ]
}
