import SwiftUI
import UIKit

struct ManagementView: View {
    private let items: [ManagementItem] = [
        ManagementItem(kind: .lessons, title: "Lezioni", subtitle: "Calendario, sale e modifiche", icon: "calendar.badge.clock", tint: .cyan, badge: "Programmazione"),
        ManagementItem(kind: .attendance, title: "Presenze", subtitle: "Registro, assenze e recuperi", icon: "checkmark.circle.fill", tint: .green, badge: "Oggi 46"),
        ManagementItem(kind: .payments, title: "Quote", subtitle: "Pagamenti, ricevute e scadenze", icon: "eurosign.circle.fill", tint: .orange, badge: "7 scadute"),
        ManagementItem(kind: .medical, title: "Certificati", subtitle: "Documenti e scadenze mediche", icon: "cross.case.fill", tint: .blue, badge: "4 avvisi"),
        ManagementItem(kind: .announcements, title: "Comunicazioni", subtitle: "Avvisi mirati e notifiche", icon: "megaphone.fill", tint: .dzFuchsia, badge: "2 nuove"),
        ManagementItem(kind: .events, title: "Saggi ed eventi", subtitle: "Prove, costumi e partecipanti", icon: "star.fill", tint: .dzPurple, badge: "1 attivo"),
        ManagementItem(kind: .staff, title: "Staff e inviti", subtitle: "Ruoli e codici di accesso", icon: "person.2.badge.gearshape.fill", tint: .indigo, badge: "8 membri"),
        ManagementItem(kind: .permissions, title: "Permessi", subtitle: "Autorizzazioni della segreteria", icon: "lock.shield.fill", tint: .purple, badge: "Personalizzati")
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
        case .lessons: LessonsManagementView()
        case .attendance: OwnerAttendanceView()
        case .payments: PaymentsLedgerView()
        case .medical: DocumentsOperationalView()
        case .announcements: CommunicationsManagementView()
        case .events: EventsOperationalView()
        case .staff: InviteCenterView()
        case .permissions: StaffPermissionsView()
        }
    }
}

enum ManagementKind { case lessons, attendance, payments, medical, announcements, events, staff, permissions }
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
    @State private var selectedCourseID: UUID?
    @State private var showSaved = false

    init(initialCourseID: UUID? = nil) {
        _selectedCourseID = State(initialValue: initialCourseID)
    }

    private var selectedCourse: DanceCourse? {
        guard let selectedCourseID else { return nil }
        return store.courses.first { $0.id == selectedCourseID }
    }

    private var visibleStudents: [Student] {
        guard let selectedCourseID else { return [] }
        return store.studentsForCourse(selectedCourseID)
    }

    var body: some View {
        List {
            Section("Lezione") {
                Picker("Corso", selection: $selectedCourseID) {
                    Text("Seleziona corso").tag(UUID?.none)
                    ForEach(store.courses) { course in
                        Text(course.title).tag(Optional(course.id))
                    }
                }
                Label("Le modifiche vengono salvate automaticamente", systemImage: "checkmark.icloud.fill")
                    .font(.caption).foregroundColor(.secondary)
            }

            Section("Registro presenze") {
                if selectedCourseID == nil {
                    Text("Seleziona un corso per aprire il registro.").foregroundColor(.secondary)
                } else if visibleStudents.isEmpty {
                    VStack(spacing: 8) { Image(systemName: "person.2.slash").font(.largeTitle).foregroundColor(.secondary); Text("Nessun allievo iscritto").font(.headline); Text("Assegna prima gli allievi a questo corso.").font(.caption).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 16)
                } else if let course = selectedCourse {
                    ForEach(visibleStudents) { student in
                        Button {
                            store.toggleAttendance(studentID: student.id, courseTitle: course.title)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(student.name).foregroundColor(.primary)
                                    Text(course.title).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: store.isPresent(studentID: student.id, courseTitle: course.title) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(store.isPresent(studentID: student.id, courseTitle: course.title) ? .green : .secondary)
                            }
                        }
                    }
                }
            }

            if let course = selectedCourse {
                Section("Riepilogo") {
                    LabeledContent("Iscritti", value: "\(visibleStudents.count)/\(course.capacity)")
                    LabeledContent("Presenti", value: "\(visibleStudents.filter { store.isPresent(studentID: $0.id, courseTitle: course.title) }.count)")
                }
                Section { Button("Conferma registro") { store.saveLocalData(); showSaved = true } }
            }
        }
        .navigationTitle("Presenze")
        .onAppear {
            if selectedCourseID == nil { selectedCourseID = store.courses.first?.id }
        }
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
                Section("Destinatari") {
                    Picker("Invia a", selection: $audience) {
                        ForEach(["Tutta la scuola", "Solo insegnanti", "Solo genitori"] + store.courses.map { "Corso: \($0.title)" }, id: \.self) { Text($0) }
                    }
                }
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
    @EnvironmentObject var store: AppStore
    @State private var showNewInvite = false
    @State private var copiedCode: String?
    @State private var inviteToDelete: InviteCode?
    @State private var copiedStudentCode: String?

    var body: some View {
        List {
            InviteAccessHeaderSection()

            StudentCodesSection(copiedStudentCode: $copiedStudentCode)

            PendingChildLinksSection()

            AccessCodesSection(
                copiedCode: $copiedCode,
                inviteToDelete: $inviteToDelete
            )

            ConnectedMembersSection()

            Section {
                Button { showNewInvite = true } label: {
                    Label("Genera nuovo codice", systemImage: "qrcode.viewfinder")
                }
            } footer: {
                Text("Scorri un codice verso sinistra per rigenerarlo o eliminarlo; verso destra per attivarlo o disattivarlo.")
            }
        }
        .navigationTitle("Inviti e codici")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNewInvite = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showNewInvite) {
            NewInviteView { role, uses in
                let invite = store.createInvite(role: role, maxUses: uses)
                copiedCode = invite.code
            }
        }
        .alert("Codice copiato", isPresented: copiedCodeAlertBinding) {
            Button("OK") { copiedCode = nil }
        } message: {
            Text(copiedCode ?? "")
        }
        .alert("Codice allievo copiato", isPresented: studentCodeAlertBinding) {
            Button("OK") { copiedStudentCode = nil }
        } message: {
            Text(copiedStudentCode ?? "")
        }
        .confirmationDialog(
            "Eliminare questo codice?",
            isPresented: deleteDialogBinding,
            titleVisibility: .visible
        ) {
            Button("Elimina", role: .destructive) {
                guard let invite = inviteToDelete else { return }
                store.deleteInvite(invite.id)
                inviteToDelete = nil
            }
            Button("Annulla", role: .cancel) { inviteToDelete = nil }
        }
    }

    private var copiedCodeAlertBinding: Binding<Bool> {
        Binding(
            get: { copiedCode != nil },
            set: { newValue in if !newValue { copiedCode = nil } }
        )
    }

    private var studentCodeAlertBinding: Binding<Bool> {
        Binding(
            get: { copiedStudentCode != nil },
            set: { newValue in if !newValue { copiedStudentCode = nil } }
        )
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { inviteToDelete != nil },
            set: { newValue in if !newValue { inviteToDelete = nil } }
        )
    }
}

