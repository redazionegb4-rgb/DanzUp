import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            switch store.userRole {
            case .owner:
                SchoolDashboard()
            case .secretary, .teacher:
                StaffDashboard()
            case .parent, .student:
                FamilyDashboard()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 9) {
                    AppIconMark(size: 31)
                    Text("DanzUp")
                        .font(.headline.weight(.bold))
                }
            }
        }
    }
}

// MARK: - School home

private struct SchoolDashboard: View {
    @EnvironmentObject var store: AppStore

    private var todayText: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        ZStack {
            ModernDashboardBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ModernWelcomeHeader(
                        eyebrow: todayText.capitalized,
                        title: "Buongiorno, \(store.ownerName)",
                        subtitle: store.schoolName,
                        badge: "\(store.selectedPlan.rawValue) • \(store.trialDaysRemaining) giorni di prova"
                    )

                    SchoolOverviewGrid()

                    VStack(alignment: .leading, spacing: 12) {
                        ModernSectionHeader(
                            title: "La giornata",
                            subtitle: "Lezioni e attività previste oggi",
                            actionTitle: "Registro"
                        )
                        NavigationLink { OwnerAttendanceView() } label: {
                            ModernTodaySchedule()
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ModernSectionHeader(
                            title: "Da controllare",
                            subtitle: "Le attività che richiedono attenzione"
                        )
                        AttentionGrid()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ModernSectionHeader(
                            title: "Azioni rapide",
                            subtitle: "Le operazioni più frequenti"
                        )
                        QuickActionsGrid()
                    }

                    TrialStatusCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
    }

    @ViewBuilder
    private func SchoolOverviewGrid() -> some View {
        HStack(spacing: 11) {
            NavigationLink { StudentsView() } label: {
                ModernMetricCard(
                    value: "\(store.students.count)",
                    label: "Allievi",
                    detail: "iscritti",
                    icon: "person.2.fill",
                    tint: .dzPurple
                )
            }
            NavigationLink { CoursesView() } label: {
                ModernMetricCard(
                    value: "\(store.courses.count)",
                    label: "Corsi",
                    detail: "attivi",
                    icon: "figure.dance",
                    tint: .dzFuchsia
                )
            }
            NavigationLink { OwnerAttendanceView() } label: {
                ModernMetricCard(
                    value: "91%",
                    label: "Presenze",
                    detail: "questo mese",
                    icon: "checkmark.circle.fill",
                    tint: .dzSky
                )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func AttentionGrid() -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
            NavigationLink { PaymentsManagementView(initialFilter: "Scadute") } label: {
                ModernAttentionCard(
                    value: "\(store.overduePaymentsCount)",
                    title: "Quote scadute",
                    subtitle: "Da verificare",
                    icon: "eurosign.circle.fill",
                    tint: .red
                )
            }
            NavigationLink { MedicalCertificatesView(showOnlyAlerts: true) } label: {
                ModernAttentionCard(
                    value: "\(store.medicalAlertsCount)",
                    title: "Certificati",
                    subtitle: "In scadenza",
                    icon: "cross.case.fill",
                    tint: .orange
                )
            }
            NavigationLink { CommunicationsManagementView() } label: {
                ModernAttentionCard(
                    value: "\(store.announcements.count)",
                    title: "Comunicazioni",
                    subtitle: "Pubblicate",
                    icon: "megaphone.fill",
                    tint: .dzFuchsia
                )
            }
            NavigationLink { InviteCenterView() } label: {
                ModernAttentionCard(
                    value: "3",
                    title: "Richieste",
                    subtitle: "In attesa",
                    icon: "person.crop.circle.badge.plus",
                    tint: .blue
                )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func QuickActionsGrid() -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink { PaymentsManagementView(initialFilter: "Da pagare") } label: {
                    ModernQuickAction(title: "Pagamento", icon: "eurosign.circle.fill", tint: .green)
                }
                NavigationLink { CommunicationsManagementView(openComposerOnAppear: true) } label: {
                    ModernQuickAction(title: "Nuovo avviso", icon: "megaphone.fill", tint: .dzFuchsia)
                }
            }
            HStack(spacing: 10) {
                NavigationLink { InviteCenterView() } label: {
                    ModernQuickAction(title: "Nuovo invito", icon: "qrcode", tint: .dzPurple)
                }
                NavigationLink { CoursesView() } label: {
                    ModernQuickAction(title: "Gestisci corsi", icon: "calendar.badge.plus", tint: .dzSky)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func TrialStatusCard() -> some View {
        NavigationLink { PlansView() } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.18))
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prova Premium attiva")
                        .font(.headline.weight(.bold))
                    Text("Restano \(store.trialDaysRemaining) giorni per provare tutte le funzioni")
                        .font(.caption)
                        .opacity(0.86)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundColor(.white)
            .padding(17)
            .background(BrandGradient())
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.dzPurple.opacity(0.22), radius: 18, y: 9)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Staff home

private struct StaffDashboard: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            ModernDashboardBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ModernWelcomeHeader(
                        eyebrow: "Area \(store.userRole.rawValue)",
                        title: "La tua giornata",
                        subtitle: store.schoolName,
                        badge: store.userRole == .teacher ? "3 lezioni assegnate" : "Segreteria operativa"
                    )

                    ModernSectionHeader(title: "Prossima lezione", subtitle: "Tutto pronto per il registro")
                    NavigationLink { AttendanceRegisterView() } label: {
                        FeaturedLessonCard(
                            time: "18:30",
                            title: "Hip Hop Teen",
                            room: "Sala Urban",
                            students: "24 allievi iscritti"
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 11) {
                        NavigationLink { StaffCoursesView() } label: {
                            ModernMetricCard(value: "3", label: "Lezioni", detail: "oggi", icon: "calendar", tint: .dzPurple)
                        }
                        NavigationLink { AttendanceRegisterView() } label: {
                            ModernMetricCard(value: "46", label: "Allievi", detail: "previsti", icon: "person.2.fill", tint: .dzFuchsia)
                        }
                        NavigationLink { StaffMessagesView() } label: {
                            ModernMetricCard(value: "\(store.announcements.count)", label: "Messaggi", detail: "nuovi", icon: "bubble.left.fill", tint: .dzSky)
                        }
                    }
                    .buttonStyle(.plain)

                    ModernSectionHeader(title: "Comunicazioni", subtitle: "Gli ultimi avvisi della scuola")
                    NavigationLink { StaffMessagesView() } label: {
                        ModernAnnouncementCard(
                            title: store.announcements.first?.title ?? "Nessun avviso",
                            body: store.announcements.first?.body ?? "Quando la scuola pubblicherà una comunicazione comparirà qui."
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Family home

private struct FamilyDashboard: View {
    @EnvironmentObject var store: AppStore

    private var linkedChildren: [Student] {
        store.userRole == .parent ? store.linkedChildrenForCurrentParent() : []
    }

    var body: some View {
        ZStack {
            ModernDashboardBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ModernWelcomeHeader(
                        eyebrow: store.userRole == .parent ? "Area famiglia" : "Area allievo",
                        title: store.userRole == .parent ? "La tua famiglia" : "Ciao!",
                        subtitle: store.schoolName,
                        badge: store.userRole == .parent ? "Profilo genitore" : "Profilo allievo"
                    )

                    if store.userRole == .parent {
                        LinkedChildCard(children: linkedChildren)
                    }

                    ModernSectionHeader(title: "Prossima lezione", subtitle: "Il prossimo appuntamento in calendario")
                    NavigationLink { FamilyCalendarView() } label: {
                        FeaturedLessonCard(
                            time: "17:00",
                            title: "Danza Classica",
                            room: "Sala Étoile",
                            students: "Insegnante: Giulia Ferri"
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 11) {
                        NavigationLink { FamilyAttendanceView() } label: {
                            ModernMetricCard(value: "96%", label: "Presenze", detail: "totali", icon: "checkmark.circle.fill", tint: .green)
                        }
                        NavigationLink { FamilyPaymentsView() } label: {
                            ModernMetricCard(value: "0", label: "Quote", detail: "aperte", icon: "eurosign.circle.fill", tint: .dzPurple)
                        }
                        NavigationLink { FamilyMedicalView() } label: {
                            ModernMetricCard(value: "OK", label: "Certificato", detail: "valido", icon: "cross.case.fill", tint: .orange)
                        }
                    }
                    .buttonStyle(.plain)

                    ModernSectionHeader(title: "Avvisi", subtitle: "Comunicazioni dalla scuola")
                    NavigationLink { StaffMessagesView() } label: {
                        ModernAnnouncementCard(
                            title: store.announcements.first?.title ?? "Nessun avviso",
                            body: store.announcements.first?.body ?? "Le comunicazioni della scuola appariranno qui."
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Shared modern components

private struct ModernDashboardBackground: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            Circle()
                .fill(Color.dzPurple.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 24)
                .offset(x: 145, y: -300)

            Circle()
                .fill(Color.dzFuchsia.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .offset(x: -155, y: 330)
        }
    }
}

private struct ModernWelcomeHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let badge: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BrandGradient()

            Circle()
                .fill(Color.white.opacity(0.11))
                .frame(width: 190, height: 190)
                .offset(x: 72, y: -72)

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 115, height: 115)
                .offset(x: -238, y: 116)

            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 13) {
                    AppIconMark(size: 58)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(eyebrow.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .opacity(0.76)
                        Text(title)
                            .font(.title2.weight(.bold))
                            .lineLimit(2)
                        Text(subtitle)
                            .font(.subheadline.weight(.medium))
                            .opacity(0.82)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                    Text(badge)
                        .lineLimit(1)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.16))
                .clipShape(Capsule())
            }
            .foregroundColor(.white)
            .padding(19)
        }
        .frame(minHeight: 178)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.dzPurple.opacity(0.24), radius: 24, y: 12)
    }
}

private struct ModernSectionHeader: View {
    let title: String
    let subtitle: String
    var actionTitle: String? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let actionTitle {
                Text(actionTitle)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.dzPurple)
            }
        }
    }
}

private struct ModernMetricCard: View {
    let value: String
    let label: String
    let detail: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(tint.opacity(0.12))
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(tint)
            }
            .frame(width: 34, height: 34)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(tint.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 12, y: 6)
    }
}

