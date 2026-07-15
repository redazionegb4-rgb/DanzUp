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
    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeroCard(title: store.schoolName, subtitle: "Buongiorno, \(store.ownerName)", badge: "Piano \(store.selectedPlan.rawValue) • \(store.trialDaysRemaining) giorni gratis", icon: "building.2.fill")
                    HStack(spacing: 10) {
                        NavigationLink { StudentsView() } label: { MetricCard(value: "\(store.students.count)", label: "Allievi", icon: "person.3.fill") }
                        NavigationLink { CoursesView() } label: { MetricCard(value: "\(store.courses.count)", label: "Corsi", icon: "figure.dance") }
                        NavigationLink { OwnerAttendanceView() } label: { MetricCard(value: "91%", label: "Presenze", icon: "checkmark.circle.fill") }
                    }.buttonStyle(.plain)

                    SectionTitle("Oggi", subtitle: "Tocca una lezione per aprire il registro")
                    NavigationLink { OwnerAttendanceView() } label: { TodayCard() }.buttonStyle(.plain)

                    SectionTitle("Da controllare", subtitle: "Apri direttamente le attività urgenti")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        NavigationLink { PaymentsManagementView(initialFilter: "Scadute") } label: { AlertCard(value: "\(store.overduePaymentsCount)", label: "Quote scadute", icon: "eurosign.circle.fill", tint: .red) }
                        NavigationLink { MedicalCertificatesView(showOnlyAlerts: true) } label: { AlertCard(value: "\(store.medicalAlertsCount)", label: "Certificati", icon: "cross.case.fill", tint: .orange) }
                        NavigationLink { CommunicationsManagementView() } label: { AlertCard(value: "\(store.announcements.count)", label: "Comunicazioni", icon: "megaphone.fill", tint: .dzFuchsia) }
                        NavigationLink { InviteCenterView() } label: { AlertCard(value: "3", label: "Inviti in attesa", icon: "person.crop.circle.badge.plus", tint: .blue) }
                    }.buttonStyle(.plain)

                    SectionTitle("Azioni rapide")
                    DZCard {
                        VStack(spacing: 0) {
                            NavigationLink { PaymentsManagementView(initialFilter: "Da pagare") } label: { QuickActionRow(title: "Registra un pagamento", icon: "eurosign.circle.fill", tint: .green) }
                            Divider().padding(.leading, 46)
                            NavigationLink { CommunicationsManagementView(openComposerOnAppear: true) } label: { QuickActionRow(title: "Pubblica una comunicazione", icon: "megaphone.fill", tint: .dzFuchsia) }
                            Divider().padding(.leading, 46)
                            NavigationLink { InviteCenterView() } label: { QuickActionRow(title: "Genera un codice invito", icon: "qrcode", tint: .dzPurple) }
                        }
                    }.buttonStyle(.plain)
                }.padding()
            }
        }
    }
}

private struct StaffDashboard: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ZStack { ScreenBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroCard(title: store.userRole.rawValue, subtitle: "La tua giornata in DanzUp", badge: store.schoolName, icon: store.userRole.icon)
                SectionTitle("Prossima lezione")
                NavigationLink { AttendanceRegisterView() } label: { DZCard { VStack(alignment: .leading, spacing: 10) { Text("Hip Hop Teen").font(.title2.bold()).foregroundColor(.primary); Label("18:30 • Sala Urban", systemImage: "clock.fill"); Label("24 allievi iscritti", systemImage: "person.3.fill"); Label("Apri registro presenze", systemImage: "arrow.right.circle.fill").font(.headline).foregroundColor(.dzPurple) }.frame(maxWidth: .infinity, alignment: .leading) } }.buttonStyle(.plain)
                HStack(spacing: 10) {
                    NavigationLink { StaffCoursesView() } label: { MetricCard(value: "3", label: "Lezioni", icon: "calendar") }
                    NavigationLink { AttendanceRegisterView() } label: { MetricCard(value: "46", label: "Allievi oggi", icon: "person.2.fill") }
                    NavigationLink { StaffMessagesView() } label: { MetricCard(value: "\(store.announcements.count)", label: "Messaggi", icon: "bubble.left.fill") }
                }.buttonStyle(.plain)
                SectionTitle("Comunicazioni")
                NavigationLink { StaffMessagesView() } label: { DZCard { Label(store.announcements.first?.title ?? "Nessun avviso", systemImage: "megaphone.fill").font(.headline).foregroundColor(.primary) } }.buttonStyle(.plain)
            }.padding()
        }}
    }
}

