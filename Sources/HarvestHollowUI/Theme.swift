#if canImport(SwiftUI)
import SwiftUI

// MARK: - Colours

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 3:
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double(value & 0xF) / 15
            a = 1
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = 0.5; g = 0.5; b = 0.5; a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

public enum HHTheme {
    public static let cream = Color(hex: "F7F1E3")
    public static let paper = Color(hex: "FFFBF1")
    public static let paperDeep = Color(hex: "F1E5D0")
    public static let forest = Color(hex: "3E6B4F")
    public static let forestDark = Color(hex: "274936")
    public static let leaf = Color(hex: "6FA84F")
    public static let leafLight = Color(hex: "A7CE7E")
    public static let terracotta = Color(hex: "C96A4B")
    public static let terracottaDark = Color(hex: "9E4C35")
    public static let gold = Color(hex: "E8BC55")
    public static let goldDeep = Color(hex: "B8892E")
    public static let soil = Color(hex: "B07A52")
    public static let soilDark = Color(hex: "845637")
    public static let soilLight = Color(hex: "D3A478")
    public static let ink = Color(hex: "3A2E28")
    public static let muted = Color(hex: "7A6A5F")
    public static let sky = Color(hex: "BFE3EE")
    public static let rose = Color(hex: "E8A7B7")
    public static let lavender = Color(hex: "8E6BC4")

    public static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FBEFD8"), Color(hex: "F3E4CC"), Color(hex: "EADCC6")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public static func headerGradient(timeOfDay: Double) -> LinearGradient {
        let colors: [Color]
        switch timeOfDay {
        case ..<0.22:
            colors = [Color(hex: "2C3B5A"), Color(hex: "58658A"), Color(hex: "C68A7A")]
        case ..<0.34:
            colors = [Color(hex: "F2B98A"), Color(hex: "F6D6A8"), Color(hex: "BFE3EE")]
        case ..<0.66:
            colors = [Color(hex: "8FD0E4"), Color(hex: "C4E8EF"), Color(hex: "F6E7C8")]
        case ..<0.82:
            colors = [Color(hex: "F3A77E"), Color(hex: "F6C99A"), Color(hex: "E8C3B0")]
        default:
            colors = [Color(hex: "2A3550"), Color(hex: "4A5375"), Color(hex: "7F7D9C")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public static func comfortTint(_ comfort: Int) -> Color {
        if comfort >= 40 { return goldDeep }
        if comfort >= 20 { return forest }
        if comfort >= 8 { return terracotta }
        return muted
    }
}

// MARK: - Typography

public extension Font {
    static func hhTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func hhHeadline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func hhBody(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func hhCaption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Shared surfaces

public struct CozyCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(HHTheme.paper.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(HHTheme.ink.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: HHTheme.soilDark.opacity(0.12), radius: 14, x: 0, y: 8)
    }
}

public struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?

    public init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HHTheme.terracotta)
                }
                Text(title)
                    .font(.hhHeadline(19))
                    .foregroundStyle(HHTheme.ink)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.hhCaption(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public struct TagChip: View {
    let text: String
    let icon: String?
    let tint: Color

    public init(_ text: String, icon: String? = nil, tint: Color = HHTheme.forest) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.hhCaption(11.5))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .foregroundStyle(tint)
        .background(tint.opacity(0.12), in: Capsule())
    }
}
#endif
