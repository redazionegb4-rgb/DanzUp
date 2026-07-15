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
    @Published var courseEnrollments: [UUID: Set<UUID>] = [:]
    @Published var teacherAssignments: [UUID: Set<UUID>] = [:]
    @Published var inviteCodes: [InviteCode] = AppStore.demoInviteCodes
    @Published var schoolMembers: [SchoolMember] = AppStore.demoMembers
    @Published var parentInvitations: [ParentInvitation] = []
    @Published var currentMember: SchoolMember?
    @Published var childLinkRequests: [ChildLinkRequest] = []
    @Published var linkedChildIDsByParent: [String: [UUID]] = [:]
    @Published var lastSavedAt: Date?
    @Published var lessons: [CourseLesson] = []
    @Published var lessonAttendance: [LessonAttendance] = []
    @Published var paymentRecords: [PaymentRecord] = []
    @Published var documents: [SchoolDocument] = []
    @Published var danceEvents: [DanceEvent] = []
    @Published var staffPermissions: [UUID: StaffPermissions] = [:]

    private let persistenceKey = "DanzUp.LocalData.v15"
    private var isRestoring = false

    init() {
        restoreLocalData()
        ensureStudentFamilyCodes()
        ensureCourseEnrollments()
        ensureTeacherAssignments()
        ensureOperationalData()
    }

    var trialDaysRemaining: Int {
        max(0, 14 - (Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0))
    }
    var overduePaymentsCount: Int { students.filter { $0.paymentStatus == .late }.count }
    var duePaymentsCount: Int { students.filter { $0.paymentStatus == .due }.count }
    var medicalAlertsCount: Int { students.filter { $0.medicalStatus != .valid }.count }

    func enterDemo(role: UserRole) {
        userRole = role

        if role == .parent {
            // L’accesso demo famiglia deve usare un vero account genitore collegato
            // allo stesso studentID mostrato in Home, Corsi e Profilo.
            let demoEmail = "demo.genitore@danzup.local"
            let demoMember = SchoolMember(
                name: "Mario Romano",
                email: demoEmail,
                role: .parent,
                inviteCode: "DEMO-FAMIGLIA"
            )
            currentMember = demoMember

            if let aliceID = students.first(where: { $0.name == "Alice Romano" })?.id {
                linkedChildIDsByParent[demoEmail] = [aliceID]
            }
        } else if role == .student {
            let demoMember = SchoolMember(
                name: "Alice Romano",
                email: "demo.allievo@danzup.local",
                role: .student,
                inviteCode: "DEMO-ALLIEVO"
            )
            currentMember = demoMember
        } else {
            currentMember = nil
        }

        isAuthenticated = true
        saveLocalData()
    }

    @discardableResult
    func useInvite(code rawCode: String, email rawEmail: String, name rawName: String, selectedRole: UserRole) -> InviteUseResult {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !email.isEmpty, !name.isEmpty else { return .emptyFields }
        if selectedRole == .parent, let invitationIndex = parentInvitations.firstIndex(where: { $0.code.uppercased() == code }) {
            guard parentInvitations[invitationIndex].isActive else { return .inactiveCode }
            let invitation = parentInvitations[invitationIndex]
            guard invitation.email.lowercased() == email else { return .invalidCode }
            guard !schoolMembers.contains(where: { $0.email.lowercased() == email }) else { return .emailAlreadyRegistered }
            let member = SchoolMember(name: name, email: email, role: .parent, inviteCode: invitation.code)
            schoolMembers.insert(member, at: 0)
            linkedChildIDsByParent[email] = invitation.studentIDs
            parentInvitations[invitationIndex].isActive = false
            currentMember = member
            userRole = .parent
            isAuthenticated = true
            saveLocalData()
            return .success(member)
        }
        guard let index = inviteCodes.firstIndex(where: { $0.code.uppercased() == code }) else { return .invalidCode }
        guard inviteCodes[index].isActive else { return .inactiveCode }
        guard inviteCodes[index].remainingUses > 0 else { return .exhaustedCode }

        let codeRole = inviteCodes[index].role
        let familyCompatible = [.parent, .student].contains(codeRole) && [.parent, .student].contains(selectedRole)
        guard codeRole == selectedRole || familyCompatible else { return .incompatibleRole(expected: codeRole) }
        guard !schoolMembers.contains(where: { $0.email.lowercased() == email }) else { return .emailAlreadyRegistered }

        inviteCodes[index].usedCount += 1
        if inviteCodes[index].remainingUses == 0 { inviteCodes[index].isActive = false }
        let member = SchoolMember(name: name, email: email, role: selectedRole, inviteCode: inviteCodes[index].code)
        schoolMembers.insert(member, at: 0)
        currentMember = member
        userRole = selectedRole
        isAuthenticated = true
        saveLocalData()
        return .success(member)
    }

    var currentFamilyName: String { currentMember?.name ?? (userRole == .parent ? "Mario Romano" : "Alice Romano") }
    var currentFamilyEmail: String { currentMember?.email.lowercased() ?? "demo.genitore@danzup.local" }

    func linkedChildrenForCurrentParent() -> [Student] {
        let ids = Set(linkedChildIDsByParent[currentFamilyEmail] ?? [])
        return students.filter { ids.contains($0.id) }
    }

    @discardableResult
    func requestChildLink(code rawCode: String) -> ChildLinkResult {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return .emptyCode }
        guard let student = students.first(where: { $0.familyCode?.uppercased() == code }) else { return .invalidCode }
        let studentID = student.id
        if linkedChildIDsByParent[currentFamilyEmail, default: []].contains(studentID) { return .alreadyLinked }
        if childLinkRequests.contains(where: { $0.parentEmail == currentFamilyEmail && $0.studentID == studentID && $0.status == .pending }) { return .alreadyPending }
        childLinkRequests.insert(
            ChildLinkRequest(
                parentName: currentFamilyName,
                parentEmail: currentFamilyEmail,
                studentID: studentID,
                studentName: student.name,
                authorizationCode: code
            ),
            at: 0
        )
        saveLocalData()
        return .success
    }

    func familyCode(for studentID: UUID) -> String {
        guard let student = students.first(where: { $0.id == studentID }) else { return "" }
        return student.familyCode ?? ""
    }

    func regenerateFamilyCode(for studentID: UUID) {
        guard let index = students.firstIndex(where: { $0.id == studentID }) else { return }
        students[index].familyCode = makeUniqueFamilyCode()
        childLinkRequests.removeAll { $0.studentID == studentID && $0.status == .pending }
        saveLocalData()
    }

    private func ensureStudentFamilyCodes() {
        var changed = false
        for index in students.indices where students[index].familyCode == nil || students[index].familyCode?.isEmpty == true {
            students[index].familyCode = makeUniqueFamilyCode()
            changed = true
        }
        if changed { saveLocalData() }
    }

    private func makeUniqueFamilyCode() -> String {
        var value: String
        repeat { value = "ALU-\(Int.random(in: 100000...999999))" }
        while students.contains(where: { $0.familyCode == value })
        return value
    }

    func approveChildLink(_ id: UUID) {
        guard let index = childLinkRequests.firstIndex(where: { $0.id == id }) else { return }
        childLinkRequests[index].status = .approved
        let email = childLinkRequests[index].parentEmail
        let studentID = childLinkRequests[index].studentID
        if !linkedChildIDsByParent[email, default: []].contains(studentID) { linkedChildIDsByParent[email, default: []].append(studentID) }
        saveLocalData()
    }

    func rejectChildLink(_ id: UUID) {
        guard let index = childLinkRequests.firstIndex(where: { $0.id == id }) else { return }
        childLinkRequests[index].status = .rejected
        saveLocalData()
    }

    func deleteChildLinkRequest(_ id: UUID) { childLinkRequests.removeAll { $0.id == id }; saveLocalData() }

    func parentInvitations(for studentID: UUID) -> [ParentInvitation] {
        parentInvitations.filter { $0.studentIDs.contains(studentID) }
    }

    func createParentInvitation(name: String, email: String, phone: String, relationship: String, studentID: UUID) -> ParentInvitation? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanName.isEmpty, !cleanEmail.isEmpty else { return nil }
        if let existingIndex = parentInvitations.firstIndex(where: { $0.email.lowercased() == cleanEmail }) {
            if !parentInvitations[existingIndex].studentIDs.contains(studentID) {
                parentInvitations[existingIndex].studentIDs.append(studentID)
            }
            parentInvitations[existingIndex].isActive = true
            saveLocalData()
            return parentInvitations[existingIndex]
        }
        var code: String
        repeat { code = "GEN-\(Int.random(in: 100000...999999))" }
        while parentInvitations.contains(where: { $0.code == code })
        let invitation = ParentInvitation(name: cleanName, email: cleanEmail, phone: phone, relationship: relationship, studentIDs: [studentID], code: code)
        parentInvitations.insert(invitation, at: 0)
        saveLocalData()
        return invitation
    }

    func linkExistingParentInvitation(_ invitationID: UUID, to studentID: UUID) {
        guard let index = parentInvitations.firstIndex(where: { $0.id == invitationID }) else { return }
        if !parentInvitations[index].studentIDs.contains(studentID) { parentInvitations[index].studentIDs.append(studentID) }
        let email = parentInvitations[index].email.lowercased()
        if schoolMembers.contains(where: { $0.email.lowercased() == email && $0.role == .parent }) {
            if !linkedChildIDsByParent[email, default: []].contains(studentID) { linkedChildIDsByParent[email, default: []].append(studentID) }
        }
        saveLocalData()
    }

    func unlinkParentInvitation(_ invitationID: UUID, from studentID: UUID) {
        guard let index = parentInvitations.firstIndex(where: { $0.id == invitationID }) else { return }
        parentInvitations[index].studentIDs.removeAll { $0 == studentID }
        let email = parentInvitations[index].email.lowercased()
        linkedChildIDsByParent[email]?.removeAll { $0 == studentID }
        saveLocalData()
    }

    func regenerateParentInvitation(_ invitationID: UUID) {
        guard let index = parentInvitations.firstIndex(where: { $0.id == invitationID }) else { return }
        parentInvitations[index].code = "GEN-\(Int.random(in: 100000...999999))"
        parentInvitations[index].isActive = true
        saveLocalData()
    }

    func toggleMember(_ id: UUID) {
        guard let index = schoolMembers.firstIndex(where: { $0.id == id }) else { return }
        schoolMembers[index].isActive.toggle()
        saveLocalData()
    }

    func deleteMember(_ id: UUID) {
        schoolMembers.removeAll { $0.id == id }
        saveLocalData()
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
        let ids = courseEnrollments[courseID] ?? []
        return students.filter { ids.contains($0.id) }
    }

    func coursesForStudent(_ studentID: UUID) -> [DanceCourse] {
        courses.filter { courseEnrollments[$0.id, default: []].contains(studentID) }
    }

    func enrolledCount(for courseID: UUID) -> Int {
        courseEnrollments[courseID]?.count ?? 0
    }

    func assignedTeachers(for courseID: UUID) -> [SchoolMember] {
        let ids = teacherAssignments[courseID] ?? []
        return schoolMembers.filter { $0.role == .teacher && ids.contains($0.id) }
    }

    func toggleTeacher(_ teacherID: UUID, for courseID: UUID) {
        var ids = teacherAssignments[courseID] ?? []
        if ids.contains(teacherID) { ids.remove(teacherID) } else { ids.insert(teacherID) }
        teacherAssignments[courseID] = ids
        if let courseIndex = courses.firstIndex(where: { $0.id == courseID }) {
            let names = assignedTeachers(for: courseID).map(\.name)
            courses[courseIndex].teacher = names.isEmpty ? "Da assegnare" : names.joined(separator: ", ")
        }
        saveLocalData()
    }

    func addCourse(_ course: DanceCourse) {
        courses.append(course)
        courseEnrollments[course.id] = []
        teacherAssignments[course.id] = []
        let start = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        lessons.append(CourseLesson(courseID: course.id, start: start, room: course.room))
        saveLocalData()
    }

    func deleteCourses(at offsets: IndexSet, from visibleCourses: [DanceCourse]) {
        let ids = offsets.compactMap { visibleCourses.indices.contains($0) ? visibleCourses[$0].id : nil }
        courses.removeAll { ids.contains($0.id) }
        for id in ids {
            courseEnrollments.removeValue(forKey: id)
            teacherAssignments.removeValue(forKey: id)
            let lessonIDs = Set(lessons.filter { $0.courseID == id }.map(\.id))
            lessons.removeAll { $0.courseID == id }
            lessonAttendance.removeAll { lessonIDs.contains($0.lessonID) }
            paymentRecords.removeAll { $0.courseID == id }
        }
        saveLocalData()
    }

    func addStudent(_ student: Student) {
        var newStudent = student
        if newStudent.familyCode == nil || newStudent.familyCode?.isEmpty == true {
            newStudent.familyCode = makeUniqueFamilyCode()
        }
        students.append(newStudent)
        saveLocalData()
    }

    func assignStudent(_ studentID: UUID, toCourseID courseID: UUID) {
        guard students.contains(where: { $0.id == studentID }),
              let course = courses.first(where: { $0.id == courseID }) else { return }
        courseEnrollments[courseID, default: []].insert(studentID)
        if let studentIndex = students.firstIndex(where: { $0.id == studentID }), students[studentIndex].course == "Nessun corso" {
            students[studentIndex].course = course.title
        }
        saveLocalData()
    }

    func removeStudent(_ studentID: UUID, fromCourseID courseID: UUID) {
        guard let course = courses.first(where: { $0.id == courseID }) else { return }
        courseEnrollments[courseID]?.remove(studentID)
        attendanceByCourse[course.title]?.remove(studentID)
        if let studentIndex = students.firstIndex(where: { $0.id == studentID }) {
            let remaining = coursesForStudent(studentID)
            students[studentIndex].course = remaining.first?.title ?? "Nessun corso"
        }
        saveLocalData()
    }

    func isStudent(_ studentID: UUID, enrolledIn courseID: UUID) -> Bool {
        courseEnrollments[courseID, default: []].contains(studentID)
    }

    func deleteStudents(at offsets: IndexSet, from visibleStudents: [Student]) {
        let ids = offsets.compactMap { visibleStudents.indices.contains($0) ? visibleStudents[$0].id : nil }
        students.removeAll { ids.contains($0.id) }
        for key in Array(attendanceByCourse.keys) {
            attendanceByCourse[key]?.subtract(ids)
        }
        for courseID in Array(courseEnrollments.keys) {
            courseEnrollments[courseID]?.subtract(ids)
        }
        lessonAttendance.removeAll { ids.contains($0.studentID) }
        paymentRecords.removeAll { ids.contains($0.studentID) }
        documents.removeAll { ids.contains($0.studentID) }
        childLinkRequests.removeAll { ids.contains($0.studentID) }
        for email in Array(linkedChildIDsByParent.keys) { linkedChildIDsByParent[email]?.removeAll { ids.contains($0) } }
        for index in danceEvents.indices { danceEvents[index].participantIDs.removeAll { ids.contains($0) } }
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

    private func ensureCourseEnrollments() {
        guard courseEnrollments.isEmpty else { return }
        for student in students {
            if let course = courses.first(where: { $0.title == student.course }) {
                courseEnrollments[course.id, default: []].insert(student.id)
            }
        }
        saveLocalData()
    }

    private func ensureTeacherAssignments() {
        guard teacherAssignments.isEmpty else { return }
        for course in courses {
            let matching = schoolMembers.filter { $0.role == .teacher && course.teacher.localizedCaseInsensitiveContains($0.name) }
            teacherAssignments[course.id] = Set(matching.map(\.id))
        }
        saveLocalData()
    }


    func lessonsForCourse(_ courseID: UUID) -> [CourseLesson] {
        lessons.filter { $0.courseID == courseID }.sorted { $0.start < $1.start }
    }

    func lessonsForStudent(_ studentID: UUID) -> [CourseLesson] {
        let courseIDs = Set(coursesForStudent(studentID).map(\.id))
        return lessons.filter { courseIDs.contains($0.courseID) }.sorted { $0.start < $1.start }
    }

    func lessonsForCurrentStaff() -> [CourseLesson] {
        guard userRole == .teacher, let memberID = currentMember?.id else { return lessons.sorted { $0.start < $1.start } }
        let allowedCourseIDs = Set(teacherAssignments.filter { $0.value.contains(memberID) }.map(\.key))
        return lessons.filter { allowedCourseIDs.contains($0.courseID) }.sorted { $0.start < $1.start }
    }

    func addLesson(_ lesson: CourseLesson) { lessons.append(lesson); saveLocalData() }
    func updateLesson(_ lesson: CourseLesson) { if let i = lessons.firstIndex(where: { $0.id == lesson.id }) { lessons[i] = lesson; saveLocalData() } }
    func deleteLesson(_ id: UUID) { lessons.removeAll { $0.id == id }; lessonAttendance.removeAll { $0.lessonID == id }; saveLocalData() }

    func attendanceState(lessonID: UUID, studentID: UUID) -> AttendanceState? {
        lessonAttendance.first { $0.lessonID == lessonID && $0.studentID == studentID }?.state
    }

    func setAttendance(_ state: AttendanceState, lessonID: UUID, studentID: UUID, note: String = "") {
        if let i = lessonAttendance.firstIndex(where: { $0.lessonID == lessonID && $0.studentID == studentID }) {
            lessonAttendance[i].state = state; lessonAttendance[i].note = note; lessonAttendance[i].updatedAt = Date()
        } else {
            lessonAttendance.append(LessonAttendance(lessonID: lessonID, studentID: studentID, state: state, note: note, recordedBy: currentMember?.name ?? ownerName))
        }
        saveLocalData()
    }

    func attendanceForStudent(_ studentID: UUID) -> [LessonAttendance] {
        lessonAttendance.filter { $0.studentID == studentID }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func addPaymentRecord(_ record: PaymentRecord) {
        paymentRecords.insert(record, at: 0)
        if let i = students.firstIndex(where: { $0.id == record.studentID }) { students[i].paymentStatus = record.status }
        saveLocalData()
    }
    func updatePaymentRecord(_ record: PaymentRecord) {
        if let i = paymentRecords.firstIndex(where: { $0.id == record.id }) { paymentRecords[i] = record }
        if let i = students.firstIndex(where: { $0.id == record.studentID }) { students[i].paymentStatus = record.status }
        saveLocalData()
    }
    func paymentsForStudent(_ studentID: UUID) -> [PaymentRecord] { paymentRecords.filter { $0.studentID == studentID }.sorted { $0.dueDate > $1.dueDate } }

    func addDocument(_ document: SchoolDocument) { documents.insert(document, at: 0); saveLocalData() }
    func updateDocument(_ document: SchoolDocument) { if let i = documents.firstIndex(where: { $0.id == document.id }) { documents[i] = document; saveLocalData() } }
    func documentsForStudent(_ studentID: UUID) -> [SchoolDocument] { documents.filter { $0.studentID == studentID } }

    func addDanceEvent(_ event: DanceEvent) { danceEvents.insert(event, at: 0); saveLocalData() }
    func updateDanceEvent(_ event: DanceEvent) { if let i = danceEvents.firstIndex(where: { $0.id == event.id }) { danceEvents[i] = event; saveLocalData() } }

    func permissions(for memberID: UUID) -> StaffPermissions { staffPermissions[memberID] ?? StaffPermissions() }
    func setPermissions(_ permissions: StaffPermissions, for memberID: UUID) { staffPermissions[memberID] = permissions; saveLocalData() }

    private func ensureOperationalData() {
        if lessons.isEmpty {
            let calendar = Calendar.current
            for (index, course) in courses.enumerated() {
                let base = calendar.date(byAdding: .day, value: index + 1, to: Date()) ?? Date()
                let parts = course.time.split(separator: ":").compactMap { Int($0) }
                var comps = calendar.dateComponents([.year, .month, .day], from: base)
                comps.hour = parts.first ?? 17; comps.minute = parts.count > 1 ? parts[1] : 0
                let start = calendar.date(from: comps) ?? base
                lessons.append(CourseLesson(courseID: course.id, start: start, room: course.room, teacherID: teacherAssignments[course.id]?.first))
                if let next = calendar.date(byAdding: .day, value: 7, to: start) { lessons.append(CourseLesson(courseID: course.id, start: next, room: course.room, teacherID: teacherAssignments[course.id]?.first)) }
            }
        }
        if paymentRecords.isEmpty {
            for student in students {
                paymentRecords.append(PaymentRecord(studentID: student.id, courseID: coursesForStudent(student.id).first?.id, type: .monthly, title: "Quota mensile", amount: 50, paidAmount: student.paymentStatus == .paid ? 50 : 0, dueDate: Calendar.current.date(byAdding: .day, value: student.paymentStatus == .late ? -5 : 10, to: Date()) ?? Date(), status: student.paymentStatus, method: student.paymentStatus == .paid ? "Bonifico" : "Da definire"))
            }
        }
        if documents.isEmpty {
            for student in students { documents.append(SchoolDocument(studentID: student.id, title: "Certificato medico", kind: "Certificato", issueDate: Date(), expiryDate: Calendar.current.date(byAdding: .month, value: student.medicalStatus == .expired ? -1 : 6, to: Date()), reviewStatus: student.medicalStatus == .valid ? .approved : .pending, hasAttachment: student.medicalStatus == .valid)) }
        }
        if danceEvents.isEmpty, let course = courses.first {
            danceEvents = [DanceEvent(title: "Saggio d’estate", date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(), location: "Teatro Aurora", courseIDs: [course.id], participantIDs: Array(courseEnrollments[course.id] ?? []), rehearsalDates: [], fee: 25, costumeNote: "Costume nero", performanceOrder: "Da definire")]
        }
        for member in schoolMembers where member.role == .secretary { if staffPermissions[member.id] == nil { staffPermissions[member.id] = StaffPermissions() } }
        saveLocalData()
    }

    func createInvite(role: UserRole, maxUses: Int) -> InviteCode {
        let prefix: String
        switch role {
        case .secretary: prefix = "SEG"
        case .teacher: prefix = "DOC"
        case .parent, .student: prefix = "FAM"
        case .owner: prefix = "OWN"
        }
        var generated = ""
        repeat { generated = "\(prefix)-\(Int.random(in: 100000...999999))" }
        while inviteCodes.contains(where: { $0.code == generated })
        let invite = InviteCode(code: generated, role: role, maxUses: maxUses)
        inviteCodes.insert(invite, at: 0)
        saveLocalData()
        return invite
    }

    func toggleInvite(_ id: UUID) {
        guard let index = inviteCodes.firstIndex(where: { $0.id == id }) else { return }
        inviteCodes[index].isActive.toggle()
        saveLocalData()
    }

    func regenerateInvite(_ id: UUID) {
        guard let index = inviteCodes.firstIndex(where: { $0.id == id }) else { return }
        let role = inviteCodes[index].role
        let prefix: String
        switch role {
        case .secretary: prefix = "SEG"
        case .teacher: prefix = "DOC"
        case .parent, .student: prefix = "FAM"
        case .owner: prefix = "OWN"
        }
        inviteCodes[index].code = "\(prefix)-\(Int.random(in: 100000...999999))"
        inviteCodes[index].usedCount = 0
        inviteCodes[index].isActive = true
        inviteCodes[index].createdAt = Date()
        saveLocalData()
    }

    func deleteInvite(_ id: UUID) {
        inviteCodes.removeAll { $0.id == id }
        saveLocalData()
    }

    func resetDemoData() {
        courses = Self.demoCourses
        students = Self.demoStudents
        announcements = Self.demoAnnouncements
        attendanceByCourse = [:]
        courseEnrollments = [:]
        teacherAssignments = [:]
        lessons = []
        lessonAttendance = []
        paymentRecords = []
        documents = []
        danceEvents = []
        staffPermissions = [:]
        inviteCodes = Self.demoInviteCodes
        schoolMembers = Self.demoMembers
        parentInvitations = []
        childLinkRequests = []
        linkedChildIDsByParent = [:]
        ensureStudentFamilyCodes()
        ensureCourseEnrollments()
        ensureTeacherAssignments()
        ensureOperationalData()
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
            attendanceByCourse: attendanceByCourse.mapValues(Array.init),
            courseEnrollments: courseEnrollments.mapValues(Array.init),
            teacherAssignments: teacherAssignments.mapValues(Array.init),
            inviteCodes: inviteCodes,
            schoolMembers: schoolMembers,
            parentInvitations: parentInvitations,
            childLinkRequests: childLinkRequests,
            linkedChildIDsByParent: linkedChildIDsByParent,
            lessons: lessons,
            lessonAttendance: lessonAttendance,
            paymentRecords: paymentRecords,
            documents: documents,
            danceEvents: danceEvents,
            staffPermissions: staffPermissions
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
            courseEnrollments = (snapshot.courseEnrollments ?? [:]).mapValues(Set.init)
            teacherAssignments = (snapshot.teacherAssignments ?? [:]).mapValues(Set.init)
            inviteCodes = snapshot.inviteCodes ?? Self.demoInviteCodes
            schoolMembers = snapshot.schoolMembers ?? Self.demoMembers
            parentInvitations = snapshot.parentInvitations ?? []
            childLinkRequests = snapshot.childLinkRequests ?? []
            linkedChildIDsByParent = snapshot.linkedChildIDsByParent ?? [:]
            lessons = snapshot.lessons ?? []
            lessonAttendance = snapshot.lessonAttendance ?? []
            paymentRecords = snapshot.paymentRecords ?? []
            documents = snapshot.documents ?? []
            danceEvents = snapshot.danceEvents ?? []
            staffPermissions = snapshot.staffPermissions ?? [:]
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
        var courseEnrollments: [UUID: [UUID]]?
        var teacherAssignments: [UUID: [UUID]]?
        var inviteCodes: [InviteCode]?
        var schoolMembers: [SchoolMember]?
        var parentInvitations: [ParentInvitation]?
        var childLinkRequests: [ChildLinkRequest]?
        var linkedChildIDsByParent: [String: [UUID]]?
        var lessons: [CourseLesson]?
        var lessonAttendance: [LessonAttendance]?
        var paymentRecords: [PaymentRecord]?
        var documents: [SchoolDocument]?
        var danceEvents: [DanceEvent]?
        var staffPermissions: [UUID: StaffPermissions]?
    }

    static let demoMembers: [SchoolMember] = [
        SchoolMember(name: "Giulia Ferri", email: "giulia@danzup.demo", role: .teacher, inviteCode: "DOC-482103"),
        SchoolMember(name: "Laura Bianchi", email: "laura@danzup.demo", role: .secretary, inviteCode: "SEG-729412"),
        SchoolMember(name: "Anna Romano", email: "anna@danzup.demo", role: .parent, inviteCode: "FAM-156824")
    ]

    static let demoInviteCodes: [InviteCode] = [
        InviteCode(code: "DOC-482103", role: .teacher, maxUses: 3, usedCount: 1),
        InviteCode(code: "SEG-729412", role: .secretary, maxUses: 2, usedCount: 1),
        InviteCode(code: "FAM-156824", role: .parent, maxUses: 15, usedCount: 3)
    ]

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
