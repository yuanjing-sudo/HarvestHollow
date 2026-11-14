#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Feature cards

public struct TownFeatureCard: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let accent: Color
    public let badge: String?
    public let action: () -> Void

    public init(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
        self.badge = badge
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [accent.opacity(0.95), accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    Spacer(minLength: 4)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accent.opacity(0.12), in: Capsule())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(HHTheme.muted.opacity(0.55))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HHTheme.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: HHTheme.soilDark.opacity(0.09), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

public struct TownQuickLink: View {
    public let title: String
    public let icon: String
    public let tint: Color
    public let action: () -> Void

    public init(title: String, icon: String, tint: Color, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.hhCaption(11))
                    .lineLimit(1)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.09), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Segmented picker

public struct CozySegmentedPicker<Item: Hashable>: View {
    public let items: [Item]
    public let title: (Item) -> String
    public let icon: ((Item) -> String)?
    public let tint: Color
    @Binding public var selection: Item

    public init(
        items: [Item],
        selection: Binding<Item>,
        tint: Color = HHTheme.forest,
        icon: ((Item) -> String)? = nil,
        title: @escaping (Item) -> String
    ) {
        self.items = items
        _selection = selection
        self.tint = tint
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 5) {
                ForEach(items, id: \.self) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selection = item
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if let icon {
                                Image(systemName: icon(item))
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(title(item))
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(selection == item ? .white : HHTheme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background {
                            Capsule()
                                .fill(selection == item ? tint : HHTheme.paper)
                        }
                        .overlay(
                            Capsule()
                                .stroke(
                                    selection == item ? tint : HHTheme.ink.opacity(0.07),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Rings and charts

public struct ProgressRing: View {
    public let value: Double
    public let tint: Color
    public let lineWidth: CGFloat
    public let label: String?
    public let detail: String?

    public init(
        value: Double,
        tint: Color = HHTheme.forest,
        lineWidth: CGFloat = 7,
        label: String? = nil,
        detail: String? = nil
    ) {
        self.value = value
        self.tint = tint
        self.lineWidth = lineWidth
        self.label = label
        self.detail = detail
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.01, min(1, value)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.7), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                if let label {
                    Text(label)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.ink)
                }
                if let detail {
                    Text(detail)
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
            }
        }
        .animation(.easeOut(duration: 0.4), value: value)
    }
}

public struct MiniBarChart: View {
    public let values: [Double]
    public let tint: Color
    public let labels: [String]

    public init(values: [Double], labels: [String] = [], tint: Color = HHTheme.forest) {
        self.values = values
        self.labels = labels
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: 5) {
            GeometryReader { proxy in
                let maxValue = max(1, values.max() ?? 1)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        let fraction = max(0.06, value / maxValue)
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            tint.opacity(0.55 + 0.45 * fraction),
                                            tint
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(4, (proxy.size.height - 16) * fraction))
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(labels.indices.contains(index) ? labels[index] : "\(index)"): \(Int(value))")
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 56)

            if !labels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

public struct MiniTrendBar: View {
    public let value: Double
    public let tint: Color

    public init(value: Double, tint: Color = HHTheme.forest) {
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(HHTheme.ink.opacity(0.06))
                Capsule()
                    .fill(tint)
                    .frame(width: max(2, CGFloat(max(0, min(1, value))) * proxy.size.width))
            }
        }
        .frame(height: 5)
    }
}

// MARK: - Badges and chips

public struct RarityBadge: View {
    public let rarity: FishRarity
    public let compact: Bool

    public init(_ rarity: FishRarity, compact: Bool = false) {
        self.rarity = rarity
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkle")
                .font(.system(size: compact ? 7 : 8, weight: .bold))
            Text(rarity.title)
                .font(.system(size: compact ? 8.5 : 9.5, weight: .heavy, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(Color(hex: rarity.tintHex))
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 2 : 3)
        .background(Color(hex: rarity.tintHex).opacity(0.11), in: Capsule())
        .overlay(Capsule().stroke(Color(hex: rarity.tintHex).opacity(0.18), lineWidth: 1))
    }
}

public struct IngredientChip: View {
    public let itemID: String
    public let needed: Int
    public let owned: Int
    public let name: String
    public let spriteKey: String?
    public let emoji: String

    public init(
        itemID: String,
        needed: Int,
        owned: Int,
        name: String,
        spriteKey: String?,
        emoji: String
    ) {
        self.itemID = itemID
        self.needed = needed
        self.owned = owned
        self.name = name
        self.spriteKey = spriteKey
        self.emoji = emoji
    }

    private var enough: Bool { owned >= needed }

    public var body: some View {
        HStack(spacing: 5) {
            ItemIconView(spriteKey: spriteKey, emoji: emoji, size: 22)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                Text("\(owned)/\(needed)")
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(enough ? HHTheme.forest : HHTheme.terracotta)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(
            (enough ? HHTheme.forest : HHTheme.terracotta).opacity(0.07),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(
                    (enough ? HHTheme.forest : HHTheme.terracotta).opacity(0.13),
                    lineWidth: 1
                )
        )
    }
}

public struct TownInfoRow: View {
    public let icon: String
    public let title: String
    public let value: String
    public let tint: Color

    public init(icon: String, title: String, value: String, tint: Color = HHTheme.forest) {
        self.icon = icon
        self.title = title
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.1), in: Circle())
            Text(title)
                .font(.hhCaption(11.5))
                .foregroundStyle(HHTheme.muted)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

public struct CozyDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(HHTheme.ink.opacity(0.07))
            .frame(height: 1)
            .padding(.vertical, 2)
    }
}

// MARK: - Ponds and skies

public struct AnimatedPondScene: View {
    public let fishID: String?
    public let tint: Color
    public let height: CGFloat

    public init(fishID: String? = nil, tint: Color = Color(hex: "4F8AAE"), height: CGFloat = 180) {
        self.fishID = fishID
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                let water = CGRect(origin: .zero, size: size)
                context.fill(Path(water), with: .linearGradient(
                    Gradient(colors: [
                        Color(hex: "8FC3DD"),
                        Color(hex: "4F8AAE"),
                        Color(hex: "2E5E78")
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                for index in 0..<9 {
                    let seed = Double(index)
                    let y = size.height * (0.15 + (seed * 0.11).truncatingRemainder(dividingBy: 0.8))
                    let width = size.width * (0.22 + (seed * 0.07).truncatingRemainder(dividingBy: 0.48))
                    let x = (time * (5 + seed * 1.4) + seed * 47)
                        .truncatingRemainder(dividingBy: Double(size.width + width)) - width
                    let rect = CGRect(x: x, y: y, width: width, height: 1.2)
                    context.fill(Path(roundedRect: rect, cornerRadius: 0.6), with: .color(.white.opacity(0.18)))
                }

                for index in 0..<5 {
                    let x = size.width * (0.12 + Double(index) * 0.19)
                    let y = size.height * (0.78 + (Double(index % 2) * 0.05))
                    let pad = CGRect(x: x, y: y, width: 20, height: 7)
                    context.fill(Path(ellipseIn: pad), with: .color(Color(hex: "5E8A5A").opacity(0.85)))
                    context.fill(
                        Path(ellipseIn: pad.insetBy(dx: 4, dy: 1.5)),
                        with: .color(Color(hex: "7DBF5B"))
                    )
                }

                if let fishID, let sprite = SpriteLibrary.fish(fishID) {
                    let fishWidth = min(96, size.width * 0.42)
                    let fishHeight = fishWidth * CGFloat(sprite.height) / CGFloat(sprite.width)
                    let bob = sin(time * 1.6) * 5
                    draw(sprite: sprite, in: CGRect(
                        x: size.width * 0.5 - fishWidth * 0.5,
                        y: size.height * 0.5 - fishHeight * 0.5 + bob,
                        width: fishWidth,
                        height: fishHeight
                    ), context: &context)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func draw(sprite: PixelSprite, in rect: CGRect, context: inout GraphicsContext) {
        let cell = min(rect.width / CGFloat(sprite.width), rect.height / CGFloat(sprite.height))
        let origin = CGPoint(
            x: rect.midX - cell * CGFloat(sprite.width) / 2,
            y: rect.midY - cell * CGFloat(sprite.height) / 2
        )
        for pixel in sprite.cells {
            let p = CGRect(
                x: origin.x + CGFloat(pixel.x) * cell,
                y: origin.y + CGFloat(pixel.y) * cell,
                width: cell + 0.2,
                height: cell + 0.2
            )
            context.fill(Path(p), with: .color(Color(hex: pixel.hex)))
        }
    }
}

public struct WeatherDiorama: View {
    public let weather: Weather
    public let timeOfDay: Double
    public let compact: Bool

    public init(weather: Weather, timeOfDay: Double, compact: Bool = false) {
        self.weather = weather
        self.timeOfDay = timeOfDay
        self.compact = compact
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let sky = HHTheme.headerGradient(timeOfDay: timeOfDay)
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: skyColors),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                let hill = Path { path in
                    path.move(to: CGPoint(x: 0, y: size.height * 0.72))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width, y: size.height * 0.66),
                        control: CGPoint(x: size.width * 0.5, y: size.height * 0.48)
                    )
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()
                }
                context.fill(hill, with: .color(HHTheme.forest.opacity(0.55)))

                switch weather {
                case .sunny, .heatwave:
                    let sunRect = CGRect(
                        x: size.width * 0.68,
                        y: size.height * 0.18,
                        width: compact ? 28 : 42,
                        height: compact ? 28 : 42
                    )
                    context.fill(
                        Path(ellipseIn: sunRect),
                        with: .color(weather == .heatwave ? HHTheme.terracotta : HHTheme.gold)
                    )
                case .rainy, .storm:
                    for index in 0..<16 {
                        let seed = Double(index)
                        let x = (seed * 37 + time * 34).truncatingRemainder(dividingBy: Double(size.width))
                        let y = (seed * 23 + time * 70).truncatingRemainder(dividingBy: Double(size.height))
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x - 2, y: y + (compact ? 5 : 8)))
                        context.stroke(path, with: .color(.white.opacity(0.55)), lineWidth: 1)
                    }
                case .breezy:
                    for index in 0..<4 {
                        let y = size.height * (0.25 + Double(index) * 0.12)
                        var path = Path()
                        path.move(to: CGPoint(x: size.width * 0.1, y: y))
                        path.addCurve(
                            to: CGPoint(x: size.width * 0.88, y: y - 4),
                            control1: CGPoint(x: size.width * 0.35, y: y - 10),
                            control2: CGPoint(x: size.width * 0.62, y: y + 8)
                        )
                        context.stroke(path, with: .color(.white.opacity(0.34)), lineWidth: 1.4)
                    }
                }
            }
        }
        .frame(height: compact ? 86 : 150)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 14 : 20, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
    }

    private var skyColors: [Color] {
        switch timeOfDay {
        case ..<0.24:
            return [Color(hex: "283252"), Color(hex: "596382"), Color(hex: "B98376")]
        case ..<0.4:
            return [Color(hex: "F2B98A"), Color(hex: "F8DDB2"), Color(hex: "C4E8EF")]
        case ..<0.7:
            return [Color(hex: "8FD0E4"), Color(hex: "C4E8EF"), Color(hex: "F6E7C8")]
        case ..<0.86:
            return [Color(hex: "F3A77E"), Color(hex: "F6C99A"), Color(hex: "E8C3B0")]
        default:
            return [Color(hex: "2A3550"), Color(hex: "4A5375"), Color(hex: "7F7D9C")]
        }
    }
}

// MARK: - Empty and section helpers

public struct TownSectionTitle: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let accent: Color

    public init(title: String, subtitle: String, icon: String, accent: Color = HHTheme.forest) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 25, height: 25)
                .background(accent.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hhHeadline(15))
                    .foregroundStyle(HHTheme.ink)
                Text(subtitle)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

public struct TownEmptyCard: View {
    public let icon: String
    public let title: String
    public let message: String
    public let accent: Color
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        accent: Color = HHTheme.forest,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.accent = accent
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 48, height: 48)
                .background(accent.opacity(0.1), in: Circle())
            Text(title)
                .font(.hhHeadline(14))
                .foregroundStyle(HHTheme.ink)
            Text(message)
                .font(.hhBody(12))
                .foregroundStyle(HHTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(CozySecondaryButtonStyle())
                    .padding(.top, 1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(HHTheme.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Navigation header

public struct TownScreenHeader: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let accent: Color

    public init(title: String, subtitle: String, icon: String, accent: Color) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    LinearGradient(
                        colors: [accent.opacity(0.9), accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.hhTitle(23))
                    .foregroundStyle(HHTheme.ink)
                Text(subtitle)
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
#endif
