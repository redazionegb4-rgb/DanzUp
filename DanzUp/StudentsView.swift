import SwiftUI

struct StudentsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var showAdd = false

    private var filtered: [Student] {
        search.isEmpty ? store.students : store.students.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            store.coursesForStudent($0.id).contains { $0.title.localizedCaseInsensitiveContains(search) }
        }
    }

    private var lateCount: Int { store.students.filter { $0.paymentStatus == .late }.count }
    private var medicalCount: Int { store.students.filter { $0.medicalStatus != .valid }.count }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScreenBackground()
            ScrollView {
                LazyVStack(spacing: 18) {
                    DZHeroHeader(
                        eyebrow: "Gestione scuola",
                        title: "Allievi",
                        subtitle: "Profili, iscrizioni, famiglie e stato amministrativo in un solo posto.",
                        systemImage: "person.3.fill",
                        accent: .dzPurple
                    )

                    HStack(spacing: 10) {
                        DZMetricTile(value: "\(store.students.count)", label: "Totali", icon: "person.2.fill", color: .dzPurple)
                        DZMetricTile(value: "\(lateCount)", label: "Quote scadute", icon: "creditcard.fill", color: .red)
                        DZMetricTile(value: "\(medicalCount)", label: "Certificati", icon: "cross.case.fill", color: .orange)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Cerca nome o corso", text: $search)
                            .textInputAutocapitalization(.words)
                        if !search.isEmpty {
                            Button { search = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 50)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color.primary.opacity(0.06)))

                    if filtered.isEmpty {
                        DZCard {
                            DZEmptyState(
                                icon: "person.crop.circle.badge.plus",
                                title: search.isEmpty ? "Nessun allievo" : "Nessun risultato",
                                message: search.isEmpty ? "Crea il primo profilo e assegnalo ai corsi della scuola." : "Prova con un nome o un corso diverso.",
                                actionTitle: search.isEmpty ? "Aggiungi allievo" : nil,
                                action: search.isEmpty ? { showAdd = true } : nil
                            )
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filtered) { student in
                                NavigationLink {
                                    StudentDetailView(studentID: student.id)
                                } label: {
                                    StudentModernCard(student: student)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if let index = filtered.firstIndex(where: { $0.id == student.id }) {
                                            store.deleteStudents(at: IndexSet(integer: index), from: filtered)
                                        }
                                    } label: { Label("Elimina", systemImage: "trash") }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            DZFloatingAddButton { showAdd = true }
                .padding(22)
        }
        .navigationTitle("Allievi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) { AddStudentView() }
    }
}

private struct StudentModernCard: View {
    @EnvironmentObject var store: AppStore
    let student: Student

    private var courses: [DanceCourse] { store.coursesForStudent(student.id) }
    private var initials: String {
        student.name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color.dzPurple, Color.dzFuchsia], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 58, height: 58)
                Text(initials).font(.headline.weight(.heavy)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(student.name).font(.headline).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                }
                Text(courses.isEmpty ? "Nessun corso assegnato" : courses.map(\.title).joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    DZStatusChip(text: student.paymentStatus.rawValue, color: student.paymentStatus.color, icon: "creditcard.fill")
                    DZStatusChip(text: student.medicalStatus.rawValue, color: student.medicalStatus.color, icon: "cross.case.fill")
                }
            }
            DZProgressRing(value: Double(student.attendanceRate) / 100, color: .dzPurple, text: "\(student.attendanceRate)%")
        }
        .padding(15)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(Color.primary.opacity(0.055)))
        .shadow(color: .black.opacity(0.055), radius: 14, y: 7)
    }
}

private struct DZStatusChip: View {
    let text: String
    let color: Color
    let icon: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.10), in: Capsule())
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
                ScrollView {
                    VStack(spacing: 18) {
                        StudentProfileHero(student: student)

                        HStack(spacing: 10) {
                            DZMetricTile(value: "\(student.attendanceRate)%", label: "Presenze", icon: "checkmark.circle.fill", color: .dzMint)
                            DZMetricTile(value: "\(store.coursesForStudent(student.id).count)", label: "Corsi", icon: "figure.dance", color: .dzPurple)
                            DZMetricTile(value: "\(store.parentInvitations(for: student.id).count)", label: "Tutori", icon: "figure.2.and.child.holdinghands", color: .dzSky)
                        }

                        DZCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionTitle("Corsi frequentati", subtitle: "Tutte le iscrizioni attive")
                                if store.coursesForStudent(student.id).isEmpty {
                                    DZEmptyState(icon: "figure.dance", title: "Nessun corso", message: "Assegna l’allievo dalla scheda di un corso.")
                                } else {
                                    ForEach(store.coursesForStudent(student.id)) { course in
                                        NavigationLink { CourseDetailView(courseID: course.id) } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "figure.dance")
                                                    .foregroundStyle(.white)
                                                    .frame(width: 40, height: 40)
                                                    .background(Color.dzPurple, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(course.title).font(.subheadline.bold()).foregroundStyle(.primary)
                                                    Text("\(course.day) • \(course.time) • \(course.room)").font(.caption).foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                                            }
                                            .padding(.vertical, 3)
                                        }
                                    }
                                }
                            }
                        }

                        DZCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    SectionTitle("Genitori e tutori", subtitle: "Accessi autorizzati")
                                    Button("Gestisci") { showParentManager = true }.font(.subheadline.bold())
                                }
                                let guardians = store.parentInvitations(for: student.id)
                                if guardians.isEmpty {
                                    DZEmptyState(icon: "person.crop.circle.badge.plus", title: "Nessun tutore", message: "Aggiungi un genitore o un tutore e invia il codice personale.", actionTitle: "Aggiungi", action: { showParentManager = true })
                                } else {
                                    ForEach(guardians) { guardian in
                                        HStack(spacing: 12) {
                                            Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(Color.dzSky)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(guardian.name).font(.subheadline.bold())
                                                Text("\(guardian.relationship) • \(guardian.email)").font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Circle().fill(guardian.isActive ? Color.orange : Color.green).frame(width: 9, height: 9)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
                .background(ScreenBackground())
                .navigationTitle(student.name)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showParentManager) { ParentGuardianManagerView(studentID: student.id) }
            } else {
                DZEmptyState(icon: "exclamationmark.triangle", title: "Allievo non disponibile", message: "Il profilo potrebbe essere stato eliminato.")
            }
        }
    }
}

private struct StudentProfileHero: View {
    let student: Student
    private var initials: String { student.name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined() }
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BrandGradient()
            Circle().fill(Color.white.opacity(0.10)).frame(width: 160, height: 160).offset(x: 230, y: -45)
            HStack(spacing: 17) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.17)).frame(width: 82, height: 82)
                    Text(initials).font(.title.weight(.heavy)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(student.name).font(.title2.weight(.heavy)).foregroundStyle(.white)
                    Text("\(student.age) anni").foregroundStyle(.white.opacity(0.78))
                    HStack(spacing: 7) {
                        Text(student.paymentStatus.rawValue)
                        Text("•")
                        Text(student.medicalStatus.rawValue)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.86))
                }
                Spacer()
            }
            .padding(22)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
        .shadow(color: Color.dzPurple.opacity(0.25), radius: 20, y: 12)
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
