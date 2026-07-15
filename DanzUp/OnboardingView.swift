import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                BrandGradient().ignoresSafeArea()
                Circle().fill(Color.white.opacity(0.10)).frame(width: 310).offset(x: 160, y: -300)
                ScrollView {
                    VStack(spacing: 26) {
                        Spacer(minLength: 45)
                        AppIconMark(size: 108)
                        VStack(spacing: 8) {
                            Text("DanzUp").font(.system(size: 46, weight: .black, design: .rounded)).foregroundColor(.white)
                            Text("La tua scuola di danza, finalmente in ordine.").font(.headline).foregroundColor(.white.opacity(0.82)).multilineTextAlignment(.center)
                        }
                        VStack(spacing: 13) {
                            NavigationLink(value: AuthRoute.login) {
                                AuthButtonLabel(title: "Accedi", subtitle: "Per tutti gli account già attivati", icon: "person.crop.circle.fill")
                            }
                            NavigationLink(value: AuthRoute.activation) {
                                AuthButtonLabel(title: "Prima registrazione", subtitle: "Usa una sola volta il codice della scuola", icon: "key.fill")
                            }
                            NavigationLink(value: AuthRoute.schoolRequest) {
                                AuthButtonLabel(title: "Registra una scuola di ballo", subtitle: "Richiedi la verifica come proprietario", icon: "building.2.fill")
                            }
                        }
                        Text("Dopo la prima attivazione non servirà più il codice: entrerai normalmente con email e password.")
                            .font(.caption).foregroundColor(.white.opacity(0.75)).multilineTextAlignment(.center).padding(.horizontal)
                    }.padding(20)
                }
            }
            .navigationDestination(for: AuthRoute.self) { route in AuthFlowView(route: route) }
        }
    }
}

enum AuthRoute: String, Identifiable, Hashable { case login, activation, schoolRequest; var id: String { rawValue } }

private struct AuthButtonLabel: View {
    let title: String; let subtitle: String; let icon: String
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).font(.title2).frame(width: 46, height: 46).background(Color.white.opacity(0.16)).clipShape(RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(subtitle).font(.caption).opacity(0.75) }
            Spacer(); Image(systemName: "chevron.right")
        }.foregroundColor(.white).padding(15).background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.18)))
    }
}

struct AppIconMark: View {
    var size: CGFloat = 104
    var body: some View {
        Image("DanzUpLogo")
            .resizable().scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
            .shadow(color: .black.opacity(0.20), radius: size * 0.16, y: size * 0.08)
    }
}

struct LogoMark: View { var body: some View { AppIconMark() } }