private struct InviteAccessHeaderSection: View {
    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundColor(.dzPurple)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Accessi controllati").font(.headline)
                    Text("Solo la scuola può generare, disattivare o eliminare i codici.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct StudentCodesSection: View {
    @EnvironmentObject var store: AppStore
    @Binding var copiedStudentCode: String?

    var body: some View {
        Section {
            if store.students.isEmpty {
                Text("Crea prima un allievo per generare il suo codice personale.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.students) { student in
                    StudentFamilyCodeRow(
                        student: student,
                        code: store.familyCode(for: student.id),
                        onCopy: { copyCode($0) },
                        onRegenerate: { store.regenerateFamilyCode(for: student.id) }
                    )
                }
            }
        } header: {
            Text("Codici personali allievi")
        } footer: {
            Text("Ogni codice identifica un solo allievo. Il genitore non può vedere né selezionare altri profili. Rigenerando il codice, le richieste ancora in attesa per quello precedente vengono annullate.")
        }
    }

    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        copiedStudentCode = code
    }
}

private struct PendingChildLinksSection: View {
    @EnvironmentObject var store: AppStore

    private var pendingRequests: [ChildLinkRequest] {
        store.childLinkRequests.filter { $0.status == .pending }
    }

    var body: some View {
        Section("Richieste collegamento figli") {
            if pendingRequests.isEmpty {
                Text("Nessuna richiesta in attesa.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(pendingRequests) { request in
                    PendingChildLinkRow(request: request)
                }
            }
        }
    }
}

