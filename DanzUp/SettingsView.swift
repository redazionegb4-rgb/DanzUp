import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showPlans = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 15) {
                    ZStack {
                        BrandGradient()
                        Image(systemName: "figure.dance").foregroundStyle(.white).font(.title)
                    }
                    .frame(width: 62, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                    VStack(alignment: .leading) {
                        Text(store.schoolName).font(.headline)
                        Text(store.ownerName).foregroundStyle(.secondary)
                        Text("Proprietario").font(.caption.bold()).foregroundStyle(Color.dzPurple)
                    }
                }
                .padding(.vertical, 5)
            }

            Section("Abbonamento") {
                Button { showPlans = true } label: {
                    HStack {
                        Label("Prova Premium", systemImage: "crown.fill")
                        Spacer()
                        Text("\(store.trialDaysRemaining) giorni rimasti").foregroundStyle(.secondary)
                    }
                }
                Label("Ripristina acquisti", systemImage: "arrow.clockwise")
            }

            Section("Preferenze") {
                Picker("Aspetto", selection: $store.appearance) {
                    ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) }
                }
                Label("Notifiche", systemImage: "bell.fill")
                Label("Dati della scuola", systemImage: "building.2.fill")
            }

            Section("Assistenza") {
                Label("Centro assistenza", systemImage: "questionmark.circle.fill")
                Label("Privacy", systemImage: "hand.raised.fill")
                LabeledContent("Versione", value: "1.0 • Build 1")
            }

            Section {
                Button(role: .destructive) { store.resetDemo() } label: {
                    Label("Esci dalla demo", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profilo")
        .sheet(isPresented: $showPlans) { PlansView() }
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
                        Image(systemName: "crown.fill").font(.system(size: 46)).foregroundStyle(Color.dzPurple)
                        Text("Scegli il piano DanzUp").font(.title2.bold())
                        Text("14 giorni gratis, poi rinnovo mensile").foregroundStyle(.secondary)
                    }
                    .padding(.vertical)

                    ForEach(SubscriptionPlan.allCases) { plan in
                        Button {
                            store.selectedPlan = plan
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(plan.rawValue).font(.title3.bold())
                                        Text(plan.subtitle).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(plan.monthlyPrice).font(.headline)
                                        Text("al mese").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                ForEach(plan.features, id: \.self) { feature in
                                    Label(feature, systemImage: "checkmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(18)
                            .background(store.selectedPlan == plan ? Color.dzPurple.opacity(0.12) : Color(uiColor: .secondarySystemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(store.selectedPlan == plan ? Color.dzPurple : Color.clear, lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Continua con \(store.selectedPlan.rawValue)") {}
                        .buttonStyle(.borderedProminent)
                        .tint(Color.dzPurple)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    Text("In questa prima build il pagamento è simulato e non parte alcun addebito.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } } }
        }
    }
}
