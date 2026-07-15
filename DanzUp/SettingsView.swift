import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            switch store.userRole {
            case .owner:
                OwnerSettingsView()
            case .secretary, .teacher:
                StaffProfileView()
            case .parent, .student:
                FamilyProfileView()
            }
        }
    }
}

private struct OwnerSettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showPlans = false
    @State private var notificationsEnabled = true
    @State private var showRestoreMessage = false

    var body: some View {
        List {
            Section {
                ProfileHeader(
                    title: store.schoolName,
                    subtitle: store.ownerName,
                    role: "Proprietario della scuola",
                    icon: "building.2.fill"
                )
            }

            Section("Abbonamento DanzUp") {
                Button { showPlans = true } label: {
                    HStack {
                        Label("Piano \(store.selectedPlan.rawValue)", systemImage: "crown.fill")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Prova attiva").font(.caption.bold()).foregroundColor(.green)
                            Text("\(store.trialDaysRemaining) giorni rimasti").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
                Button { showPlans = true } label: { Label("Gestisci o cambia piano", systemImage: "creditcard.fill") }
                Button { showRestoreMessage = true } label: { Label("Ripristina acquisti", systemImage: "arrow.clockwise") }
            }

            Section("Gestione scuola") {
                NavigationLink { SchoolDataView() } label: { Label("Dati della scuola", systemImage: "building.2.fill") }
                NavigationLink { InviteCenterView() } label: { Label("Inviti e codici accesso", systemImage: "qrcode") }
                NavigationLink { RolesPermissionsView() } label: { Label("Ruoli e autorizzazioni", systemImage: "person.badge.key.fill") }
                NavigationLink { BranchesView() } label: { Label("Sedi e sale", systemImage: "map.fill") }
            }

            Section("Preferenze") {
                Picker("Aspetto", selection: $store.appearance) {
                    ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) }
                }
                Toggle(isOn: $notificationsEnabled) { Label("Notifiche", systemImage: "bell.fill") }
            }

            CommonInformationSection(build: "36")
            LogoutSection()
        }
        .modernScreen()
        .navigationTitle("Scuola")
        .sheet(isPresented: $showPlans) { PlansView() }
        .alert("Acquisti ripristinati", isPresented: $showRestoreMessage) { Button("OK", role: .cancel) {} } message: { Text("Nella build demo non ci sono ancora acquisti reali. Il collegamento StoreKit verrà attivato nella fase abbonamenti.") }
    }
}

