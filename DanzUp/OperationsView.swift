import SwiftUI

struct LessonsManagementView: View {
    @EnvironmentObject var store: AppStore
    @State private var showEditor = false
    @State private var selectedLesson: CourseLesson?

    var body: some View {
        List {
            Section("Prossime lezioni") {
                ForEach(store.lessons.sorted { $0.start < $1.start }) { lesson in
                    Button { selectedLesson = lesson } label: {
                        LessonRow(lesson: lesson)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Lezioni e calendario")
        .toolbar { Button { showEditor = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $showEditor) { LessonEditorView() }
        .sheet(item: $selectedLesson) { LessonEditorView(existing: $0) }
    }
}

private struct LessonRow: View {
    @EnvironmentObject var store: AppStore
    let lesson: CourseLesson
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(lesson.start.formatted(.dateTime.day())).font(.title2.bold())
                Text(lesson.start.formatted(.dateTime.month(.abbreviated))).font(.caption).foregroundColor(.secondary)
            }.frame(width: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.courses.first(where: { $0.id == lesson.courseID })?.title ?? "Corso").font(.headline)
                Text(lesson.start.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
                Label(lesson.room, systemImage: "mappin.and.ellipse").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(lesson.state.rawValue).font(.caption2.bold()).foregroundColor(lesson.state == .cancelled ? .red : .dzPurple)
        }.padding(.vertical, 4)
    }
}

private struct LessonEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let existing: CourseLesson?
    @State private var courseID: UUID?
    @State private var start = Date()
    @State private var duration = 75
    @State private var room = "Sala principale"
    @State private var teacherID: UUID?
    @State private var state: LessonState = .scheduled
    @State private var note = ""

    init(existing: CourseLesson? = nil) {
        self.existing = existing
        _courseID = State(initialValue: existing?.courseID)
        _start = State(initialValue: existing?.start ?? Date())
        _duration = State(initialValue: existing?.durationMinutes ?? 75)
        _room = State(initialValue: existing?.room ?? "Sala principale")
        _teacherID = State(initialValue: existing?.teacherID)
        _state = State(initialValue: existing?.state ?? .scheduled)
        _note = State(initialValue: existing?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Lezione") {
                    Picker("Corso", selection: $courseID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(store.courses) { Text($0.title).tag(Optional($0.id)) }
                    }
                    DatePicker("Data e ora", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    Stepper("Durata: \(duration) minuti", value: $duration, in: 30...180, step: 15)
                    TextField("Sala", text: $room)
                    Picker("Insegnante", selection: $teacherID) {
                        Text("Da assegnare").tag(UUID?.none)
                        ForEach(store.schoolMembers.filter { $0.role == .teacher && $0.isActive }) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Picker("Stato", selection: $state) { ForEach(LessonState.allCases) { Text($0.rawValue).tag($0) } }
                    TextField("Nota", text: $note, axis: .vertical)
                }
                if let existing {
                    Section { Button("Elimina lezione", role: .destructive) { store.deleteLesson(existing.id); dismiss() } }
                }
            }
            .navigationTitle(existing == nil ? "Nuova lezione" : "Modifica lezione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salva") { save() }.disabled(courseID == nil || room.isEmpty) }
            }
        }
    }

    private func save() {
        guard let courseID else { return }
        let lesson = CourseLesson(id: existing?.id ?? UUID(), courseID: courseID, start: start, durationMinutes: duration, room: room, teacherID: teacherID, state: state, note: note)
        existing == nil ? store.addLesson(lesson) : store.updateLesson(lesson)
        dismiss()
    }
}

struct LessonAttendanceView: View {
    @EnvironmentObject var store: AppStore
    let lesson: CourseLesson
    private var students: [Student] { store.studentsForCourse(lesson.courseID) }
    var body: some View {
        List {
            Section("Lezione") { LessonRow(lesson: lesson) }
            Section("Registro") {
                if students.isEmpty { Text("Nessun allievo iscritto").foregroundColor(.secondary) }
                ForEach(students) { student in
                    Menu {
                        ForEach(AttendanceState.allCases) { state in Button(state.rawValue) { store.setAttendance(state, lessonID: lesson.id, studentID: student.id) } }
                    } label: {
                        HStack {
                            Text(student.name).foregroundColor(.primary)
                            Spacer()
                            Text(store.attendanceState(lessonID: lesson.id, studentID: student.id)?.rawValue ?? "Da segnare").font(.caption.bold()).foregroundColor(.dzPurple)
                            Image(systemName: "chevron.up.chevron.down").font(.caption)
                        }
                    }
                }
            }
        }.navigationTitle("Registro lezione")
    }
}

