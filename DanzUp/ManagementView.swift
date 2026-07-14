import SwiftUI

struct ManagementView: View {
    private let items: [ManagementItem] = [
        ManagementItem(kind: .attendance, title: "Presenze", subtitle: "Registro, assenze e recuperi", icon: "checkmark.circle.fill", tint: .green, badge: "Oggi 46"),
        ManagementItem(kind: .payments, title: "Quote", subtitle: "Pagamenti, ricevute e scadenze", icon: "eurosign.circle.fill", tint: .orange, badge: "7 scadute"),
        ManagementItem(kind: .medical, title: "Certificati", subtitle: "Documenti e scadenze mediche", icon: "cross.case.fill", tint: .blue, badge: "4 avvisi"),
        ManagementItem(kind: .announcements, title: "Comunicazioni", subtitle: "Avvisi mirati e notifiche", icon: "megaphone.fill", tint: .dzFuchsia, badge: "2 nuove"),
        ManagementItem(kind: .events, title: "Saggi ed eventi", subtitle: "Prove, costumi e partecipanti", icon: "star.fill", tint: .dzPurple, badge: "1 attivo"),
        ManagementItem(kind: .staff, title: "Staff e inviti", subtitle: "Ruoli e codici di accesso", icon: "person.2.badge.gearshape.fill", tint: .indigo, badge: "8 membri")
    ]

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle("Centro gestione", subtitle: "Operazioni riservate alla scuola e alla segreteria")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                        ForEach(items) { item in
                            NavigationLink { destination(for: item.kind) } label: { ManagementTile(item: item) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Gestione")
    }

    @ViewBuilder
    private func destination(for kind: ManagementKind) -> some View {
        switch kind {
        case .attendance: OwnerAttendanceView()
        case .payments: PaymentsManagementView()
        case .medical: MedicalCertificatesView()
        case .announcements: CommunicationsManagementView()
        case .events: EventsManagementView()
        case .staff: InviteCenterView()
        }
    }
}

enum ManagementKind { case attendance, payments, medical, announcements, events, staff }
struct ManagementItem: Identifiable { let id = UUID(); let kind: ManagementKind; let title: String; let subtitle: String; let icon: String; let tint: Color; let badge: String }

private struct ManagementTile: View {
    let item: ManagementItem
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.icon).font(.title2).foregroundColor(item.tint)
                    .frame(width: 46, height: 46).background(item.tint.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 15))
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption.bold()).foregroundColor(.secondary)
            }
            Text(item.title).font(.headline).foregroundColor(.primary)
            Text(item.subtitle).font(.caption).foregroundColor(.secondary).lineLimit(2)
            Text(item.badge).font(.caption2.bold()).foregroundColor(item.tint)
                .padding(.horizontal, 9).padding(.vertical, 5).background(item.tint.opacity(0.10)).clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 165, alignment: .leading)
        .padding(15).background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.primary.opacity(0.05)))
    }
}

struct OwnerAttendanceView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedCourse = "Hip Hop Teen"
    @State private var showSaved = false

    private var visibleStudents: [Student] {
        let matches = store.students.filter { $0.course == selectedCourse }
        return matches.isEmpty ? store.students : matches
    }

    var body: some View {
        List {
            Section("Lezione") {
                Picker("Corso", selection: $selectedCourse) {
                    ForEach(store.courses.map(\.title), id: \.self) { Text($0) }
                }
                Label("Le modifiche vengono salvate automaticamente", systemImage: "checkmark.icloud.fill")
                    .font(.caption).foregroundColor(.secondary)
            }
            Section("Registro presenze") {
                ForEach(visibleStudents) { student in
                    Button {
                        store.toggleAttendance(studentID: student.id, courseTitle: selectedCourse)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(student.name).foregroundColor(.primary)
                                Text(student.course).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: store.isPresent(studentID: student.id, courseTitle: selectedCourse) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(store.isPresent(studentID: student.id, courseTitle: selectedCourse) ? .green : .secondary)
                        }
                    }
                }
            }
            Section { Button("Conferma registro") { store.saveLocalData(); showSaved = true } }
        }
        .navigationTitle("Presenze")
        .alert("Registro salvato", isPresented: $showSaved) { Button("OK", role: .cancel) {} }
    }
}