struct AuthFlowView: View {
    @EnvironmentObject var store: AppStore
    let route: AuthRoute
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var fullName = ""
    @State private var school = ""
    @State private var vat = ""
    @State private var selectedRole: UserRole = .parent
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    switch route {
                    case .login: loginContent
                    case .activation: activationContent
                    case .schoolRequest: schoolRequestContent
                    }
                    demoSection
                }.padding()
            }
        }
        .modernScreen()
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) { Button("OK") {} } message: { Text(alertMessage) }
    }

    private var title: String {
        switch route { case .login: return "Accedi"; case .activation: return "Prima registrazione"; case .schoolRequest: return "Registra scuola" }
    }

    private var header: some View {
        DZCard {
            HStack(spacing: 15) {
                AppIconMark(size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3.bold())
                    Text(route == .activation ? "Il codice serve soltanto ora" : route == .login ? "Email e password" : "Solo scuole di ballo")
                        .foregroundColor(.secondary).font(.subheadline)
                }
                Spacer()
            }
        }
    }

    private var loginContent: some View {
        DZCard {
            VStack(spacing: 14) {
                TextField("Email", text: $email).textContentType(.emailAddress).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                SecureField("Password", text: $password).textContentType(.password)
                Button("Accedi") { login() }.buttonStyle(PrimaryButtonStyle())
                Text("Scuola, segreteria, insegnanti, genitori e allievi usano tutti questo accesso dopo l’attivazione iniziale.")
                    .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
        }
    }

    private var activationContent: some View {
        DZCard {
            VStack(spacing: 14) {
                Picker("Ruolo", selection: $selectedRole) {
                    ForEach([UserRole.secretary, .teacher, .parent, .student]) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu)
                TextField("Nome e cognome", text: $fullName).textContentType(.name)
                TextField("Codice ricevuto dalla scuola", text: $inviteCode).textInputAutocapitalization(.characters).autocorrectionDisabled()
                TextField("Email", text: $email).textContentType(.emailAddress).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                SecureField("Crea password", text: $password).textContentType(.newPassword)
                Button("Attiva account") { activate() }.buttonStyle(PrimaryButtonStyle())
                Text("Dopo l’attivazione il codice viene consumato. Le volte successive userai soltanto Accedi.")
                    .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
        }
    }

    private var schoolRequestContent: some View {
        DZCard {
            VStack(spacing: 14) {
                TextField("Nome legale della scuola", text: $school)
                TextField("Partita IVA o Codice Fiscale", text: $vat)
                TextField("Email istituzionale", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                SecureField("Crea password", text: $password).textContentType(.newPassword)
                Text("La richiesta deve essere verificata prima dell’attivazione del profilo proprietario.").font(.caption).foregroundColor(.secondary)
                Button("Invia richiesta di verifica") {
                    guard !school.trimmingCharacters(in: .whitespaces).isEmpty, !vat.trimmingCharacters(in: .whitespaces).isEmpty, email.contains("@"), password.count >= 6 else {
                        show("Dati incompleti", "Inserisci tutti i dati e una password di almeno 6 caratteri."); return
                    }
                    show("Richiesta inviata", "La scuola verrà verificata prima dell’attivazione. In questa build demo l’invio è simulato.")
                }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func login() {
        switch store.login(email: email, password: password) {
        case .success: break
        case .emptyFields: show("Dati mancanti", "Inserisci email e password.")
        case .invalidCredentials: show("Accesso non riuscito", "Email o password non corretti. Se è il primo accesso, usa Prima registrazione.")
        case .inactiveAccount: show("Account bloccato", "La scuola ha disattivato questo account.")
        }
    }

    private func activate() {
        guard password.count >= 6 else { show("Password non valida", "Usa almeno 6 caratteri."); return }
        let result = store.useInvite(code: inviteCode, email: email, name: fullName, selectedRole: selectedRole, password: password)
        switch result {
        case .success: break
        case .emptyFields: show("Dati mancanti", "Compila nome, codice ed email.")
        case .invalidCode: show("Codice non valido", "Il codice non esiste o non corrisponde all’email prevista.")
        case .inactiveCode: show("Codice disattivato", "Chiedi un nuovo codice alla scuola.")
        case .exhaustedCode: show("Codice esaurito", "Il codice ha raggiunto il limite di utilizzi.")
        case .incompatibleRole(let expected): show("Ruolo non corretto", "Questo codice è riservato a: \(expected.rawValue).")
        case .emailAlreadyRegistered: show("Account già esistente", "Questa email è già registrata. Torna indietro e usa Accedi.")
        }
    }

    private func show(_ title: String, _ message: String) { alertTitle = title; alertMessage = message; showAlert = true }

    private var demoSection: some View {
        DZCard {
            VStack(spacing: 10) {
                Text("Accessi demo").font(.headline)
                Button("Demo scuola") { store.enterDemo(role: .owner) }
                Button("Demo insegnante") { store.enterDemo(role: .teacher) }
                Button("Demo genitore") { store.enterDemo(role: .parent) }
            }.buttonStyle(.bordered).frame(maxWidth: .infinity)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(BrandGradient()).clipShape(RoundedRectangle(cornerRadius: 16)).opacity(configuration.isPressed ? 0.8 : 1)
    }
}
