import SwiftUI

struct ManagementView: View {
    let items = [
        ("Presenze", "checkmark.circle.fill", "Registro giornaliero", Color.green),
        ("Pagamenti", "creditcard.fill", "Quote e scadenze", Color.orange),
        ("Certificati", "doc.text.fill", "Documenti medici", Color.blue),
        ("Comunicazioni", "megaphone.fill", "Avvisi alla scuola", Color.dzPink),
        ("Eventi e saggi", "star.fill", "Prove e spettacoli", Color.dzPurple),
        ("Insegnanti", "person.2.fill", "Staff e permessi", Color.indigo)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(items, id: \.0) { item in
                    NavigationLink {
                        GenericManagementList(title: item.0, icon: item.1)
                    } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: item.1)
                                .font(.title2)
                                .foregroundStyle(item.3)
                                .frame(width: 48, height: 48)
                                .background(item.3.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            Text(item.0).font(.headline).foregroundStyle(.primary)
                            Text(item.2).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 145, alignment: .leading)
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Gestione")
    }
}

struct GenericManagementList: View {
    let title: String
    let icon: String
    var body: some View {
        List {
            Section {
                Label("Riepilogo \(title.lowercased())", systemImage: icon)
                Label("Aggiungi nuovo elemento", systemImage: "plus.circle.fill")
                Label("Filtri e ricerca", systemImage: "line.3.horizontal.decrease.circle")
            }
            Section("Demo") {
                Text("Questa sezione è già predisposta nella prima build e verrà collegata al database online nella fase successiva.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
    }
}
