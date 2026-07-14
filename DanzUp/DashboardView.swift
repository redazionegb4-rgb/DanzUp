import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Group {
            switch store.userRole {
            case .owner: SchoolDashboard()
            case .secretary, .teacher: StaffDashboard()
            case .parent, .student: FamilyDashboard()
            }
        }
        .navigationTitle("DanzUp")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SchoolDashboard: View {
    @EnvironmentObject var store: AppStore
    var body: some View { ZStack { ScreenBackground(); ScrollView { VStack(alignment: .leading, spacing: 20) { HeroCard(title: store.schoolName, subtitle: "Buongiorno, \(store.ownerName)", badge: "Piano \(store.selectedPlan.rawValue) • \(store.trialDaysRemaining) giorni gratis", icon: "building.2.fill"); HStack(spacing: 10) { MetricCard(value: "128", label: "Allievi", icon: "person.3.fill"); MetricCard(value: "12", label: "Corsi", icon: "figure.dance"); MetricCard(value: "91%", label: "Presenze", icon: "checkmark.circle.fill") }; SectionTitle("Oggi", subtitle: "Attività della scuola"); TodayCard(); SectionTitle("Da controllare"); HStack(spacing: 10) { AlertCard(value: "7", label: "Quote scadute", icon: "eurosign.circle.fill", tint: .red); AlertCard(value: "4", label: "Certificati", icon: "cross.case.fill", tint: .orange) } }.padding() } } }
}

private struct StaffDashboard: View {
    @EnvironmentObject var store: AppStore
    var body: some View { ZStack { ScreenBackground(); ScrollView { VStack(alignment: .leading, spacing: 20) { HeroCard(title: store.userRole.rawValue, subtitle: "La tua giornata in DanzUp", badge: store.schoolName, icon: store.userRole.icon); SectionTitle("Prossima lezione"); DZCard { VStack(alignment: .leading, spacing: 10) { Text("Hip Hop Teen").font(.title2.bold()); Label("18:30 • Sala Urban", systemImage: "clock.fill"); Label("24 allievi iscritti", systemImage: "person.3.fill"); Button("Apri registro presenze") {}.buttonStyle(PrimaryButtonStyle()) }.frame(maxWidth: .infinity, alignment: .leading) }; HStack(spacing: 10) { MetricCard(value: "3", label: "Lezioni", icon: "calendar"); MetricCard(value: "46", label: "Allievi oggi", icon: "person.2.fill"); MetricCard(value: "2", label: "Messaggi", icon: "bubble.left.fill") }; SectionTitle("Comunicazioni"); DZCard { Label("Prove saggio sabato alle 15:00", systemImage: "megaphone.fill").font(.headline) } }.padding() } } }
}

private struct FamilyDashboard: View {
    @EnvironmentObject var store: AppStore
    var body: some View { ZStack { ScreenBackground(); ScrollView { VStack(alignment: .leading, spacing: 20) { HeroCard(title: store.userRole == .parent ? "La tua famiglia" : "Ciao, Alice", subtitle: store.schoolName, badge: "Tutto in regola", icon: store.userRole.icon); SectionTitle("Prossima lezione"); DZCard { HStack(spacing: 14) { VStack { Text("MAR").font(.caption.bold()).foregroundColor(.dzPurple); Text("14").font(.largeTitle.bold()) }.frame(width: 58); VStack(alignment: .leading, spacing: 5) { Text("Danza Classica").font(.title3.bold()); Text("17:00 – Sala Étoile").foregroundColor(.secondary); Text("Giulia Ferri").font(.caption.bold()).foregroundColor(.dzPurple) }; Spacer() } }; HStack(spacing: 10) { MetricCard(value: "96%", label: "Presenze", icon: "checkmark.circle.fill"); MetricCard(value: "0", label: "Quote aperte", icon: "eurosign.circle.fill"); MetricCard(value: "Valido", label: "Certificato", icon: "cross.case.fill") }; SectionTitle("Avvisi della scuola"); DZCard { VStack(alignment: .leading, spacing: 6) { Text("Prove saggio estivo").font(.headline); Text("Sabato alle 15:00. Presentarsi 20 minuti prima.").font(.subheadline).foregroundColor(.secondary) } } }.padding() } } }
}

private struct HeroCard: View { let title: String; let subtitle: String; let badge: String; let icon: String; var body: some View { ZStack(alignment: .bottomLeading) { BrandGradient(); Circle().fill(Color.white.opacity(0.12)).frame(width: 170).offset(x: 120, y: -55); VStack(alignment: .leading, spacing: 8) { HStack { Image(systemName: icon); Text(title).font(.title2.bold()); Spacer() }; Text(subtitle).font(.headline).opacity(0.85); Text(badge).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6).background(Color.white.opacity(0.16)).clipShape(Capsule()) }.foregroundColor(.white).padding(20) }.frame(height: 175).clipShape(RoundedRectangle(cornerRadius: 28)) } }
private struct MetricCard: View { let value: String; let label: String; let icon: String; var body: some View { VStack(spacing: 7) { Image(systemName: icon).foregroundColor(.dzPurple); Text(value).font(.title3.bold()); Text(label).font(.caption).foregroundColor(.secondary).lineLimit(1) }.frame(maxWidth: .infinity).padding(.vertical, 15).background(Color(uiColor: .secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 19)) } }
private struct AlertCard: View { let value: String; let label: String; let icon: String; let tint: Color; var body: some View { HStack { Image(systemName: icon).foregroundColor(tint).font(.title2); VStack(alignment: .leading) { Text(value).font(.title2.bold()); Text(label).font(.caption).foregroundColor(.secondary) }; Spacer() }.padding(15).frame(maxWidth: .infinity).background(tint.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius: 20)) } }
private struct TodayCard: View { var body: some View { DZCard { VStack(spacing: 14) { Label("16:30  Propedeutica • Sala Étoile", systemImage: "sparkles"); Divider(); Label("18:30  Hip Hop Teen • Sala Urban", systemImage: "bolt.fill"); Divider(); Label("20:00  Latino Avanzato • Sala Ritmo", systemImage: "music.note") }.frame(maxWidth: .infinity, alignment: .leading) } } }