private struct PendingChildLinkRow: View {
    @EnvironmentObject var store: AppStore
    let request: ChildLinkRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .foregroundColor(.dzPurple)
                VStack(alignment: .leading) {
                    Text(request.studentName).font(.headline)
                    Text("Richiesto da \(request.parentName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(request.parentEmail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            HStack {
                Button("Rifiuta", role: .destructive) {
                    store.rejectChildLink(request.id)
                }
                Spacer()
                Button("Approva") {
                    store.approveChildLink(request.id)
                }
                .buttonStyle(.borderedProminent)
                .tint(.dzPurple)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AccessCodesSection: View {
    @EnvironmentObject var store: AppStore
    @Binding var copiedCode: String?
    @Binding var inviteToDelete: InviteCode?

    var body: some View {
        Section("Codici di accesso") {
            if store.inviteCodes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessun codice").font(.headline)
                    Text("Genera il primo codice per invitare staff o famiglie.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(store.inviteCodes) { invite in
                    InviteRow(invite: invite, copiedCode: $copiedCode)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { inviteToDelete = invite } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                            Button { store.regenerateInvite(invite.id) } label: {
                                Label("Rigenera", systemImage: "arrow.clockwise")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { store.toggleInvite(invite.id) } label: {
                                Label(
                                    invite.isActive ? "Disattiva" : "Attiva",
                                    systemImage: invite.isActive ? "pause.circle" : "play.circle"
                                )
                            }
                            .tint(invite.isActive ? .gray : .green)
                        }
                }
            }
        }
    }
}

private struct ConnectedMembersSection: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section("Utenti collegati alla scuola") {
            if store.schoolMembers.isEmpty {
                Text("Nessun utente ha ancora utilizzato un codice.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.schoolMembers) { member in
                    ConnectedMemberRow(member: member)
                }
            }
        }
    }
}

private struct ConnectedMemberRow: View {
    @EnvironmentObject var store: AppStore
    let member: SchoolMember

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: member.role.icon)
                .foregroundColor(member.isActive ? .dzPurple : .secondary)
                .frame(width: 34, height: 34)
                .background(Color.dzPurple.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(.headline)
                Text("\(member.role.rawValue) • \(member.email)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Codice usato: \(member.inviteCode)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(member.isActive ? "Attivo" : "Bloccato")
                .font(.caption.bold())
                .foregroundColor(member.isActive ? .green : .red)
        }
        .swipeActions(edge: .leading) {
            Button { store.toggleMember(member.id) } label: {
                Label(
                    member.isActive ? "Blocca" : "Riattiva",
                    systemImage: member.isActive ? "lock" : "lock.open"
                )
            }
            .tint(member.isActive ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { store.deleteMember(member.id) } label: {
                Label("Rimuovi", systemImage: "trash")
            }
        }
    }
}

private struct InviteRow: View {
    let invite: InviteCode
    @Binding var copiedCode: String?

    private var tint: Color {
        switch invite.role { case .teacher: return .dzPurple; case .secretary: return .indigo; case .parent, .student: return .green; case .owner: return .blue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "qrcode").font(.title2).foregroundColor(invite.isActive ? tint : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(invite.code).font(.headline.monospaced()).textSelection(.enabled)
                    Text("\(invite.role.rawValue) • \(invite.statusText)").font(.caption).foregroundColor(invite.isActive ? .secondary : .red)
                }
                Spacer()
                Circle().fill(invite.isActive && invite.remainingUses > 0 ? Color.green : Color.gray).frame(width: 9, height: 9)
            }
            HStack {
                Button {
                    UIPasteboard.general.string = invite.code
                    copiedCode = invite.code
                } label: { Label("Copia", systemImage: "doc.on.doc") }
                .buttonStyle(.bordered)

                ShareLink(item: "Codice DanzUp per \(invite.role.rawValue): \(invite.code)") {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }.buttonStyle(.bordered)
            }.font(.caption)
        }.padding(.vertical, 4)
    }
}

private struct NewInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var role: UserRole = .teacher
    @State private var uses = 1
    let onGenerate: (UserRole, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Destinatario") {
                    Picker("Ruolo", selection: $role) {
                        Text("Segreteria").tag(UserRole.secretary)
                        Text("Insegnante").tag(UserRole.teacher)
                        Text("Genitore").tag(UserRole.parent)
                        Text("Allievo").tag(UserRole.student)
                    }
                }
                Section("Validità") {
                    Stepper("Utilizzi consentiti: \(uses)", value: $uses, in: 1...100)
                    Text("Ogni registrazione consuma un utilizzo. Il codice può essere disattivato in qualsiasi momento.").font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nuovo codice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Genera") { onGenerate(role, uses); dismiss() }.fontWeight(.semibold) }
            }
        }
    }
}


private struct StudentFamilyCodeRow: View {
    let student: Student
    let code: String
    let onCopy: (String) -> Void
    let onRegenerate: () -> Void

    private var shareText: String {
        "Codice personale DanzUp di \(student.name): \(code)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(student.name)
                        .font(.headline)
                    Text(student.course)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(code)
                    .font(.system(.subheadline, design: .monospaced).bold())
                    .foregroundColor(.dzPurple)
            }

            HStack {
                Button {
                    onCopy(code)
                } label: {
                    Label("Copia", systemImage: "doc.on.doc")
                }

                Spacer()

                ShareLink(item: shareText) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }

                Spacer()

                Button {
                    onRegenerate()
                } label: {
                    Label("Rigenera", systemImage: "arrow.clockwise")
                }
                .tint(.orange)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
