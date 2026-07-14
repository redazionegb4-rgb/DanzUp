import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                trialCard
                metrics
                todaySection
                alertsSection
                announcements
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buongiorno, \(store.ownerName)")
                    .font(.title2.bold())
                Text(store.schoolName)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.headline)
                    .foregroundStyle(Color.dzPurple)
                    .frame(width: 44, height: 44)
                    .background(Color.dzPurple.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.top, 8)
    }

    private var trialCard: some View {
        ZStack(alignment: .leading) {
            BrandGradient()
            Circle().fill(.white.opacity(0.1)).frame(width: 170).offset(x: 250, y: -55)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("PROVA PREMIUM", systemImage: "crown.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                    Spacer()
                    Text("\(store.trialDaysRemaining) giorni")
                        .font(.title3.bold())
                }
                Text("Tutte le funzioni sono sbloccate")
                    .font(.headline)
                ProgressView(value: 1.0 - store.trialProgress)
                    .tint(.white)
                Text("La prova gratuita dura 14 giorni")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.dzPurple.opacity(0.25), radius: 18, y: 10)
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(icon: "person.3.fill", value: "\(store.students.count)", label: "Allievi attivi", tint: Color.dzPurple)
            MetricCard(icon: "figure.dance", value: "\(store.courses.count)", label: "Corsi attivi", tint: Color.dzPink)
            MetricCard(icon: "checkmark.circle.fill", value: "91%", label: "Presenze medie", tint: .green)
            MetricCard(icon: "eurosign.circle.fill", value: "3", label: "Quote da verificare", tint: .orange)
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lezioni di oggi").font(.title3.bold())
                Spacer()
                Text("Vedi tutte").font(.subheadline.weight(.semibold)).foregroundStyle(Color.dzPurple)
            }
            ForEach(store.courses.prefix(2)) { course in
                HStack(spacing: 14) {
                    VStack(spacing: 2) {
                        Text(course.time).font(.headline)
                        Text(course.day.prefix(3).uppercased()).font(.caption2.bold()).foregroundStyle(.secondary)
                    }
                    .frame(width: 58, height: 58)
                    .background(Color.dzPurple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title).font(.headline)
                        Text("\(course.teacher) • \(course.room)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Da controllare").font(.title3.bold())
            HStack(spacing: 12) {
                AlertTile(icon: "doc.text.fill", title: "2 certificati", subtitle: "in scadenza", tint: .orange)
                AlertTile(icon: "exclamationmark.circle.fill", title: "1 quota", subtitle: "scaduta", tint: .red)
            }
        }
    }

    private var announcements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comunicazioni recenti").font(.title3.bold())
            ForEach(store.announcements, id: \.id) { announcement in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(announcement.title).font(.headline)
                        Spacer()
                        Text(announcement.audience).font(.caption2.bold()).foregroundStyle(Color.dzPurple)
                    }
                    Text(announcement.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
        }
        .padding(.bottom, 20)
    }
}

private struct AlertTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).font(.title3)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}
