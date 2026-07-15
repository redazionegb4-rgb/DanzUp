import SwiftUI

struct StudentsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var showAdd = false

    var filtered: [Student] {
        search.isEmpty ? store.students : store.students.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.course.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            ForEach(filtered) { student in
                NavigationLink {
                    StudentDetailView(studentID: student.id)
                } label: {
                    HStack(spacing: 14) {
                        Text(initials(student.name))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(BrandGradient())
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(student.name).font(.headline)
                            Text(student.course).font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 7) {
                                StatusPill(text: student.paymentStatus.rawValue, color: student.paymentStatus.color)
                                StatusPill(text: "Pres. \(student.attendanceRate)%", color: Color.dzPurple)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        if let index = filtered.firstIndex(where: { $0.id == student.id }) {
                            store.deleteStudents(at: IndexSet(integer: index), from: filtered)
                        }
                    } label: { Label("Elimina", systemImage: "trash") }
                }
            }
        }
        .navigationTitle("Allievi")
        .searchable(text: $search, prompt: "Cerca allievo o corso")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showAdd = true } label: { Image(systemName: "person.badge.plus") } } }
        .sheet(isPresented: $showAdd) { AddStudentView() }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text).font(.caption2.bold()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }
}

struct StudentDetailView: View {
    @EnvironmentObject var store: AppStore
    @State private var showParentManager = false
    let studentID: UUID

    private var student: Student? { store.students.first { $0.id == studentID } }

    var body: some View {
        Group {
            if let student {
                List {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill").font(.system(size: 64)).foregroundStyle(Color.dzPurple)
                            VStack(alignment: .leading) {
                                Text(student.name).font(.title2.bold())
                                Text("\(student.age) anni • \(student.course)").foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 8)
                    }
                    Section("Situazione") {
                        LabeledContent("Pagamento", value: student.paymentStatus.rawValue)
                        LabeledContent("Certificato", value: student.medicalStatus.rawValue)
                        LabeledContent("Presenze", value: "\(student.attendanceRate)%")
                    }
                    Section("Genitori e tutori") {
                        let guardians = store.parentInvitations(for: student.id)
                        if guardians.isEmpty {
                            Text("Nessun genitore collegato").foregroundStyle(.secondary)
                        } else {
                            ForEach(guardians) { guardian in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(guardian.name).font(.headline)
                                    Text("\(guardian.relationship) • \(guardian.email)").font(.caption).foregroundStyle(.secondary)
                                    HStack {
                                        Text(guardian.isActive ? "Invito da attivare" : "Account attivato")
                                            .font(.caption2.bold())
                                            .foregroundStyle(guardian.isActive ? .orange : .green)
                                        Spacer()
                                        Text(guardian.code).font(.caption.monospaced()).foregroundStyle(Color.dzPurple)
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) { store.unlinkParentInvitation(guardian.id, from: student.id) } label: { Label("Scollega", systemImage: "link.badge.minus") }
                                }
                            }
                        }
                        Button { showParentManager = true } label: { Label("Aggiungi o collega genitore", systemImage: "person.2.badge.plus") }
                    }
                    Section("Azioni rapide") {
                        NavigationLink { PaymentsManagementView(initialFilter: student.paymentStatus == .late ? "Scadute" : "Tutte") } label: { Label("Registra pagamento", systemImage: "eurosign.circle") }
                        NavigationLink { OwnerAttendanceView(initialCourseID: store.courseID(named: student.course)) } label: { Label("Segna presenza", systemImage: "checkmark.circle") }
                        NavigationLink { CommunicationsManagementView(openComposerOnAppear: true) } label: { Label("Invia comunicazione", systemImage: "paperplane") }
                        NavigationLink { MedicalCertificatesView(showOnlyAlerts: false) } label: { Label("Gestisci certificato", systemImage: "cross.case.fill") }
                    }
                }
                .navigationTitle("Scheda allievo")
                .sheet(isPresented: $showParentManager) { ParentGuardianManagerView(studentID: student.id) }
            } else {
                VStack(spacing: 10) { Image(systemName: "person.crop.circle.badge.exclamationmark").font(.largeTitle); Text("Allievo non disponibile").font(.headline) }.foregroundStyle(.secondary)
            }
        }
    }
}