private struct StaffProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var notificationsEnabled = true

    var body: some View {
        List {
            Section {
                ProfileHeader(
                    title: store.userRole == .teacher ? "Giulia Ferri" : "Elena Rossi",
                    subtitle: store.schoolName,
                    role: store.userRole.rawValue,
                    icon: store.userRole.icon
                )
            }

            Section("Profilo professionale") {
                Label(store.userRole == .teacher ? "Danza classica e propedeutica" : "Segreteria principale", systemImage: "briefcase.fill")
                Label(store.userRole == .teacher ? "3 corsi assegnati" : "Accesso gestione operativa", systemImage: "checkmark.seal.fill")
                NavigationLink { PersonalAvailabilityView() } label: { Label("Disponibilità e sostituzioni", systemImage: "calendar.badge.clock") }
            }

            Section("Account") {
                NavigationLink { EditableProfileView(title: "Dati personali") } label: { Label("Modifica dati personali", systemImage: "person.crop.circle.badge.pencil") }
                NavigationLink { ChangePasswordView() } label: { Label("Cambia password", systemImage: "key.fill") }
                Toggle(isOn: $notificationsEnabled) { Label("Notifiche", systemImage: "bell.fill") }
                Picker("Aspetto", selection: $store.appearance) {
                    ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section {
                Label("Il piano DanzUp è gestito esclusivamente dal proprietario della scuola.", systemImage: "lock.shield.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            CommonInformationSection(build: "36")
            LogoutSection()
        }
        .modernScreen()
        .navigationTitle("Profilo")
    }
}

private struct FamilyProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var notificationsEnabled = true

    var body: some View {
        List {
            Section {
                ProfileHeader(
                    title: store.userRole == .parent ? "Mario Romano" : "Alice Romano",
                    subtitle: store.schoolName,
                    role: store.userRole.rawValue,
                    icon: store.userRole.icon
                )
            }

            if store.userRole == .parent {
                Section("Profili collegati") {
                    let linked = store.linkedChildrenForCurrentParent()
                    if linked.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Nessun figlio collegato")
                                .font(.headline)
                            Text("Invia una richiesta e attendi l’approvazione della scuola.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    } else {
                        ForEach(linked) { child in
                            HStack {
                                Circle().fill(Color.dzPurple.opacity(0.14)).frame(width: 42, height: 42)
                                    .overlay(Text(child.name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()).font(.caption.bold()).foregroundColor(.dzPurple))
                                VStack(alignment: .leading) { Text(child.name).font(.headline); Text("\(child.course) • \(child.age) anni").font(.caption).foregroundColor(.secondary) }
                                Spacer(); Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                    }
                    NavigationLink { LinkChildView() } label: { Label("Collega un altro figlio", systemImage: "person.badge.plus") }
                }
            }

            Section("Account") {
                NavigationLink { EditableProfileView(title: "Dati personali") } label: { Label("Dati personali", systemImage: "person.text.rectangle") }
                NavigationLink { EmergencyContactsView() } label: { Label("Contatti di emergenza", systemImage: "phone.fill") }
                NavigationLink { ChangePasswordView() } label: { Label("Cambia password", systemImage: "key.fill") }
                Toggle(isOn: $notificationsEnabled) { Label("Notifiche", systemImage: "bell.fill") }
                Picker("Aspetto", selection: $store.appearance) {
                    ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section {
                Label("L’accesso per genitori e allievi è gratuito e viene fornito dalla scuola.", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            CommonInformationSection(build: "36")
            LogoutSection()
        }
        .modernScreen()
        .navigationTitle("Profilo")
    }
}

private struct ProfileHeader: View {
    let title: String
    let subtitle: String
    let role: String
    let icon: String

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                BrandGradient().clipShape(RoundedRectangle(cornerRadius: 20))
                Image(systemName: icon).font(.title2.bold()).foregroundColor(.white)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).foregroundColor(.secondary)
                Text(role).font(.caption.bold()).foregroundColor(.dzPurple)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct CommonInformationSection: View {
    let build: String
    var body: some View {
        Section("Informazioni") {
            NavigationLink { DiagnosticsView() } label: { Label("Stabilità e diagnostica", systemImage: "stethoscope") }
            NavigationLink { InfoPageView(title: "Assistenza", text: "Per assistenza su DanzUp contatta la tua scuola oppure il supporto DanzUp. Nella versione definitiva sarà disponibile il modulo di contatto online.", icon: "questionmark.circle.fill") } label: { Label("Assistenza", systemImage: "questionmark.circle.fill") }
            NavigationLink { InfoPageView(title: "Privacy", text: "DanzUp protegge i dati di scuole, insegnanti, famiglie e allievi. La pagina legale definitiva verrà collegata prima della pubblicazione.", icon: "hand.raised.fill") } label: { Label("Privacy", systemImage: "hand.raised.fill") }
            LabeledContent("Versione", value: "1.0 • Build \(build)")
        }
    }
}

private struct LogoutSection: View {
    @EnvironmentObject var store: AppStore
    @State private var confirmLogout = false
    var body: some View {
        Section {
            Button(role: .destructive) { confirmLogout = true } label: { Label("Esci", systemImage: "rectangle.portrait.and.arrow.right") }
        }
        .confirmationDialog("Vuoi uscire da DanzUp?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Esci", role: .destructive) { store.logout() }
            Button("Annulla", role: .cancel) {}
        }
    }
}

struct DiagnosticsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showResetConfirmation = false
    @State private var showSaved = false

    var body: some View {
        List {
            Section("Stato app") {
                Label("Dati locali disponibili", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                LabeledContent("Corsi caricati", value: "\(store.courses.count)")
                LabeledContent("Allievi caricati", value: "\(store.students.count)")
                LabeledContent("Comunicazioni", value: "\(store.announcements.count)")
                if let date = store.lastSavedAt {
                    LabeledContent("Ultimo salvataggio", value: date.formatted(date: .omitted, time: .shortened))
                }
            }
            Section("Manutenzione") {
                Button { store.saveLocalData(); showSaved = true } label: { Label("Salva ora", systemImage: "square.and.arrow.down.fill") }
                if store.userRole == .owner {
                    Button(role: .destructive) { showResetConfirmation = true } label: { Label("Ripristina dati dimostrativi", systemImage: "arrow.counterclockwise") }
                }
            }
            Section {
                Text("Questa build usa salvataggi locali protetti e navigazione semplificata. Quando un blocco si ripete, indica la schermata e l’azione eseguita immediatamente prima.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .modernScreen()
        .navigationTitle("Diagnostica")
        .alert("Dati salvati", isPresented: $showSaved) { Button("OK", role: .cancel) {} }
        .confirmationDialog("Ripristinare tutti i dati demo?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Ripristina", role: .destructive) { store.resetDemoData() }
            Button("Annulla", role: .cancel) {}
        }
    }
}

struct PlansView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Image(systemName: "crown.fill").font(.system(size: 45)).foregroundColor(.dzPurple)
                        Text("Il piano giusto per la scuola").font(.title2.bold())
                        Text("14 giorni gratis, poi rinnovo mensile").foregroundColor(.secondary)
                    }
                    .padding(.vertical)

                    ForEach(SubscriptionPlan.allCases) { plan in
                        Button { store.selectedPlan = plan } label: {
                            VStack(alignment: .leading, spacing: 11) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(plan.rawValue).font(.title3.bold())
                                        Text(plan.subtitle).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(plan.monthlyPrice).font(.headline)
                                }
                                ForEach(plan.features, id: \.self) {
                                    Label($0, systemImage: "checkmark.circle.fill").font(.subheadline).foregroundColor(.primary)
                                }
                            }
                            .padding(18)
                            .background(store.selectedPlan == plan ? Color.dzPurple.opacity(0.12) : Color(uiColor: .secondarySystemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(store.selectedPlan == plan ? Color.dzPurple : Color.clear, lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Continua con \(store.selectedPlan.rawValue)") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                    Text("Pagamento simulato nella build di test.").font(.caption).foregroundColor(.secondary)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Piani DanzUp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } } }
        }
    }
}

private struct SchoolDataView: View {
    @State private var schoolName = "DanzUp Academy"
    @State private var legalName = "DanzUp Academy ASD"
    @State private var taxCode = "12345678901"
    @State private var email = "segreteria@danzupacademy.it"

    var body: some View {
        Form {
            Section("Dati pubblici") {
                TextField("Nome scuola", text: $schoolName)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            Section("Dati legali") {
                TextField("Ragione sociale", text: $legalName)
                TextField("Partita IVA / Codice fiscale", text: $taxCode)
            }
            Section { Button("Salva modifiche") {} }
        }
        .modernScreen()
        .navigationTitle("Dati scuola")
    }
}

private struct RolesPermissionsView: View {
    var body: some View {
        List {
            Section("Proprietario") { PermissionRow(title: "Tutte le funzioni", enabled: true); PermissionRow(title: "Piani e pagamenti DanzUp", enabled: true) }
            Section("Segreteria") { PermissionRow(title: "Corsi, allievi e quote", enabled: true); PermissionRow(title: "Piani e pagamenti DanzUp", enabled: false) }
            Section("Insegnante") { PermissionRow(title: "Corsi assegnati e presenze", enabled: true); PermissionRow(title: "Dati economici della scuola", enabled: false) }
            Section("Genitore / Allievo") { PermissionRow(title: "Visualizzazione dati personali", enabled: true); PermissionRow(title: "Gestione scuola", enabled: false) }
        }
        .modernScreen()
        .navigationTitle("Autorizzazioni")
    }
}

private struct PermissionRow: View {
    let title: String
    let enabled: Bool
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(enabled ? .green : .secondary)
        }
    }
}

private struct BranchesView: View {
    var body: some View {
        List {
            Section("Sede principale") {
                Label("Via della Danza 25, Roma", systemImage: "mappin.circle.fill")
                LabeledContent("Sale", value: "3")
            }
            Section("Sale") {
                Label("Sala Étoile • 22 posti", systemImage: "sparkles")
                Label("Sala Urban • 26 posti", systemImage: "bolt.fill")
                Label("Sala Ritmo • 20 posti", systemImage: "music.note")
            }
            Section { Label("Aggiungi sede o sala", systemImage: "plus.circle.fill") }
        }
        .modernScreen()
        .navigationTitle("Sedi e sale")
    }
}

private struct PersonalAvailabilityView: View {
    var body: some View {
        List {
            Section("Disponibilità settimanale") {
                LabeledContent("Lunedì", value: "16:00 – 21:00")
                LabeledContent("Martedì", value: "17:00 – 20:30")
                LabeledContent("Giovedì", value: "16:00 – 21:00")
            }
            Section("Richieste") {
                Label("Richiedi sostituzione", systemImage: "person.2.badge.gearshape.fill")
                Label("Segnala indisponibilità", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .modernScreen()
        .navigationTitle("Disponibilità")
    }
}


private struct EditableProfileView: View {
    let title: String
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var saved = false
    var body: some View {
        Form {
            Section("Informazioni") { TextField("Nome", text: $name); TextField("Cognome", text: $surname); TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never); TextField("Telefono", text: $phone).keyboardType(.phonePad) }
            Section { Button("Salva modifiche") { saved = true } }
        }.modernScreen().navigationTitle(title).alert("Modifiche salvate", isPresented: $saved) { Button("OK") {} }
    }
}

private struct ChangePasswordView: View {
    @State private var current = ""; @State private var newPassword = ""; @State private var confirm = ""; @State private var message = false
    var body: some View { Form { Section("Sicurezza") { SecureField("Password attuale", text: $current); SecureField("Nuova password", text: $newPassword); SecureField("Conferma nuova password", text: $confirm) }; Section { Button("Aggiorna password") { message = true }.disabled(newPassword.count < 8 || newPassword != confirm) }; Section { Text("La password deve contenere almeno 8 caratteri.").font(.caption).foregroundColor(.secondary) } }.modernScreen().navigationTitle("Cambia password").alert("Password aggiornata", isPresented: $message) { Button("OK") {} } }
}

private struct EmergencyContactsView: View {
    @State private var name = ""; @State private var relation = ""; @State private var phone = ""; @State private var saved = false
    var body: some View { Form { Section("Contatto") { TextField("Nome e cognome", text: $name); TextField("Relazione", text: $relation); TextField("Telefono", text: $phone).keyboardType(.phonePad) }; Section { Button("Salva contatto") { saved = true } } }.modernScreen().navigationTitle("Contatto di emergenza").alert("Contatto salvato", isPresented: $saved) { Button("OK") {} } }
}

private struct LinkChildView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var success = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.dzPurple)
                    Text("Collega tuo figlio in modo sicuro")
                        .font(.headline)
                    Text("Inserisci esclusivamente il codice personale ALU ricevuto dalla scuola. Non verrà mostrato l’elenco degli altri allievi.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Codice personale allievo") {
                TextField("ALU-000000", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                Text("La scuola riceverà una richiesta contenente solo il profilo corrispondente al codice. Dovrà approvarla prima che tu possa vedere i dati del figlio.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Invia richiesta alla scuola") { submit() }
                    .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .modernScreen()
        .navigationTitle("Collega un figlio")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { if success { dismiss() } }
        } message: { Text(alertMessage) }
    }

    private func submit() {
        success = false
        switch store.requestChildLink(code: code) {
        case .success:
            alertTitle = "Richiesta inviata"
            alertMessage = "La scuola deve approvare il collegamento. Dopo l’approvazione vedrai soltanto questo figlio nel tuo profilo."
            success = true
        case .emptyCode:
            alertTitle = "Codice mancante"; alertMessage = "Inserisci il codice personale ALU fornito dalla scuola."
        case .invalidCode:
            alertTitle = "Codice non valido"; alertMessage = "Non esiste alcun allievo associato a questo codice. Controllalo oppure chiedine uno nuovo alla scuola."
        case .alreadyLinked:
            alertTitle = "Già collegato"; alertMessage = "Questo figlio è già collegato al tuo profilo."
        case .alreadyPending:
            alertTitle = "Richiesta già inviata"; alertMessage = "La scuola deve ancora approvare la richiesta precedente."
        default:
            alertTitle = "Operazione non riuscita"; alertMessage = "Controlla il codice e riprova."
        }
        showAlert = true
    }
}

private struct InfoPageView: View {
    let title: String; let text: String; let icon: String
    var body: some View { ScrollView { VStack(spacing: 20) { Image(systemName: icon).font(.system(size: 48)).foregroundColor(.dzPurple); Text(title).font(.largeTitle.bold()); Text(text).foregroundColor(.secondary).multilineTextAlignment(.center) }.padding(30) }.modernScreen().navigationTitle(title).navigationBarTitleDisplayMode(.inline) }
}
