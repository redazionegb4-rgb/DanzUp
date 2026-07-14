import SwiftUI

struct WelcomeView: View {
    @State private var route: AuthRoute?
    var body: some View {
        NavigationStack {
            ZStack {
                BrandGradient().ignoresSafeArea()
                Circle().fill(Color.white.opacity(0.10)).frame(width: 310).offset(x: 160, y: -300)
                ScrollView {
                    VStack(spacing: 26) {
                        Spacer(minLength: 45)
                        LogoMark().frame(width: 104, height: 104)
                        VStack(spacing: 8) {
                            Text("DanzUp").font(.system(size: 46, weight: .black, design: .rounded)).foregroundColor(.white)
                            Text("La tua scuola di danza, finalmente in ordine.").font(.headline).foregroundColor(.white.opacity(0.82)).multilineTextAlignment(.center)
                        }
                        VStack(spacing: 13) {
                            AuthButton(title: "Sono una scuola di ballo", subtitle: "Richiedi verifica o accedi", icon: "building.2.fill") { route = .school }
                            AuthButton(title: "Sono insegnante o segreteria", subtitle: "Entra solo con invito della scuola", icon: "person.2.badge.gearshape.fill") { route = .staff }
                            AuthButton(title: "Sono genitore o allievo", subtitle: "Usa il codice ricevuto dalla scuola", icon: "figure.2.and.child.holdinghands") { route = .family }
                        }
                        Text("Nessun utente esterno può creare liberamente una scuola. Le nuove scuole vengono verificate prima dell’attivazione.")
                            .font(.caption).foregroundColor(.white.opacity(0.72)).multilineTextAlignment(.center).padding(.horizontal)
                    }.padding(20)
                }
            }
            .navigationDestination(item: $route) { route in AuthFlowView(route: route) }
        }
    }
}

enum AuthRoute: String, Identifiable, Hashable { case school, staff, family; var id: String { rawValue } }

private struct AuthButton: View { let title: String; let subtitle: String; let icon: String; let action: () -> Void; var body: some View { Button(action: action) { HStack(spacing: 15) { Image(systemName: icon).font(.title2).frame(width: 46, height: 46).background(Color.white.opacity(0.16)).clipShape(RoundedRectangle(cornerRadius: 15)); VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(subtitle).font(.caption).opacity(0.75) }; Spacer(); Image(systemName: "chevron.right") }.foregroundColor(.white).padding(15).background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.18))) }.buttonStyle(.plain) } }

struct LogoMark: View { var body: some View { ZStack { RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color.white); Image(systemName: "figure.dance").font(.system(size: 48, weight: .semibold)).foregroundColor(.dzPurple); Circle().fill(Color.dzFuchsia).frame(width: 18, height: 18).offset(x: 31, y: -31) }.shadow(color: .black.opacity(0.18), radius: 20, y: 10) } }

struct AuthFlowView: View {
    @EnvironmentObject var store: AppStore
    let route: AuthRoute
    @State private var mode = 0
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var school = ""
    @State private var vat = ""
    @State private var showRequest = false

    var body: some View {
        ZStack { ScreenBackground(); ScrollView { VStack(spacing: 20) { header; if route == .school { Picker("", selection: $mode) { Text("Accedi").tag(0); Text("Richiedi attivazione").tag(1) }.pickerStyle(.segmented); schoolContent } else { inviteContent }; demoSection }.padding() } }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline).alert("Richiesta inviata", isPresented: $showRequest) { Button("OK") {} } message: { Text("La scuola verrà verificata prima di poter creare account e utilizzare DanzUp.") }
    }
    private var title: String { route == .school ? "Accesso scuola" : route == .staff ? "Accesso personale" : "Accesso famiglia" }
    private var header: some View { DZCard { HStack(spacing: 15) { Image(systemName: route == .school ? "building.2.fill" : route == .staff ? "person.2.fill" : "figure.2.and.child.holdinghands").font(.title).foregroundColor(.dzPurple).frame(width: 58, height: 58).background(Color.dzPurple.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 18)); VStack(alignment: .leading, spacing: 4) { Text(title).font(.title3.bold()); Text(route == .school ? "Solo scuole verificate" : "Account creato dalla tua scuola").foregroundColor(.secondary).font(.subheadline) }; Spacer() } } }
    @ViewBuilder private var schoolContent: some View {
        if mode == 0 { DZCard { VStack(spacing: 14) { TextField("Email della scuola", text: $email).textContentType(.emailAddress).textInputAutocapitalization(.never); SecureField("Password", text: $password); Button("Accedi") { store.enterDemo(role: .owner) }.buttonStyle(PrimaryButtonStyle()) } } }
        else { DZCard { VStack(spacing: 14) { TextField("Nome legale della scuola", text: $school); TextField("Partita IVA o Codice Fiscale", text: $vat); TextField("Email istituzionale", text: $email).textInputAutocapitalization(.never); Text("La registrazione non attiva subito l’account: controlliamo i dati della scuola prima di approvarla.").font(.caption).foregroundColor(.secondary); Button("Invia richiesta di verifica") { showRequest = true }.buttonStyle(PrimaryButtonStyle()) } } }
    }
    private var inviteContent: some View { DZCard { VStack(spacing: 14) { TextField("Codice invito (es. DZ-482915)", text: $inviteCode).textInputAutocapitalization(.characters); TextField("Email", text: $email).textInputAutocapitalization(.never); SecureField("Password", text: $password); Text("Il codice viene generato dalla segreteria ed è associato al ruolo corretto: insegnante, genitore o allievo.").font(.caption).foregroundColor(.secondary); Button("Continua") { store.enterDemo(role: route == .staff ? .teacher : .parent) }.buttonStyle(PrimaryButtonStyle()) } } }
    private var demoSection: some View { Button { store.enterDemo(role: route == .school ? .owner : route == .staff ? .teacher : .parent) } label: { Label("Apri accesso demo", systemImage: "sparkles").font(.headline).foregroundColor(.dzPurple).frame(maxWidth: .infinity).padding() }.background(Color.dzPurple.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 18)) }
}

struct PrimaryButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(BrandGradient()).clipShape(RoundedRectangle(cornerRadius: 16)).opacity(configuration.isPressed ? 0.8 : 1) } }
