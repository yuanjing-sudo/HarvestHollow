#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Small metrics

struct LedgerMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
                Text(title)
                    .font(.system(size: 7.5, weight: .black, design: .rounded))
            }
            .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
    }
}

struct LedgerMiniStat: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
    }
}

// MARK: - Sparkline

struct EconomySparkCard: View {
    let title: String
    let value: String
    let values: [Double]
    let tint: Color
    let icon: String
    var invert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
                Text(title)
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Canvas { context, size in
                let points = sparkPoints(in: size)
                guard points.count >= 2 else { return }
                var path = Path()
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(
                    path,
                    with: .color(tint.opacity(0.95)),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )
                if let last = points.last {
                    context.fill(
                        Path(ellipseIn: CGRect(x: last.x - 2, y: last.y - 2, width: 4, height: 4)),
                        with: .color(tint)
                    )
                }
            }
            .frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(HHTheme.paper.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    private func sparkPoints(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let span = max(0.001, high - low)
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = size.height - size.height * CGFloat((value - low) / span)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Factor tile

struct EconomyFactorTile: View {
    let reading: EconomyFactorReading

    private var scoreColor: Color {
        if !reading.isUnlocked { return HHTheme.muted }
        if reading.score < 35 { return HHTheme.terracotta }
        if reading.score < 60 { return HHTheme.goldDeep }
        return HHTheme.forest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: reading.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(reading.isUnlocked ? scoreColor : HHTheme.muted)
                Text(reading.shortTitle)
                    .font(.hhCaption(11))
                    .foregroundStyle(reading.isUnlocked ? HHTheme.ink : HHTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if !reading.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(HHTheme.muted)
                } else {
                    Image(systemName: reading.trend > 0.0001 ? "arrow.up.right" : (reading.trend < -0.0001 ? "arrow.down.right" : "minus"))
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(reading.trend >= 0 ? HHTheme.forest : HHTheme.terracotta)
                }
            }

            Text(reading.valueText)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(reading.isUnlocked ? HHTheme.muted : HHTheme.muted.opacity(0.7))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(HHTheme.paperDeep)
                    Capsule()
                        .fill(scoreColor.opacity(reading.isUnlocked ? 0.9 : 0.25))
                        .frame(width: max(3, geo.size.width * CGFloat(reading.score / 100)))
                }
            }
            .frame(height: 4)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(reading.isUnlocked ? HHTheme.paper.opacity(0.9) : HHTheme.paperDeep.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(reading.isUnlocked ? scoreColor.opacity(0.14) : HHTheme.ink.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Policy controls

struct LedgerPolicyRow: View {
    let title: String
    let detail: String
    let value: Double
    let tint: Color
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.hhCaption(12))
                        .foregroundStyle(HHTheme.ink)
                    Text("\(Int((value * 100).rounded()))%")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                }
                Text(detail)
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Button(action: onDecrease) {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(canDecrease ? tint : HHTheme.muted.opacity(0.45))
                    .frame(width: 28, height: 28)
                    .background(HHTheme.paperDeep.opacity(0.7), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canDecrease)
            Button(action: onIncrease) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(canIncrease ? tint : HHTheme.muted.opacity(0.45))
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(canIncrease ? 0.12 : 0.04), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canIncrease)
        }
        .padding(9)
        .background(HHTheme.paperDeep.opacity(0.42), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Investment tile

struct LedgerInvestmentTile: View {
    let investment: EconomyInvestment
    let unlocked: Bool
    let affordable: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: investment.icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(unlocked ? HHTheme.forest : HHTheme.muted)
                .frame(width: 26, height: 26)
                .background(
                    (unlocked ? HHTheme.forest : HHTheme.muted).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(investment.title)
                        .font(.hhCaption(10.5))
                        .foregroundStyle(unlocked ? HHTheme.ink : HHTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(HHTheme.muted)
                    }
                }
                Text(investment.blurb)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(unlocked ? "\(investment.cost)c" : "Level \(investment.minimumLevel)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(unlocked ? (affordable ? HHTheme.goldDeep : HHTheme.terracotta) : HHTheme.muted)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(HHTheme.paper.opacity(unlocked ? 0.9 : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    unlocked ? (affordable ? HHTheme.forest.opacity(0.16) : HHTheme.terracotta.opacity(0.16)) : HHTheme.ink.opacity(0.04),
                    lineWidth: 1
                )
        )
        .opacity(unlocked && affordable ? 1 : 0.8)
    }
}

// MARK: - Agent tiles

struct LedgerFirmTile: View {
    let firm: AIBusiness

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: firm.kind.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HHTheme.lavender)
                Text(firm.name)
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
            }
            Text("\(firm.kind.title) · \(firm.employees) staff")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            HStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(HHTheme.paperDeep)
                        Capsule()
                            .fill(firm.mood > 0.45 ? HHTheme.leaf : HHTheme.terracotta)
                            .frame(width: max(3, geo.size.width * CGFloat(firm.mood)))
                    }
                }
                .frame(width: 48, height: 4)
                Text("\(Int(firm.capital))c")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(HHTheme.goldDeep)
            }
        }
        .padding(8)
        .frame(width: 132, alignment: .leading)
        .background(HHTheme.paper.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HHTheme.lavender.opacity(0.12), lineWidth: 1)
        )
    }
}