struct PaymentsLedgerView: View {
    @EnvironmentObject var store: AppStore
    @State private var showNew = false
    var body: some View {
        List {
            Section("Quote e pagamenti") {
                ForEach(store.paymentRecords) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(record.title).font(.headline); Spacer(); Text(record.status.rawValue).font(.caption.bold()).foregroundColor(record.status.color) }
                        Text(store.students.first(where: { $0.id == record.studentID })?.name ?? "Allievo").font(.subheadline)
                        Text("€\(record.paidAmount, specifier: "%.2f") / €\(record.amount, specifier: "%.2f") • scadenza \(record.dueDate.formatted(date: .numeric, time: .omitted))").font(.caption).foregroundColor(.secondary)
                    }.padding(.vertical, 4)
                }
            }
        }.navigationTitle("Quote reali").toolbar { Button { showNew = true } label: { Image(systemName: "plus") } }.sheet(isPresented: $showNew) { PaymentRecordEditor() }
    }
}

private struct PaymentRecordEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var studentID: UUID?
    @State private var courseID: UUID?
    @State private var type: FeeType = .monthly
    @State private var title = "Quota mensile"
    @State private var amount = 50.0
    @State private var paidAmount = 0.0
    @State private var dueDate = Date()
    @State private var status: PaymentStatus = .due
    @State private var method = "Da definire"
    var body: some View {
        NavigationStack { Form {
            Picker("Allievo", selection: $studentID) { Text("Seleziona").tag(UUID?.none); ForEach(store.students) { Text($0.name).tag(Optional($0.id)) } }
            Picker("Corso", selection: $courseID) { Text("Generale").tag(UUID?.none); ForEach(store.courses) { Text($0.title).tag(Optional($0.id)) } }
            Picker("Tipo", selection: $type) { ForEach(FeeType.allCases) { Text($0.rawValue).tag($0) } }
            TextField("Titolo", text: $title)
            TextField("Importo", value: $amount, format: .number).keyboardType(.decimalPad)
            TextField("Già pagato", value: $paidAmount, format: .number).keyboardType(.decimalPad)
            DatePicker("Scadenza", selection: $dueDate, displayedComponents: .date)
            Picker("Stato", selection: $status) { Text("Pagata").tag(PaymentStatus.paid); Text("Da pagare").tag(PaymentStatus.due); Text("Scaduta").tag(PaymentStatus.late) }
            TextField("Metodo", text: $method)
        }.navigationTitle("Nuova quota").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salva") { if let studentID { store.addPaymentRecord(PaymentRecord(studentID: studentID, courseID: courseID, type: type, title: title, amount: amount, paidAmount: paidAmount, dueDate: dueDate, status: status, method: method)); dismiss() } }.disabled(studentID == nil || title.isEmpty) } } }
    }
}

struct DocumentsOperationalView: View {
    @EnvironmentObject var store: AppStore
    @State private var showNew = false
    var body: some View {
        List {
            Section("Documenti") {
                ForEach(store.documents) { document in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(document.title).font(.headline); Spacer(); Text(document.reviewStatus.rawValue).font(.caption.bold()).foregroundColor(document.reviewStatus == .rejected ? .red : .dzPurple) }
                        Text(store.students.first(where: { $0.id == document.studentID })?.name ?? "Allievo").font(.subheadline)
                        if let expiry = document.expiryDate { Text("Scadenza: \(expiry.formatted(date: .numeric, time: .omitted))").font(.caption).foregroundColor(.secondary) }
                        Label(document.hasAttachment ? "Allegato presente" : "Allegato mancante", systemImage: document.hasAttachment ? "paperclip.circle.fill" : "paperclip.circle").font(.caption).foregroundColor(.secondary)
                    }.padding(.vertical, 4)
                }
            }
        }.navigationTitle("Documenti e certificati").toolbar { Button { showNew = true } label: { Image(systemName: "plus") } }.sheet(isPresented: $showNew) { DocumentEditorView() }
    }
}

