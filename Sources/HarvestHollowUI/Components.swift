#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Pixel art

public struct PixelSpriteView: View {
    public let sprite: PixelSprite

    public init(_ sprite: PixelSprite) {
        self.sprite = sprite
    }

    public var body: some View {
        Canvas { context, size in
            let cell = min(
                size.width / CGFloat(sprite.width),
                size.height / CGFloat(sprite.height)
            )
            let origin = CGPoint(
                x: ((size.width - cell * CGFloat(sprite.width)) / 2).rounded(.down),
                y: ((size.height - cell * CGFloat(sprite.height)) / 2).rounded(.down)
            )

            for pixel in sprite.cells {
                let rect = CGRect(
                    x: origin.x + CGFloat(pixel.x) * cell,
                    y: origin.y + CGFloat(pixel.y) * cell,
                    width: cell + 0.25,
                    height: cell + 0.25
                )
                context.fill(Path(rect), with: .color(Color(hex: pixel.hex)))
            }
        }
        .aspectRatio(CGFloat(sprite.width) / CGFloat(sprite.height), contentMode: .fit)
        .accessibilityHidden(true)
    }
}

public struct ItemIconView: View {
    public let spriteKey: String?
    public let emoji: String
    public let size: CGFloat

    public init(spriteKey: String?, emoji: String, size: CGFloat = 40) {
        self.spriteKey = spriteKey
        self.emoji = emoji
        self.size = size
    }

    public var body: some View {
        Group {
            if let spriteKey, let sprite = SpriteLibrary.sprite(named: spriteKey) {
                PixelSpriteView(sprite)
            } else {
                Text(emoji)
                    .font(.system(size: size * 0.66))
            }
        }
        .frame(width: size, height: size)
    }
}

public struct AnimalSpriteView: View {
    public let speciesID: String
    public let size: CGFloat

    public init(speciesID: String, size: CGFloat = 80) {
        self.speciesID = speciesID
        self.size = size
    }

    public var body: some View {
        Group {
            if let sprite = SpriteLibrary.animal(speciesID) {
                PixelSpriteView(sprite)
            } else {
                Text("🐾").font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size * 0.86)
    }
}

public struct CropSpriteView: View {
    public let cropID: String
    public let size: CGFloat

    public init(cropID: String, size: CGFloat = 42) {
        self.cropID = cropID
        self.size = size
    }

    public var body: some View {
        Group {
            if let sprite = SpriteLibrary.crop(cropID) {
                PixelSpriteView(sprite)
            } else {
                Text("🌱").font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size)
    }
}

public struct FurnitureSpriteView: View {
    public let itemID: String
    public let emoji: String

    public init(itemID: String, emoji: String = "🪑") {
        self.itemID = itemID
        self.emoji = emoji
    }

    public var body: some View {
        Group {
            if let sprite = SpriteLibrary.furniture(itemID) {
                PixelSpriteView(sprite)
            } else {
                Text(emoji).font(.system(size: 30))
            }
        }
    }
}

// MARK: - HUD

public struct CoinMark: View {
    public let size: CGFloat

    public init(size: CGFloat = 20) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFE08A"), HHTheme.gold, HHTheme.goldDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(HHTheme.goldDeep.opacity(0.45), lineWidth: 1)
                .padding(1)
            Text("H")
                .font(.system(size: size * 0.52, weight: .black, design: .rounded))
                .foregroundStyle(HHTheme.goldDeep.opacity(0.85))
        }
        .frame(width: size, height: size)
        .shadow(color: HHTheme.goldDeep.opacity(0.25), radius: 2, y: 1)
    }
}

public struct CoinPill: View {
    public let amount: Int
    public var compact: Bool

    public init(_ amount: Int, compact: Bool = false) {
        self.amount = amount
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 6) {
            CoinMark(size: compact ? 18 : 21)
            Text("\(amount)")
                .font(.system(size: compact ? 13 : 15, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(Capsule().fill(HHTheme.paper.opacity(0.94)))
        .overlay(Capsule().stroke(HHTheme.goldDeep.opacity(0.26), lineWidth: 1))
        .animation(.snappy, value: amount)
    }
}

public struct LevelBadge: View {
    public let level: Int
    public let progress: Double
    public let showXP: Bool

    public init(level: Int, progress: Double, showXP: Bool = false) {
        self.level = level
        self.progress = progress
        self.showXP = showXP
    }

    public var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(HHTheme.forest.opacity(0.18), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0.02, min(1, progress)))
                    .stroke(
                        HHTheme.forest,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: -1) {
                    Text("\(level)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.forestDark)
                    Text("LV")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
            }
            .frame(width: 42, height: 42)

            if showXP {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Farmer level \(level)")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    CozyProgressBar(value: progress, tint: HHTheme.forest, height: 5)
                        .frame(width: 84)
                }
            }
        }
        .accessibilityLabel("Level \(level), \(Int(progress * 100)) percent to next level")
    }
}

