import SwiftUI
import UIKit

extension Color {
    static let dzNavy = Color(red: 0.08, green: 0.07, blue: 0.20)
    static let dzPurple = Color(red: 0.43, green: 0.24, blue: 0.86)
    static let dzFuchsia = Color(red: 0.93, green: 0.23, blue: 0.61)
    static let dzSky = Color(red: 0.25, green: 0.68, blue: 0.96)
    static let dzMint = Color(red: 0.20, green: 0.78, blue: 0.66)
    static let dzOrange = Color(red: 1.00, green: 0.55, blue: 0.23)
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
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            RadialGradient(
                colors: [Color.dzPurple.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 430
            )
            RadialGradient(
                colors: [Color.dzFuchsia.opacity(0.09), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 380
            )
        }
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
            .padding(17)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.10), Color.dzPurple.opacity(0.025)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 18, y: 9)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModernPageHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.dzPurple, .dzFuchsia],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title2.bold())
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

private struct ModernScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(ScreenBackground())
            .toolbarBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func modernScreen() -> some View {
        modifier(ModernScreenModifier())
    }

    func modernRow() -> some View {
        self
            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
            .listRowSeparatorTint(Color.primary.opacity(0.08))
    }
}