struct PaymentsManagementView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: String
    @State private var selectedStudent: Student?

    init(initialFilter: String = "Tutte") {
        _filter = State(initialValue: initialFilter)
    }

    private var filteredStudents: [Student] {
        switch filter {
        case "Pagate": return store.students.filter { $0.paymentStatus == .paid }
        case "Da pagare": return store.students.filter { $0.paymentStatus == .due }
        case "Scadute": return store.students.filter { $0.paymentStatus == .late }
        default: return store.students
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Stato", selection: $filter) {
                    ForEach(["Tutte", "Pagate", "Da pagare", "Scadute"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Riepilogo luglio") {
                HStack { FinanceMetric(value: "€4.280", label: "Incassato", tint: .green); FinanceMetric(value: "€630", label: "Da incassare", tint: .orange) }
            }
            Section("Allievi") {
                ForEach(filteredStudents) { student in
                    Button { selectedStudent = student } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.name).font(.headline)
                            Text(student.course).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(student.paymentStatus.rawValue).font(.caption.bold()).foregroundColor(student.paymentStatus.color)
                    }
                    }.buttonStyle(.plain)
                }
            }
            Section { Button { selectedStudent = filteredStudents.first } label: { Label("Registra nuovo pagamento", systemImage: "plus.circle.fill") }; Button {} label: { Label("Esporta riepilogo", systemImage: "square.and.arrow.up") } }
        }
        .navigationTitle("Quote")
        .sheet(item: $selectedStudent) { student in PaymentEditorView(student: student) }
    }
}

