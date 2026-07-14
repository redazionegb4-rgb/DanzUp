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
                Label("Gestisci o cambia piano", systemImage: "creditcard.fill")
                Label("Ripristina acquisti", systemImage: "arrow.clockwise")
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

            CommonInformationSection(build: "11")
            LogoutSection()
        }
        .navigationTitle("Scuola")
        .sheet(isPresented: $showPlans) { PlansView() }
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
                Label("Modifica dati personali", systemImage: "person.crop.circle.badge.pencil")
                Label("Cambia password", systemImage: "key.fill")
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

            CommonInformationSection(build: "11")
            LogoutSection()
        }
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
                    HStack {
                        Circle().fill(Color.dzPurple.opacity(0.14)).frame(width: 42, height: 42)
                            .overlay(Text("AR").font(.caption.bold()).foregroundColor(.dzPurple))
                        VStack(alignment: .leading) {
                            Text("Alice Romano").font(.headline)
                            Text("Danza Classica • 14 anni").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    Label("Collega un altro figlio", systemImage: "person.badge.plus")
                }
            }

            Section("Account") {
                Label("Dati personali", systemImage: "person.text.rectangle")
                Label("Contatti di emergenza", systemImage: "phone.fill")
                Label("Cambia password", systemImage: "key.fill")
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

            CommonInformationSection(build: "11")
            LogoutSection()
        }
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
            Label("Assistenza", systemImage: "questionmark.circle.fill")
            Label("Privacy", systemImage: "hand.raised.fill")
            LabeledContent("Versione", value: "1.0 • Build \(build)")
        }
    }
}

private struct LogoutSection: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Section {
            Button(role: .destructive) { store.logout() } label: {
                Label("Esci", systemImage: "rectangle.portrait.and.arrow.right")
            }
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
        .navigationTitle("Disponibilità")
    }
}