struct LedgerCitizenChip: View {
    let citizen: AICitizen

    var body: some View {
        HStack(spacing: 6) {
            Text(String(citizen.name.prefix(1)))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(citizen.employed ? HHTheme.leaf : HHTheme.muted, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(citizen.name)
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.ink)
                Text(citizen.employed ? "\(citizen.job) · \(Int(citizen.income))c" : "Looking for work")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(HHTheme.paper.opacity(0.9), in: Capsule())
        .overlay(Capsule().stroke(HHTheme.ink.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - Factor detail

struct EconomyFactorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let factor: EconomyFactor
    let economy: ValleyEconomy

    private var reading: EconomyFactorReading { economy.reading(for: factor) }

    private var feedsInto: [EconomyFactor] {
        EconomyFactor.allCases.filter { $0.dependencies.contains(factor) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: factor.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                colors: [HHTheme.forest, HHTheme.leaf],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(factor.title)
                            .font(.hhTitle(20))
                            .foregroundStyle(HHTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(factor.category.title) · \(factor.unlockHint)")
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }

                CozyCard(padding: 13) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(reading.valueText)
                                .font(.hhHeadline(16))
                                .foregroundStyle(HHTheme.ink)
                            Spacer(minLength: 0)
                            Text(reading.status)
                                .font(.hhCaption(10))
                                .foregroundStyle(HHTheme.forest)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(HHTheme.forest.opacity(0.1), in: Capsule())
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(HHTheme.paperDeep)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [HHTheme.leaf, HHTheme.forest],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(4, geo.size.width * CGFloat(reading.score / 100)))
                            }
                        }
                        .frame(height: 8)
                        Text(reading.trend > 0.0001 ? "Rising" : (reading.trend < -0.0001 ? "Falling" : "Flat"))
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                    }
                }

                Text(factor.explanation)
                    .font(.hhBody(14))
                    .foregroundStyle(HHTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if !factor.dependencies.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("FED BY")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                        FlowChips(factors: factor.dependencies, economy: economy)
                    }
                }

                if !feedsInto.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("FEEDS INTO")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                        FlowChips(factors: Array(feedsInto.prefix(8)), economy: economy)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(HHTheme.terracotta)
                    Text("Changes here travel through prices, wages, confidence, and public trust before returning to the farm.")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(11)
                .background(HHTheme.terracotta.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(18)
        }
        .background(HHTheme.backgroundGradient.ignoresSafeArea())
    }
}

struct FlowChips: View {
    let factors: [EconomyFactor]
    let economy: ValleyEconomy

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(factors) { factor in
                    HStack(spacing: 4) {
                        Image(systemName: factor.icon)
                            .font(.system(size: 9, weight: .bold))
                        Text(factor.shortTitle)
                            .font(.hhCaption(9.5))
                    }
                    .foregroundStyle(factor.isUnlocked(level: economy.lastKnownLevel) ? HHTheme.forest : HHTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        (factor.isUnlocked(level: economy.lastKnownLevel) ? HHTheme.forest : HHTheme.muted)
                            .opacity(0.09),
                        in: Capsule()
                    )
                }
            }
        }
    }
}

// MARK: - Guide

struct EconomyGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("The valley economy")
                            .font(.hhTitle(24))
                            .foregroundStyle(HHTheme.ink)
                        Text("A farm is never just a farm.")
                            .font(.hhCaption(12))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }

                Text("Each morning the simulation runs one linked circuit: weather and soil set yields; yields, imports, and firm output set supply; supply and household demand set prices; prices feed wages, confidence, interest, and policy; policy changes public services, taxes, health, education, and the next day's soil. Nothing is a standalone slider.")
                    .font(.hhBody(13))
                    .foregroundStyle(HHTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(EconomyTier.allCases) { tier in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: tier.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HHTheme.forest)
                            .frame(width: 30, height: 30)
                            .background(HHTheme.forest.opacity(0.09), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Text(tier.title)
                                    .font(.hhHeadline(13))
                                    .foregroundStyle(HHTheme.ink)
                                Text("LV \(tier.unlockLevel)")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(HHTheme.goldDeep)
                            }
                            Text(tier.blurb)
                                .font(.hhCaption(11))
                                .foregroundStyle(HHTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            let factors = EconomyFactor.allCases.filter { $0.minimumLevel == tier.unlockLevel }
                            if !factors.isEmpty {
                                Text(factors.map(\.shortTitle).joined(separator: " · "))
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HHTheme.forest)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(HHTheme.paper.opacity(0.76), in: RoundedRectangle(cornerRadius: 13))
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("THE SHORT VERSION")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                    Text("Keep soil and water healthy → protect yields → keep food affordable → support wages and confidence → invest in education, roads, and clean energy → grow productivity without letting pollution, inequality, or debt compound into the next crisis.")
                        .font(.hhCaption(12))
                        .foregroundStyle(HHTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(HHTheme.gold.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
            }
            .padding(18)
        }
        .background(HHTheme.backgroundGradient.ignoresSafeArea())
    }
}
#endif
