import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var page = 0
    @State private var school = ""
    @State private var owner = ""
    @State private var email = ""
    @State private var password = ""
    @State private var floating = false

    var body: some View {
        ZStack {
            BrandGradient().ignoresSafeArea()
            Circle().fill(.white.opacity(0.12)).frame(width: 290).blur(radius: 2).offset(x: 150, y: -330)
            Circle().fill(.white.opacity(0.08)).frame(width: 230).offset(x: -170, y: 340)

            VStack(spacing: 22) {
                Spacer(minLength: 30)
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 112, height: 112)
                    Image(systemName: "figure.dance")
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(.white)
                }
                .offset(y: floating ? -6 : 6)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: floating)

                Text("DanzUp")
                    .font(.system(size: 43, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(page == 0 ? "La tua scuola di ballo, finalmente in ordine." : "Crea la tua scuola")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal)

                if page == 0 {
                    VStack(spacing: 12) {
                        FeatureRow(icon: "calendar.badge.clock", title: "Corsi e calendario")
                        FeatureRow(icon: "person.3.fill", title: "Allievi e presenze")
                        FeatureRow(icon: "creditcard.fill", title: "Quote e scadenze")
                        FeatureRow(icon: "megaphone.fill", title: "Comunicazioni e saggi")
                    }
                    .padding(.horizontal, 28)
                } else {
                    VStack(spacing: 13) {
                        DZTextField(title: "Nome scuola", icon: "building.2.fill", text: $school)
                        DZTextField(title: "Nome proprietario", icon: "person.fill", text: $owner)
                        DZTextField(title: "Email", icon: "envelope.fill", text: $email, keyboard: .emailAddress)
                        DZSecureField(title: "Password", icon: "lock.fill", text: $password)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    if page == 0 {
                        withAnimation { page = 1 }
                    } else {
                        store.completeOnboarding(school: school, owner: owner)
                    }
                } label: {
                    HStack {
                        Text(page == 0 ? "Inizia ora" : "Avvia prova gratuita")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(Color.dzIndigo)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
                }
                .padding(.horizontal, 24)

                if page == 1 {
                    Text("14 giorni gratis • Nessun addebito in questa build demo")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                } else {
                    Button("Hai già un account? Accedi") { withAnimation { page = 1 } }
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.subheadline.weight(.semibold))
                }
                Spacer(minLength: 24)
            }
        }
        .onAppear { floating = true }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).frame(width: 24).font(.headline)
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
        }
        .foregroundStyle(.white)
        .padding(15)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct DZTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.white.opacity(0.8)).frame(width: 25)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct DZSecureField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.white.opacity(0.8)).frame(width: 25)
            SecureField(title, text: $text).foregroundStyle(.white)
        }
        .padding(16)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}
