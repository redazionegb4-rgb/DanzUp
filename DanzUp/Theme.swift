import SwiftUI

extension Color {
    static let dzIndigo = Color(red: 0.24, green: 0.18, blue: 0.55)
    static let dzPurple = Color(red: 0.52, green: 0.25, blue: 0.78)
    static let dzPink = Color(red: 0.90, green: 0.31, blue: 0.62)
    static let dzSurface = Color(uiColor: .secondarySystemBackground)
}

struct BrandGradient: View {
    var body: some View {
        LinearGradient(colors: [Color.dzIndigo, Color.dzPurple, Color.dzPink], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct DZCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.primary.opacity(0.06)))
            .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }
}

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