private struct ModernAttentionCard: View {
    let value: String
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                ZStack {
                    Circle().fill(tint.opacity(0.13))
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(tint)
                }
                .frame(width: 40, height: 40)
                Spacer()
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Apri")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(tint)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(tint)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(tint.opacity(0.13), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 12, y: 6)
    }
}

private struct ModernQuickAction: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.13))
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(tint)
            }
            .frame(width: 42, height: 42)

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 68)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
    }
}

private struct ModernTodaySchedule: View {
    var body: some View {
        VStack(spacing: 0) {
            ModernScheduleRow(time: "16:30", title: "Propedeutica", room: "Sala Étoile", tint: .dzPurple)
            Divider().padding(.leading, 67)
            ModernScheduleRow(time: "18:30", title: "Hip Hop Teen", room: "Sala Urban", tint: .dzFuchsia)
            Divider().padding(.leading, 67)
            ModernScheduleRow(time: "20:00", title: "Latino Avanzato", room: "Sala Ritmo", tint: .dzSky)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 14, y: 7)
    }
}

private struct ModernScheduleRow: View {
    let time: String
    let title: String
    let room: String
    let tint: Color

    var body: some View {
        HStack(spacing: 13) {
            Text(time)
                .font(.subheadline.weight(.bold))
                .foregroundColor(tint)
                .frame(width: 50, alignment: .leading)

            Capsule()
                .fill(tint)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(room)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
    }
}

private struct FeaturedLessonCard: View {
    let time: String
    let title: String
    let room: String
    let students: String

