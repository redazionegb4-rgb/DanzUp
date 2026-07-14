import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showPlans = false
    var body: some View {
        List {
            Section { HStack(spacing: 15) { LogoMark().frame(width: 64, height: 64); VStack(alignment: .leading, spacing: 4) { Text(store.schoolName).font(.headline); Text(store.ownerName).foregroundColor(.secondary); Label(store.userRole.rawValue, systemImage: store.userRole.icon).font(.caption.bold()).foregroundColor(.dzPurple) } }.padding(.vertical, 6) }
            Section("Abbonamento") { Button { showPlans = true } label: { HStack { Label("Piano \(store.selectedPlan.rawValue)", systemImage: "crown.fill"); Spacer(); Text("\(store.trialDaysRemaining) giorni gratis").font(.caption).foregroundColor(.secondary) } }; Label("Ripristina acquisti", systemImage: "arrow.clockwise") }
            Section("Scuola e accessi") { Label("Dati della scuola", systemImage: "building.2.fill"); Label("Genera codice invito", systemImage: "qrcode"); Label("Ruoli e autorizzazioni", systemImage: "person.badge.key.fill") }
            Section("Preferenze") { Picker("Aspetto", selection: $store.appearance) { ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) } }; Label("Notifiche", systemImage: "bell.fill") }
            Section("Informazioni") { Label("Assistenza", systemImage: "questionmark.circle.fill"); Label("Privacy", systemImage: "hand.raised.fill"); LabeledContent("Versione", value: "1.0 • Build 8") }
            Section { Button(role: .destructive) { store.logout() } label: { Label("Esci", systemImage: "rectangle.portrait.and.arrow.right") } }
        }.navigationTitle("Profilo").sheet(isPresented: $showPlans) { PlansView() }
    }
}

struct PlansView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    var body: some View { NavigationStack { ScrollView { VStack(spacing: 16) { VStack(spacing: 6) { Image(systemName: "crown.fill").font(.system(size: 45)).foregroundColor(.dzPurple); Text("Il piano giusto per la scuola").font(.title2.bold()); Text("14 giorni gratis, poi rinnovo mensile").foregroundColor(.secondary) }.padding(.vertical); ForEach(SubscriptionPlan.allCases) { plan in Button { store.selectedPlan = plan } label: { VStack(alignment: .leading, spacing: 11) { HStack { VStack(alignment: .leading) { Text(plan.rawValue).font(.title3.bold()); Text(plan.subtitle).font(.caption).foregroundColor(.secondary) }; Spacer(); Text(plan.monthlyPrice).font(.headline) }; ForEach(plan.features, id: \.self) { Label($0, systemImage: "checkmark.circle.fill").font(.subheadline).foregroundColor(.primary) } }.padding(18).background(store.selectedPlan == plan ? Color.dzPurple.opacity(0.12) : Color(uiColor: .secondarySystemBackground)).overlay(RoundedRectangle(cornerRadius: 22).stroke(store.selectedPlan == plan ? Color.dzPurple : Color.clear, lineWidth: 2)).clipShape(RoundedRectangle(cornerRadius: 22)) }.buttonStyle(.plain) }; Button("Continua con \(store.selectedPlan.rawValue)") {}.buttonStyle(PrimaryButtonStyle()); Text("Pagamento simulato nella build di test.").font(.caption).foregroundColor(.secondary) }.padding() } .background(Color(uiColor: .systemGroupedBackground)).navigationTitle("Piani DanzUp").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } } } } }
}