private struct FamilyDashboard: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ZStack { ScreenBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroCard(title: store.userRole == .parent ? "La tua famiglia" : "Ciao, Alice", subtitle: store.schoolName, badge: store.userRole == .parent ? "Profilo genitore" : "Profilo allievo", icon: store.userRole.icon)
                if store.userRole == .parent {
                    let linkedChildren = store.linkedChildrenForCurrentParent()
                    DZCard {
                        HStack {
                            Image(systemName: "person.2.fill").foregroundColor(.dzPurple)
                            VStack(alignment: .leading) {
                                if let child = linkedChildren.first {
                                    Text(child.name).font(.headline)
                                    let courseCount = store.coursesForStudent(child.id).count
                                    Text(courseCount == 1 ? "1 corso • Profilo selezionato" : "\(courseCount) corsi • Profilo selezionato")
                                        .font(.caption).foregroundColor(.secondary)
                                } else {
                                    Text("Nessun figlio collegato").font(.headline)
                                    Text("Collega un figlio dal Profilo")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(.secondary)
                        }
                    }
                }
                SectionTitle("Prossima lezione")
                NavigationLink { FamilyCalendarView() } label: { DZCard { HStack(spacing: 14) { VStack { Text("MAR").font(.caption.bold()).foregroundColor(.dzPurple); Text("14").font(.largeTitle.bold()).foregroundColor(.primary) }.frame(width: 58); VStack(alignment: .leading, spacing: 5) { Text("Danza Classica").font(.title3.bold()).foregroundColor(.primary); Text("17:00 – Sala Étoile").foregroundColor(.secondary); Text("Giulia Ferri").font(.caption.bold()).foregroundColor(.dzPurple) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.secondary) } } }.buttonStyle(.plain)
                HStack(spacing: 10) {
                    NavigationLink { FamilyAttendanceView() } label: { MetricCard(value: "96%", label: "Presenze", icon: "checkmark.circle.fill") }
                    NavigationLink { FamilyPaymentsView() } label: { MetricCard(value: "0", label: "Quote aperte", icon: "eurosign.circle.fill") }
                    NavigationLink { FamilyMedicalView() } label: { MetricCard(value: "Valido", label: "Certificato", icon: "cross.case.fill") }
                }.buttonStyle(.plain)
                SectionTitle("Avvisi della scuola")
                NavigationLink { StaffMessagesView() } label: { DZCard { VStack(alignment: .leading, spacing: 6) { Text(store.announcements.first?.title ?? "Nessun avviso").font(.headline).foregroundColor(.primary); Text(store.announcements.first?.body ?? "").font(.subheadline).foregroundColor(.secondary) } } }.buttonStyle(.plain)
            }.padding()
        }}
    }
}

private struct QuickActionRow: View { let title: String; let icon: String; let tint: Color; var body: some View { HStack(spacing: 12) { Image(systemName: icon).foregroundColor(tint).frame(width: 34, height: 34).background(tint.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10)); Text(title).font(.headline).foregroundColor(.primary); Spacer(); Image(systemName: "chevron.right").foregroundColor(.secondary) }.padding(.vertical, 10) } }
private struct HeroCard: View { let title: String; let subtitle: String; let badge: String; let icon: String; var body: some View { ZStack(alignment: .bottomLeading) { BrandGradient(); Circle().fill(Color.white.opacity(0.12)).frame(width: 170).offset(x: 120, y: -55); VStack(alignment: .leading, spacing: 8) { HStack { Image(systemName: icon); Text(title).font(.title2.bold()); Spacer() }; Text(subtitle).font(.headline).opacity(0.85); Text(badge).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6).background(Color.white.opacity(0.16)).clipShape(Capsule()) }.foregroundColor(.white).padding(20) }.frame(height: 175).clipShape(RoundedRectangle(cornerRadius: 28)) } }
private struct MetricCard: View { let value: String; let label: String; let icon: String; var body: some View { VStack(spacing: 7) { Image(systemName: icon).foregroundColor(.dzPurple); Text(value).font(.title3.bold()).foregroundColor(.primary); Text(label).font(.caption).foregroundColor(.secondary).lineLimit(1) }.frame(maxWidth: .infinity).padding(.vertical, 15).background(Color(uiColor: .secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 19)) } }
private struct AlertCard: View { let value: String; let label: String; let icon: String; let tint: Color; var body: some View { HStack { Image(systemName: icon).foregroundColor(tint).font(.title2); VStack(alignment: .leading) { Text(value).font(.title2.bold()).foregroundColor(.primary); Text(label).font(.caption).foregroundColor(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundColor(.secondary) }.padding(15).frame(maxWidth: .infinity, minHeight: 82).background(tint.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius: 20)) } }
private struct TodayCard: View { var body: some View { DZCard { VStack(spacing: 14) { Label("16:30  Propedeutica • Sala Étoile", systemImage: "sparkles"); Divider(); Label("18:30  Hip Hop Teen • Sala Urban", systemImage: "bolt.fill"); Divider(); Label("20:00  Latino Avanzato • Sala Ritmo", systemImage: "music.note") }.foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading) } } }
