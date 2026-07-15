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

// MARK: - DanzUp 2026 visual system
struct DZHeroHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    var accent: Color = .dzPurple

    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.dzNavy, accent.opacity(0.92), Color.dzFuchsia.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 150, height: 150)
                .offset(x: 240, y: -48)
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 90, height: 90)
                .offset(x: 185, y: 46)

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.heavy))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(title)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                    Image(systemName: systemImage)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(appeared ? 0 : -8))
                .scaleEffect(appeared ? 1 : 0.82)
            }
            .padding(22)
        }
        .frame(height: 176)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: accent.opacity(0.24), radius: 24, y: 14)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { appeared = true }
        }
    }
}

struct DZMetricTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.heavy))
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color.opacity(0.12)))
    }
}

struct DZEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.dzPurple.opacity(0.11)).frame(width: 78, height: 78)
                Image(systemName: icon).font(.system(size: 31, weight: .semibold)).foregroundStyle(Color.dzPurple)
            }
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dzPurple)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

struct DZProgressRing: View {
    let value: Double
    let color: Color
    let text: String

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.12), lineWidth: 7)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(text).font(.caption2.weight(.heavy))
        }
        .frame(width: 54, height: 54)
    }
}

struct DZFloatingAddButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(BrandGradient())
                .clipShape(Circle())
                .shadow(color: Color.dzPurple.opacity(0.35), radius: 16, y: 8)
        }
        .accessibilityLabel("Aggiungi")
    }
}