public struct StatTile: View {
    public let title: String
    public let value: String
    public let icon: String
    public let tint: Color

    public init(title: String, value: String, icon: String, tint: Color = HHTheme.forest) {
        self.title = title
        self.value = value
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.hhCaption(11.5))
                .foregroundStyle(HHTheme.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HHTheme.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Progress

public struct CozyProgressBar: View {
    public var value: Double
    public var tint: Color
    public var height: CGFloat

    public init(value: Double, tint: Color = HHTheme.forest, height: CGFloat = 8) {
        self.value = value
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HHTheme.ink.opacity(0.07))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.78), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(max(0, min(1, value))) * proxy.size.width)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.35), value: value)
    }
}

// MARK: - Buttons

public struct CozyPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hhHeadline(14))
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [HHTheme.forest, HHTheme.forestDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: HHTheme.forestDark.opacity(0.22), radius: 3, y: 2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

public struct CozySecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hhHeadline(13))
            .foregroundStyle(HHTheme.forestDark)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(HHTheme.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(HHTheme.forest.opacity(0.25), lineWidth: 1.2)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

public struct MiniActionStyle: ButtonStyle {
    public let tint: Color

    public init(tint: Color = HHTheme.forest) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hhHeadline(12))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.11), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

public struct RoundIconButton: View {
    public let icon: String
    public let action: () -> Void

    public init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(HHTheme.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(HHTheme.paper.opacity(0.9)))
                .overlay(Circle().stroke(HHTheme.ink.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feedback

public struct ToastView: View {
    public let title: String
    public let detail: String?
    public let icon: String
    public let tint: Color

    public init(title: String, detail: String?, icon: String, tint: Color) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(2)
                if let detail {
                    Text(detail)
                        .font(.hhCaption(11.5))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: HHTheme.soilDark.opacity(0.2), radius: 12, y: 6)
        .padding(.horizontal, 16)
    }
}

public struct NoticeBanner: View {
    public let icon: String
    public let title: String
    public let message: String
    public let tint: Color

    public init(icon: String, title: String, message: String, tint: Color = HHTheme.forest) {
        self.icon = icon
        self.title = title
        self.message = message
        self.tint = tint
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hhHeadline(13))
                    .foregroundStyle(HHTheme.ink)
                Text(message)
                    .font(.hhCaption(11.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }
}

public struct EmptyStateView: View {
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
        accent: Color = HHTheme.terracotta,
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
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 58, height: 58)
                .background(accent.opacity(0.1), in: Circle())
            Text(title)
                .font(.hhHeadline(16))
                .foregroundStyle(HHTheme.ink)
            Text(message)
                .font(.hhBody(13))
                .foregroundStyle(HHTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(CozyPrimaryButtonStyle())
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
    }
}

// MARK: - Confetti

public struct ConfettiView: View {
    public init() {}

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let width = Double(size.width)
                let height = Double(size.height)
                let colors = [HHTheme.gold, HHTheme.rose, HHTheme.leaf, HHTheme.terracotta, HHTheme.lavender]

                for index in 0..<38 {
                    let seed = Double(index)
                    let speed = 42 + (seed * 19).truncatingRemainder(dividingBy: 70)
                    let x = (seed * 83).truncatingRemainder(dividingBy: max(1, width))
                    let y = (time * speed + seed * 59).truncatingRemainder(dividingBy: height + 50) - 25
                    let angle = Angle(degrees: (time * 110 + seed * 43).truncatingRemainder(dividingBy: 360))
                    let tint = colors[index % colors.count]

                    context.drawLayer { layer in
                        layer.translateBy(x: CGFloat(x), y: CGFloat(y))
                        layer.rotate(by: angle)
                        let rect = CGRect(x: -4, y: -2.5, width: 8, height: 5)
                        layer.fill(Path(roundedRect: rect, cornerRadius: 1.2), with: .color(tint))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
#endif