struct AddStudentView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedCourseID: UUID?
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()

    private var age: Int {
        max(3, Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dati allievo") {
                    TextField("Nome e cognome", text: $name)
                    DatePicker("Data di nascita", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                    LabeledContent("Età", value: "\(age) anni")
                }

                Section("Corso") {
                    if store.courses.isEmpty {
                        Label("Prima crea almeno un corso", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    } else {
                        Picker("Assegna al corso", selection: $selectedCourseID) {
                            Text("Seleziona un corso").tag(UUID?.none)
                            ForEach(store.courses) { course in
                                Text("\(course.title) • \(course.day) \(course.time)").tag(Optional(course.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuovo allievo")
            .onAppear {
                if selectedCourseID == nil { selectedCourseID = store.courses.first?.id }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        guard let courseID = selectedCourseID,
                              let course = store.courses.first(where: { $0.id == courseID }) else { return }
                        store.addStudent(Student(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nuovo allievo" : name,
                            course: course.title,
                            age: age,
                            paymentStatus: .due,
                            medicalStatus: .expiring,
                            attendanceRate: 0
                        ))
                        dismiss()
                    }
                    .disabled(store.courses.isEmpty || selectedCourseID == nil)
                }
            }
        }
    }
}


struct ParentGuardianManagerView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let studentID: UUID
    @State private var mode = 0
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var relationship = "Genitore"
    @State private var createdInvitation: ParentInvitation?

    private var availableExisting: [ParentInvitation] {
        store.parentInvitations.filter { !$0.studentIDs.contains(studentID) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Operazione", selection: $mode) {
                    Text("Nuovo genitore").tag(0)
                    Text("Genitore esistente").tag(1)
                }
                .pickerStyle(.segmented)

                if mode == 0 {
                    Section("Dati genitore o tutore") {
                        TextField("Nome e cognome", text: $name)
                        TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                        TextField("Telefono", text: $phone).keyboardType(.phonePad)
                        Picker("Rapporto", selection: $relationship) {
                            ForEach(["Madre", "Padre", "Genitore", "Tutore", "Altro"], id: \.self) { Text($0) }
                        }
                    }
                    Section {
                        Button("Crea, collega e genera invito") {
                            createdInvitation = store.createParentInvitation(name: name, email: email, phone: phone, relationship: relationship, studentID: studentID)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || email.trimmingCharacters(in: .whitespaces).isEmpty)
                    } footer: {
                        Text("Il genitore userà il codice personale per attivare il proprio account e vedrà soltanto gli allievi associati dalla scuola.")
                    }
                } else {
                    Section("Genitori già presenti") {
                        if availableExisting.isEmpty {
                            Text("Non ci sono altri genitori da collegare").foregroundStyle(.secondary)
                        } else {
                            ForEach(availableExisting) { guardian in
                                Button {
                                    store.linkExistingParentInvitation(guardian.id, to: studentID)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(guardian.name).foregroundStyle(.primary)
                                            Text(guardian.email).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "link.badge.plus")
                                    }
                                }
                            }
                        }
                    }
                }

                if let invitation = createdInvitation {
                    Section("Invito creato") {
                        LabeledContent("Codice", value: invitation.code)
                        LabeledContent("Email", value: invitation.email)
                        ShareLink(item: "Sei stato invitato su DanzUp. Scarica l’app e accedi come Genitore usando il codice \(invitation.code) con l’email \(invitation.email).") {
                            Label("Condividi invito", systemImage: "square.and.arrow.up")
                        }
                        Button("Fine") { dismiss() }
                    }
                }
            }
            .navigationTitle("Genitore o tutore")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } } }
        }
    }
}
