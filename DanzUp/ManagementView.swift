import SwiftUI

struct ManagementView: View {
    private let items: [ManagementItem] = [
        ManagementItem(title: "Presenze", subtitle: "Registro e recuperi", icon: "checkmark.circle.fill", tint: .green, badge: "Oggi 46"),
        ManagementItem(title: "Quote", subtitle: "Pagamenti e scadenze", icon: "eurosign.circle.fill", tint: .orange, badge: "7 scadute"),
        ManagementItem(title: "Certificati", subtitle: "Scadenze mediche", icon: "cross.case.fill", tint: .blue, badge: "4 avvisi"),
        ManagementItem(title: "Comunicazioni", subtitle: "Messaggi mirati", icon: "megaphone.fill", tint: .dzFuchsia, badge: "2 nuove"),
        ManagementItem(title: "Saggi ed eventi", subtitle: "Prove, costumi e presenze", icon: "star.fill", tint: .dzPurple, badge: "1 attivo"),
        ManagementItem(title: "Staff e inviti", subtitle: "Ruoli e codici accesso", icon: "person.2.badge.gearshape.fill", tint: .indigo, badge: "8 membri")
    ]
    var body: some View {
        ZStack { ScreenBackground(); ScrollView { VStack(alignment: .leading, spacing: 18) { SectionTitle("Centro gestione", subtitle: "Tutto ciò che serve alla segreteria"); LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) { ForEach(items) { item in NavigationLink { ManagementDetailView(item: item) } label: { ManagementTile(item: item) }.buttonStyle(.plain) } } }.padding() } }
        .navigationTitle("Gestione")
    }
}

struct ManagementItem: Identifiable { let id = UUID(); let title: String; let subtitle: String; let icon: String; let tint: Color; let badge: String }
private struct ManagementTile: View { let item: ManagementItem; var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: item.icon).font(.title2).foregroundColor(item.tint).frame(width: 46, height: 46).background(item.tint.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 15)); Spacer(); Image(systemName: "arrow.up.right").font(.caption.bold()).foregroundColor(.secondary) }; Text(item.title).font(.headline).foregroundColor(.primary); Text(item.subtitle).font(.caption).foregroundColor(.secondary).lineLimit(2); Text(item.badge).font(.caption2.bold()).foregroundColor(item.tint).padding(.horizontal, 9).padding(.vertical, 5).background(item.tint.opacity(0.10)).clipShape(Capsule()) }.frame(maxWidth: .infinity, minHeight: 165, alignment: .leading).padding(15).background(Color(uiColor: .secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 23)).overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.primary.opacity(0.05))) } }

struct ManagementDetailView: View { let item: ManagementItem; var body: some View { ZStack { ScreenBackground(); ScrollView { VStack(spacing: 16) { DZCard { HStack { Image(systemName: item.icon).font(.largeTitle).foregroundColor(item.tint); VStack(alignment: .leading) { Text(item.title).font(.title2.bold()); Text(item.subtitle).foregroundColor(.secondary) }; Spacer() } }; ForEach(0..<3, id: \.self) { index in DZCard { HStack { Image(systemName: index == 0 ? "chart.bar.fill" : index == 1 ? "clock.fill" : "plus.circle.fill").foregroundColor(item.tint).frame(width: 38, height: 38).background(item.tint.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12)); VStack(alignment: .leading) { Text(index == 0 ? "Riepilogo aggiornato" : index == 1 ? "Attività recenti" : "Aggiungi nuovo elemento").font(.headline); Text("Sezione pronta per il collegamento al database.").font(.caption).foregroundColor(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.secondary) } } } }.padding() } }.navigationTitle(item.title).navigationBarTitleDisplayMode(.inline) } }
