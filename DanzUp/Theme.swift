import SwiftUI

extension Color {
    static let dzNavy = Color(red: 0.08, green: 0.07, blue: 0.20)
    static let dzPurple = Color(red: 0.43, green: 0.24, blue: 0.86)
    static let dzFuchsia = Color(red: 0.93, green: 0.23, blue: 0.61)
    static let dzSky = Color(red: 0.25, green: 0.68, blue: 0.96)
}

struct BrandGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color.dzNavy, Color.dzPurple, Color.dzFuchsia],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(uiColor: .systemGroupedBackground), Color.dzPurple.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct DZCard<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.06))
            )
            .shadow(color: Color.black.opacity(0.06), radius: 14, y: 7)
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