private struct DocumentEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var studentID: UUID?
    @State private var title = "Certificato medico"
    @State private var kind = "Certificato"
    @State private var issueDate = Date()
    @State private var expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var status: DocumentReviewStatus = .pending
    @State private var hasAttachment = false
    var body: some View { NavigationStack { Form {
        Picker("Allievo", selection: $studentID) { Text("Seleziona").tag(UUID?.none); ForEach(store.students) { Text($0.name).tag(Optional($0.id)) } }
        TextField("Titolo", text: $title); TextField("Tipo", text: $kind)
        DatePicker("Emissione", selection: $issueDate, displayedComponents: .date)
        DatePicker("Scadenza", selection: $expiryDate, displayedComponents: .date)
        Picker("Verifica", selection: $status) { ForEach(DocumentReviewStatus.allCases) { Text($0.rawValue).tag($0) } }
        Toggle("Foto/PDF allegato", isOn: $hasAttachment)
    }.navigationTitle("Nuovo documento").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salva") { if let studentID { store.addDocument(SchoolDocument(studentID: studentID, title: title, kind: kind, issueDate: issueDate, expiryDate: expiryDate, reviewStatus: status, hasAttachment: hasAttachment)); dismiss() } }.disabled(studentID == nil || title.isEmpty) } } } }
}

struct EventsOperationalView: View {
    @EnvironmentObject var store: AppStore
    @State private var showNew = false
    var body: some View {
        List {
            ForEach(store.danceEvents) { event in
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title).font(.headline)
                    Label(event.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    Label(event.location, systemImage: "mappin.and.ellipse")
                    Text("\(event.participantIDs.count) partecipanti • €\(event.fee, specifier: "%.2f")").font(.caption).foregroundColor(.secondary)
                }.padding(.vertical, 5)
            }
        }.navigationTitle("Saggi ed eventi").toolbar { Button { showNew = true } label: { Image(systemName: "plus") } }.sheet(isPresented: $showNew) { EventEditorView() }
    }
}

private struct EventEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var selectedCourses: Set<UUID> = []
    @State private var fee = 0.0
    @State private var costume = ""
    @State private var order = "Da definire"
    var body: some View { NavigationStack { Form {
        TextField("Titolo", text: $title); DatePicker("Data e ora", selection: $date, displayedComponents: [.date, .hourAndMinute]); TextField("Luogo", text: $location)
        Section("Corsi partecipanti") { ForEach(store.courses) { course in Toggle(course.title, isOn: Binding(get: { selectedCourses.contains(course.id) }, set: { isOn in if isOn { selectedCourses.insert(course.id) } else { selectedCourses.remove(course.id) } })) } }
        TextField("Quota", value: $fee, format: .number).keyboardType(.decimalPad); TextField("Costumi", text: $costume); TextField("Ordine esibizioni", text: $order)
    }.navigationTitle("Nuovo evento").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salva") { let participants = Set(selectedCourses.flatMap { store.courseEnrollments[$0] ?? [] }); store.addDanceEvent(DanceEvent(title: title, date: date, location: location, courseIDs: Array(selectedCourses), participantIDs: Array(participants), rehearsalDates: [], fee: fee, costumeNote: costume, performanceOrder: order)); dismiss() }.disabled(title.isEmpty || location.isEmpty) } } } }
}

struct StaffPermissionsView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        List {
            ForEach(store.schoolMembers.filter { $0.role == .secretary }) { member in
                NavigationLink(member.name) { StaffPermissionEditor(member: member) }
            }
        }.navigationTitle("Permessi segreteria")
    }
}

private struct StaffPermissionEditor: View {
    @EnvironmentObject var store: AppStore
    let member: SchoolMember
    @State private var permissions: StaffPermissions
    init(member: SchoolMember) { self.member = member; _permissions = State(initialValue: StaffPermissions()) }
    var body: some View {
        Form {
            Toggle("Gestione allievi", isOn: $permissions.manageStudents)
            Toggle("Gestione corsi", isOn: $permissions.manageCourses)
            Toggle("Registro presenze", isOn: $permissions.manageAttendance)
            Toggle("Dati economici", isOn: $permissions.managePayments)
            Toggle("Documenti", isOn: $permissions.manageDocuments)
            Toggle("Comunicazioni", isOn: $permissions.sendAnnouncements)
        }.navigationTitle(member.name).onAppear { permissions = store.permissions(for: member.id) }.onDisappear { store.setPermissions(permissions, for: member.id) }
    }
}