    var body: some View {
        HStack(spacing: 15) {
            VStack(spacing: 4) {
                Text(time)
                    .font(.title3.weight(.bold))
                Text("OGGI")
                    .font(.caption2.weight(.bold))
                    .tracking(0.7)
            }
            .foregroundColor(.white)
            .frame(width: 66, height: 76)
            .background(BrandGradient())
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                Label(room, systemImage: "door.left.hand.open")
                Label(students, systemImage: "person.2.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(.dzPurple)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 7)
    }
}

private struct ModernAnnouncementCard: View {
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.dzFuchsia.opacity(0.12))
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.dzFuchsia)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                Text("Apri comunicazioni")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.dzPurple)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 12, y: 6)
    }
}

private struct LinkedChildCard: View {
    let children: [Student]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Profilo selezionato")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 13) {
                ZStack {
                    Circle().fill(Color.dzPurple.opacity(0.12))
                    Image(systemName: children.isEmpty ? "person.crop.circle.badge.questionmark" : "person.fill")
                        .font(.title3)
                        .foregroundColor(.dzPurple)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(children.first?.name ?? "Nessun figlio collegato")
                        .font(.headline)
                    Text(children.isEmpty ? "Collega un figlio dal Profilo" : "Tocca il profilo per gestire corsi e documenti")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.dzPurple.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 12, y: 6)
    }
}