private struct PaymentEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let student: Student
    @State private var status: PaymentStatus
    @State private var amount = "50,00"
    init(student: Student) { self.student = student; _status = State(initialValue: student.paymentStatus) }
    var body: some View { NavigationStack { Form { Section("Allievo") { LabeledContent("Nome", value: student.name); LabeledContent("Corso", value: student.course) }; Section("Pagamento") { TextField("Importo", text: $amount).keyboardType(.decimalPad); Picker("Stato", selection: $status) { Text("Pagata").tag(PaymentStatus.paid); Text("Da pagare").tag(PaymentStatus.due); Text("Scaduta").tag(PaymentStatus.late) } } } .navigationTitle("Registra pagamento") .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salva") { store.setPayment(status, for: student.id); dismiss() } } } } }
}

private struct FinanceMetric: View {
    let value: String; let label: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { Text(value).font(.title3.bold()); Text(label).font(.caption).foregroundColor(.secondary) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(tint.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MedicalCertificatesView: View {
    @EnvironmentObject var store: AppStore
    let showOnlyAlerts: Bool
    @State private var selectedStudent: Student?
    init(showOnlyAlerts: Bool = false) { self.showOnlyAlerts = showOnlyAlerts }
    private var visibleStudents: [Student] { showOnlyAlerts ? store.students.filter { $0.medicalStatus != .valid } : store.students }
    var body: some View {
        List {
            Section("Scadenze") {
                ForEach(visibleStudents) { student in
                    Button { selectedStudent = student } label: {
                    HStack {
                        VStack(alignment: .leading) { Text(student.name).font(.headline); Text(student.course).font(.caption).foregroundColor(.secondary) }
                        Spacer()
                        Text(student.medicalStatus.rawValue).font(.caption.bold()).foregroundColor(student.medicalStatus.color)
                    }
                    }.buttonStyle(.plain)
                }
            }
            Section("Azioni") { Button {} label: { Label("Invia promemoria scadenze", systemImage: "bell.badge.fill") }; Button { selectedStudent = visibleStudents.first } label: { Label("Carica certificato", systemImage: "square.and.arrow.up.fill") } }
        }
        .navigationTitle("Certificati")
        .sheet(item: $selectedStudent) { student in MedicalEditorView(student: student) }
    }
}

private struct MedicalEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let student: Student
    @State private var status: MedicalStatus
    init(student: Student) { self.student = student; _status = State(initialValue: student.medicalStatus) }
    var body: some View { NavigationStack { Form { Section("Allievo") { LabeledContent("Nome", value: student.name) }; Section("Certificato") { Picker("Stato", selection: $status) { Text("Valido").tag(MedicalStatus.valid); Text("In scadenza").tag(MedicalStatus.expiring); Text("Scaduto").tag(MedicalStatus.expired) }; DatePicker("Scadenza", selection: .constant(Date()), displayedComponents: .date) } } .navigationTitle("Certificato") .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salva") { store.setMedical(status, for: student.id); dismiss() } } } } }
}

struct CommunicationsManagementView: View {
    @EnvironmentObject var store: AppStore
    @State private var showComposer: Bool
    init(openComposerOnAppear: Bool = false) { _showComposer = State(initialValue: openComposerOnAppear) }

    var body: some View {
        List {
            Section("Comunicazioni pubblicate") {
                ForEach(store.announcements) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(item.title).font(.headline); Spacer(); Text(item.audience).font(.caption2.bold()).foregroundColor(.dzPurple) }
                        Text(item.body).font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Comunicazioni")
        .toolbar { Button { showComposer = true } label: { Image(systemName: "square.and.pencil") } }
        .sheet(isPresented: $showComposer) { CommunicationComposerView() }
    }
}

private struct CommunicationComposerView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var message = ""
    @State private var audience = "Tutta la scuola"

    var body: some View {
        NavigationStack {
            Form {
                Section("Destinatari") { Picker("Invia a", selection: $audience) { ForEach(["Tutta la scuola", "Solo insegnanti", "Solo genitori", "Corso specifico"], id: \.self) { Text($0) } } }
                Section("Messaggio") { TextField("Titolo", text: $title); TextEditor(text: $message).frame(minHeight: 140) }
                Section { Toggle("Invia notifica push", isOn: .constant(true)) }
            }
            .navigationTitle("Nuovo avviso")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Pubblica") { store.addAnnouncement(title: title, body: message, audience: audience); dismiss() }.disabled(title.isEmpty || message.isEmpty) } }
        }
    }
}

struct EventsManagementView: View {
    var body: some View {
        List {
            Section("Evento attivo") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saggio d’estate 2026").font(.title3.bold())
                    Label("28 giugno • Teatro Aurora", systemImage: "calendar")
                    Label("112 partecipanti confermati", systemImage: "person.3.fill")
                    ProgressView(value: 0.72) { Text("Preparazione") }
                }
                .padding(.vertical, 6)
            }
            Section("Organizzazione") {
                Label("Calendario prove", systemImage: "calendar.badge.clock")
                Label("Ordine esibizioni", systemImage: "list.number")
                Label("Costumi e taglie", systemImage: "tshirt.fill")
                Label("Partecipanti e conferme", systemImage: "person.crop.circle.badge.checkmark")
                Label("Quote evento", systemImage: "eurosign.circle.fill")
            }
            Section { Label("Crea nuovo evento", systemImage: "plus.circle.fill") }
        }
        .navigationTitle("Saggi ed eventi")
    }
}

struct InviteCenterView: View {
    @State private var showNewInvite = false

    var body: some View {
        List {
            Section("Codici attivi") {
                InviteRow(code: "DOC-4821", role: "Insegnante", uses: "2 utilizzi rimasti", tint: .dzPurple)
                InviteRow(code: "SEG-7294", role: "Segreteria", uses: "1 utilizzo rimasto", tint: .indigo)
                InviteRow(code: "FAM-1568", role: "Genitore / Allievo", uses: "12 utilizzi rimasti", tint: .green)
            }
            Section("Staff") {
                Label("Giulia Ferri • Insegnante", systemImage: "figure.dance")
                Label("Marco De Luca • Insegnante", systemImage: "figure.dance")
                Label("Elena Rossi • Segreteria", systemImage: "person.crop.rectangle.stack.fill")
            }
            Section { Button { showNewInvite = true } label: { Label("Genera nuovo invito", systemImage: "qrcode") } }
        }
        .navigationTitle("Staff e inviti")
        .sheet(isPresented: $showNewInvite) { NewInviteView() }
    }
}

private struct InviteRow: View {
    let code: String; let role: String; let uses: String; let tint: Color
    var body: some View {
        HStack {
            Image(systemName: "qrcode").font(.title2).foregroundColor(tint)
            VStack(alignment: .leading) { Text(code).font(.headline.monospaced()); Text("\(role) • \(uses)").font(.caption).foregroundColor(.secondary) }
            Spacer()
            Image(systemName: "doc.on.doc").foregroundColor(.secondary)
        }
    }
}

private struct NewInviteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var role = "Insegnante"
    @State private var uses = 1

    var body: some View {
        NavigationStack {
            Form {
                Picker("Ruolo", selection: $role) { ForEach(["Segreteria", "Insegnante", "Genitore / Allievo"], id: \.self) { Text($0) } }
                Stepper("Numero di utilizzi: \(uses)", value: $uses, in: 1...50)
                Section { Text("Il codice consentirà solo l’accesso al ruolo selezionato e potrà essere disattivato dalla scuola.").font(.caption).foregroundColor(.secondary) }
            }
            .navigationTitle("Nuovo invito")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Genera") { dismiss() } } }
        }
    }
}
