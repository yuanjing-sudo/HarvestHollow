#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Candlestick chart

/// A real OHLC chart: candles, volume, a moving average and the last price. It
/// falls back to a line when there is only one bar of history.
struct LedgerCandleChart: View {
    let bars: [PriceBar]
    var height: CGFloat = 128
    var showVolume: Bool = true

    private var visible: [PriceBar] { Array(bars.suffix(32)) }

    var body: some View {
        Canvas { context, size in
            let data = visible
            guard data.count >= 2 else {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: size.height / 2))
                line.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                context.stroke(line, with: .color(HHTheme.muted.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                return
            }
            let volumeHeight = showVolume ? size.height * 0.22 : 0
            let chartHeight = size.height - volumeHeight - 4
            let highest = data.map(\.high).max() ?? 1
            let lowest = data.map(\.low).min() ?? 0
            let span = max(0.0001, highest - lowest)
            let step = size.width / CGFloat(data.count)
            let bodyWidth = max(1.4, step * 0.58)

            func y(_ value: Double) -> CGFloat {
                chartHeight - chartHeight * CGFloat((value - lowest) / span)
            }

            // Grid lines at a quarter, half and three quarters of the range.
            for fraction in [0.25, 0.5, 0.75] {
                var grid = Path()
                let gridY = chartHeight * CGFloat(fraction)
                grid.move(to: CGPoint(x: 0, y: gridY))
                grid.addLine(to: CGPoint(x: size.width, y: gridY))
                context.stroke(grid, with: .color(HHTheme.muted.opacity(0.1)), style: StrokeStyle(lineWidth: 0.6))
            }

            for (index, bar) in data.enumerated() {
                let centerX = step * CGFloat(index) + step / 2
                let tint = bar.isUp ? HHTheme.forest : HHTheme.terracotta
                var wick = Path()
                wick.move(to: CGPoint(x: centerX, y: y(bar.high)))
                wick.addLine(to: CGPoint(x: centerX, y: y(bar.low)))
                context.stroke(wick, with: .color(tint.opacity(0.75)), style: StrokeStyle(lineWidth: 0.9))

                let openY = y(bar.open)
                let closeY = y(bar.close)
                let top = min(openY, closeY)
                let body = CGRect(
                    x: centerX - bodyWidth / 2,
                    y: top,
                    width: bodyWidth,
                    height: max(1.1, abs(closeY - openY))
                )
                context.fill(Path(body), with: .color(tint.opacity(bar.isUp ? 0.85 : 0.75)))

                if showVolume {
                    let volumeMax = max(1, data.map(\.volume).max() ?? 1)
                    let volumeBar = CGRect(
                        x: centerX - bodyWidth / 2,
                        y: size.height - volumeHeight * CGFloat(bar.volume / volumeMax),
                        width: bodyWidth,
                        height: volumeHeight * CGFloat(bar.volume / volumeMax)
                    )
                    context.fill(Path(volumeBar), with: .color(tint.opacity(0.28)))
                }
            }

            // Twenty-bar moving average.
            let window = min(20, data.count)
            let closes = data.map(\.close)
            var averagePath = Path()
            for index in 0..<data.count {
                let start = max(0, index - window + 1)
                let slice = closes[start...index]
                let average = slice.reduce(0, +) / Double(slice.count)
                let point = CGPoint(x: step * CGFloat(index) + step / 2, y: y(average))
                if index == 0 {
                    averagePath.move(to: point)
                } else {
                    averagePath.addLine(to: point)
                }
            }
            context.stroke(
                averagePath,
                with: .color(HHTheme.goldDeep.opacity(0.8)),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
            )

            if let last = data.last {
                var priceLine = Path()
                priceLine.move(to: CGPoint(x: 0, y: y(last.close)))
                priceLine.addLine(to: CGPoint(x: size.width, y: y(last.close)))
                context.stroke(
                    priceLine,
                    with: .color((last.isUp ? HHTheme.forest : HHTheme.terracotta).opacity(0.45)),
                    style: StrokeStyle(lineWidth: 0.8, dash: [2, 3])
                )
            }
        }
        .frame(height: height)
        .overlay(alignment: .topLeading) {
            if let last = visible.last {
                HStack(spacing: 5) {
                    Text("O \(String(format: "%.2f", last.open))")
                    Text("H \(String(format: "%.2f", last.high))")
                    Text("L \(String(format: "%.2f", last.low))")
                    Text("C \(String(format: "%.2f", last.close))")
                }
                .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                .foregroundStyle(HHTheme.muted)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(HHTheme.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

// MARK: - Regime strip

struct LedgerRegimeStrip: View {
    let market: InvestmentMarket

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: market.regime.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(regimeTint)
                .frame(width: 30, height: 30)
                .background(regimeTint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(market.regime.title)
                        .font(.hhHeadline(13))
                        .foregroundStyle(HHTheme.ink)
                    Text(String(format: "%+.2f%%", market.todayChangePercent * 100))
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(market.todayChangePercent >= 0 ? HHTheme.forest : HHTheme.terracotta)
                }
                Text("Vol \(Int(market.volatilityIndex)) · breadth \(Int((market.breadth * 100).rounded()))% · \(market.gainers) up / \(market.losers) down · \(market.sessionsPlayed) sessions")
                    .font(.hhCaption(9))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if let rumour = market.rumour {
                    Text(rumour)
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.ink.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(HHTheme.paperDeep.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private var regimeTint: Color {
        switch market.regime {
        case .crash: return HHTheme.terracotta
        case .bear: return HHTheme.soil
        case .choppy: return HHTheme.goldDeep
        case .bull: return HHTheme.forest
        case .mania: return HHTheme.lavender
        }
    }
}

// MARK: - Market factors

/// The exchange's factor board. Every line is a real input to today's prices,
/// and the impact column is the basis points it added or removed.
struct LedgerFactorPanel: View {
    let book: MarketFactorBook
    @State private var expanded = false
    @State private var group: MarketFactorGroup?

    var body: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeader(
                    "Market factors",
                    subtitle: "\(book.readouts.count) inputs priced into today's tape. \(book.bulls) bullish, \(book.bears) bearish.",
                    icon: "square.grid.2x2.fill",
                    accent: HHTheme.lavender
                )

                HStack(spacing: 7) {
                    LedgerMiniStat(
                        title: "BULLS",
                        value: "\(book.bulls)",
                        tint: HHTheme.forest
                    )
                    LedgerMiniStat(
                        title: "BEARS",
                        value: "\(book.bears)",
                        tint: HHTheme.terracotta
                    )
                    LedgerMiniStat(
                        title: "TOTAL PULL",
                        value: String(format: "%+.0fbp", book.indexImpactBps),
                        tint: book.indexImpactBps >= 0 ? HHTheme.forest : HHTheme.terracotta
                    )
                    LedgerMiniStat(
                        title: "REGIME",
                        value: book.regime.title,
                        tint: HHTheme.goldDeep
                    )
                }

                VStack(spacing: 5) {
                    ForEach(book.strongestDrivers) { readout in
                        LedgerFactorRow(readout: readout)
                    }
                }

                if expanded {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Button {
                                group = nil
                            } label: {
                                LedgerFactorChip(
                                    title: "All",
                                    tilt: book.indexImpactBps,
                                    selected: group == nil
                                )
                            }
                            .buttonStyle(.plain)
                            ForEach(MarketFactorGroup.allCases) { candidate in
                                Button {
                                    group = candidate
                                } label: {
                                    LedgerFactorChip(
                                        title: candidate.title,
                                        tilt: book.groupTilt(candidate),
                                        selected: group == candidate
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    let shown = group.map { book.readouts(in: $0) } ?? book.readouts
                    VStack(spacing: 4) {
                        ForEach(shown) { readout in
                            LedgerFactorRow(readout: readout)
                        }
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    Text(expanded ? "Hide the full factor book" : "Open the full factor book (\(book.readouts.count))")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.lavender)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(HHTheme.lavender.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct LedgerFactorRow: View {
    let readout: MarketFactorReadout

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: readout.group.icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(readout.title)
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(readout.valueText)
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(1)
                }
                Text(readout.note)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(readout.impactLabel)
                .font(.system(size: 8.5, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(6)
        .background(HHTheme.paperDeep.opacity(0.3), in: RoundedRectangle(cornerRadius: 9))
    }

    private var tint: Color {
        readout.isBullish ? HHTheme.forest : HHTheme.terracotta
    }
}

private struct LedgerFactorChip: View {
    let title: String
    let tilt: Double
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 8.5, weight: .black, design: .rounded))
                .foregroundStyle(selected ? .white : HHTheme.ink)
                .lineLimit(1)
            Text(String(format: "%+.0fbp", tilt))
                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? .white.opacity(0.85) : (tilt >= 0 ? HHTheme.forest : HHTheme.terracotta))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            selected ? HHTheme.lavender : HHTheme.paperDeep.opacity(0.5),
            in: RoundedRectangle(cornerRadius: 9)
        )
    }
}

// MARK: - Policy pass-through

/// Shows, in coins and in percent, what the current tax and policy mix is doing
/// to the valley's firms and households. This is the panel that explains why a
/// tax rise actually moves share prices.
struct LedgerPolicyImpactCard: View {
    let report: PolicyImpactReport?
    let forecast: ElectionForecast

    var body: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeader(
                    "Policy pass-through",
                    subtitle: report?.verdict ?? "The exchange has not priced a policy change yet.",
                    icon: "building.columns.fill",
                    accent: report.map { $0.indexPercent >= 0 ? HHTheme.forest : HHTheme.terracotta } ?? HHTheme.muted
                )

                if let report {
                    HStack(spacing: 7) {
                        LedgerMiniStat(
                            title: "INDEX EFFECT",
                            value: String(format: "%+.2f%%", report.indexPercent),
                            tint: report.indexPercent >= 0 ? HHTheme.forest : HHTheme.terracotta
                        )
                        LedgerMiniStat(
                            title: "COINS / DAY",
                            value: "\(Int(report.dailyCoinImpact.rounded()))c",
                            tint: report.dailyCoinImpact >= 0 ? HHTheme.forest : HHTheme.terracotta
                        )
                        LedgerMiniStat(
                            title: "PRICED AT",
                            value: "tax \(Int((report.baseline.taxRate * 100).rounded()))%",
                            tint: HHTheme.goldDeep
                        )
                    }

                    VStack(spacing: 4) {
                        ForEach(report.lines) { line in
                            HStack(alignment: .top, spacing: 7) {
                                Image(systemName: line.kind.icon)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(line.isBenefit ? HHTheme.forest : HHTheme.terracotta)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(line.title)
                                        .font(.hhCaption(10))
                                        .foregroundStyle(HHTheme.ink)
                                        .lineLimit(1)
                                    Text(line.detail)
                                        .font(.system(size: 8, weight: .medium, design: .rounded))
                                        .foregroundStyle(HHTheme.muted)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(line.valueText)
                                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                                        .foregroundStyle(line.isBenefit ? HHTheme.forest : HHTheme.terracotta)
                                        .lineLimit(1)
                                    Text(String(format: "%+.2f%%", line.pricePercent))
                                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(HHTheme.muted)
                                }
                            }
                            .padding(6)
                            .background(HHTheme.paperDeep.opacity(0.3), in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(HHTheme.sky)
                        Text("Next vote in \(forecast.daysToVote) days")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.ink)
                        Spacer(minLength: 0)
                    }
                    Text(forecast.note)
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(forecast.ordered, id: \.party) { entry in
                        HStack(spacing: 6) {
                            Text(entry.party.shortTitle)
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundStyle(HHTheme.ink)
                                .frame(width: 58, alignment: .leading)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(HHTheme.paperDeep)
                                    Capsule()
                                        .fill(entry.party == forecast.leader ? HHTheme.sky : HHTheme.sky.opacity(0.4))
                                        .frame(width: max(3, proxy.size.width * CGFloat(entry.share)))
                                }
                            }
                            .frame(height: 5)
                            Text("\(Int((entry.share * 100).rounded()))%")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(HHTheme.muted)
                                .frame(width: 26, alignment: .trailing)
                        }
                    }
                }
                .padding(8)
                .background(HHTheme.sky.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
            }
        }
    }
}

// MARK: - Signals

struct LedgerSignalGrid: View {
    let listing: BusinessListing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("RESEARCH SHEET")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                Spacer(minLength: 0)
                Text("\(listing.bullishSignals)/\(listing.signals.count) bullish · \(listing.verdict)")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(listing.bullishSignals >= 6 ? HHTheme.forest : listing.bullishSignals >= 4 ? HHTheme.goldDeep : HHTheme.terracotta)
            }
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                spacing: 6
            ) {
                ForEach(listing.signals) { signal in
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 3) {
                            Image(systemName: signal.isBullish ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(signal.isBullish ? HHTheme.forest : HHTheme.terracotta)
                            Text(signal.title)
                                .font(.system(size: 7, weight: .black, design: .rounded))
                                .foregroundStyle(HHTheme.muted)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        Text(signal.valueText)
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.ink)
                        Text(signal.detail)
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((signal.isBullish ? HHTheme.forest : HHTheme.terracotta).opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Competitor board

struct LedgerCompetitorBoard: View {
    let profiles: [CompetitorProfile]
    let onSelect: (UUID) -> Void

    private var ranked: [CompetitorProfile] {
        profiles.sorted { $0.threat > $1.threat }
    }

    var body: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeader(
                    "Competitor intelligence",
                    subtitle: "Every rival's playbook, market share and last move. Tap one to inspect its books.",
                    icon: "person.3.fill",
                    accent: HHTheme.lavender
                )
                if profiles.isEmpty {
                    Text("No rivals listed yet. Growth attracts competitors soon enough.")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                } else {
                    VStack(spacing: 7) {
                        ForEach(ranked.prefix(8)) { profile in
                            Button {
                                onSelect(profile.businessID)
                            } label: {
                                LedgerCompetitorCard(profile: profile)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct LedgerCompetitorCard: View {
    let profile: CompetitorProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: profile.kind.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HHTheme.lavender)
                    .frame(width: 24, height: 24)
                    .background(HHTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(profile.name)
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.ink)
                            .lineLimit(1)
                        Text(profile.strategy.title.uppercased())
                            .font(.system(size: 6.5, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.lavender)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(HHTheme.lavender.opacity(0.12), in: Capsule())
                    }
                    Text("\(profile.threatLabel) · \(profile.momentumLine) · \(profile.employees) staff · \(profile.openRoles) open roles")
                        .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int((profile.marketShare * 100).rounded()))%")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.ink)
                    Text("SHARE")
                        .font(.system(size: 6, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(HHTheme.muted)
            }

            Text(profile.dossier)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(HHTheme.muted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                LedgerTinyGauge(title: "BRAND", value: profile.brand, tint: HHTheme.goldDeep)
                LedgerTinyGauge(title: "R&D", value: profile.rndFocus, tint: HHTheme.sky)
                LedgerTinyGauge(title: "SUPPLY", value: profile.supplySecurity, tint: HHTheme.leaf)
                LedgerTinyGauge(title: "DEBT", value: profile.debtLoad, tint: HHTheme.terracotta)
            }

            if let latest = profile.actions.first {
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: latest.kind.icon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(HHTheme.forest)
                    Text("D\(latest.day) · \(latest.detail)")
                        .font(.system(size: 7.5, weight: .medium, design: .rounded))
                        .foregroundStyle(HHTheme.ink.opacity(0.75))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(5)
                .background(HHTheme.forest.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
            }
        }
        .padding(8)
        .background(HHTheme.paper.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct LedgerTinyGauge: View {
    let title: String
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 6, weight: .black, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(HHTheme.paperDeep)
                    Capsule()
                        .fill(tint.opacity(0.75))
                        .frame(width: max(2, proxy.size.width * CGFloat(hhClamp(value, 0, 1))))
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Short trading

/// The short-side trade ticket. Kept separate from the long ticket so the
/// collateral, borrow fee and liquidation price are always visible.
struct LedgerShortTradeCard: View {
    let listing: BusinessListing
    let economy: ValleyEconomy
    let coins: Int
    let onOpen: (Double, Double) -> InvestmentExecution
    let onCover: (Double) -> InvestmentExecution

    @State private var shares: Double = 3
    @State private var leverage: Double = 1
    @State private var message: String?
    @State private var messagePositive = true

    private var position: ShortPosition? {
        economy.investmentMarket.short(for: listing.businessID)
    }

    private var maxLeverage: Double { economy.maxShortLeverage }

    private var quantity: Double { max(1, floor(shares)) }

    private var collateral: Double {
        (quantity * listing.sharePrice / max(1, leverage)).rounded(.up)
    }

    private var fee: Double {
        max(1, (quantity * listing.sharePrice * 0.006).rounded(.up))
    }

    private var borrowRate: Double {
        let tier = LeverageLadder.tier(for: max(1, leverage))
        return hhClamp(0.045 + tier.annualBorrowRate + listing.fundamentals.fraudRisk * 0.25, 0.02, 0.9)
    }

    private var projectedLiquidation: Double {
        let maintenance = LeverageLadder.maintenanceRatio(for: max(1, leverage))
        let denominator = quantity * (1 + maintenance)
        guard denominator > 0 else { return 0 }
        return max(0.01, (collateral + quantity * listing.sharePrice) / denominator)
    }

    var body: some View {
        CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeader(
                    "Trade the downside",
                    subtitle: economy.shortSellingUnlocked
                        ? "Borrow shares, sell them now, buy them back cheaper. Losses are bounded by your collateral."
                        : "Short selling unlocks at level 4 with the Village tier.",
                    icon: "arrow.down.forward.circle.fill",
                    accent: HHTheme.terracotta
                )

                if let position {
                    HStack(spacing: 7) {
                        LedgerMiniStat(
                            title: "SHORTED",
                            value: "\(Int(position.shares))",
                            tint: HHTheme.terracotta
                        )
                        LedgerMiniStat(
                            title: "COLLATERAL",
                            value: "\(Int(position.collateral.rounded()))c",
                            tint: HHTheme.goldDeep
                        )
                        LedgerMiniStat(
                            title: "P&L",
                            value: "\(position.profit(price: listing.sharePrice) >= 0 ? "+" : "")\(Int(position.profit(price: listing.sharePrice).rounded()))c",
                            tint: position.profit(price: listing.sharePrice) >= 0 ? HHTheme.forest : HHTheme.terracotta
                        )
                        LedgerMiniStat(
                            title: "CALL AT",
                            value: String(format: "%.2f", position.liquidationPrice()),
                            tint: HHTheme.soil
                        )
                    }
                }

                if economy.shortSellingUnlocked {
                    HStack {
                        Text("SHARES")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                        Stepper(value: $shares, in: 1...max(1, Double(coins) * max(1, maxLeverage) / max(0.25, listing.sharePrice)), step: 1) {
                            Text("\(Int(quantity))")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(HHTheme.ink)
                        }
                        .labelsHidden()
                        Spacer(minLength: 0)
                        Text("\(Int(quantity)) shares short")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                    }

                    HStack(spacing: 5) {
                        ForEach(LeverageLadder.tiers, id: \.multiple) { tier in
                            Button {
                                leverage = tier.multiple
                            } label: {
                                VStack(spacing: 1) {
                                    Text("\(Int(tier.multiple))x")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                    Text(tier.isCash ? "cash" : "margin")
                                        .font(.system(size: 6.5, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(leverage == tier.multiple ? .white : (tier.multiple <= maxLeverage ? HHTheme.terracotta : HHTheme.muted))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    leverage == tier.multiple ? HHTheme.terracotta : HHTheme.paperDeep,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(tier.multiple > maxLeverage)
                            .opacity(tier.multiple > maxLeverage ? 0.35 : 1)
                        }
                    }

                    VStack(spacing: 4) {
                        LedgerShortPreviewRow(title: "Collateral", value: "\(Int(collateral))c", tint: HHTheme.goldDeep)
                        LedgerShortPreviewRow(title: "Open fee", value: "\(Int(fee))c")
                        LedgerShortPreviewRow(title: "Borrow fee", value: String(format: "%.1f%% a year", borrowRate * 100), tint: HHTheme.terracotta)
                        LedgerShortPreviewRow(title: "Forced cover near", value: String(format: "%.2f", projectedLiquidation), tint: HHTheme.soil)
                        LedgerShortPreviewRow(
                            title: "Cash needed",
                            value: "\(Int(collateral + fee))c",
                            tint: collateral + fee > Double(coins) ? HHTheme.terracotta : HHTheme.ink
                        )
                    }
                    .padding(8)
                    .background(HHTheme.paperDeep.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))

                    if let message {
                        Text(message)
                            .font(.hhCaption(10))
                            .foregroundStyle(messagePositive ? HHTheme.forest : HHTheme.terracotta)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background((messagePositive ? HHTheme.forest : HHTheme.terracotta).opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                    }

                    HStack(spacing: 7) {
                        Button {
                            let result = onOpen(quantity, max(1, leverage))
                            message = result.message
                            messagePositive = result.success
                        } label: {
                            Text("Short \(Int(quantity))")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(HHTheme.terracotta, in: RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                        .disabled(collateral + fee > Double(coins))

                        if let position {
                            Button {
                                let result = onCover(position.shares)
                                message = result.message
                                messagePositive = result.success
                            } label: {
                                Text("Cover all")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(HHTheme.terracotta)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(HHTheme.terracotta.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct LedgerShortPreviewRow: View {
    let title: String
    let value: String
    var tint: Color = HHTheme.ink

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(tint)
        }
    }
}

struct LedgerShortPositionRow: View {
    let position: ShortPosition
    let listing: BusinessListing

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.down.forward.circle.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(HHTheme.terracotta)
                .frame(width: 26, height: 26)
                .background(HHTheme.terracotta.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(listing.name) short")
                    .font(.hhCaption(11))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                Text("\(Int(position.shares)) borrowed · \(String(format: "%.1f", position.leverage))x · call \(String(format: "%.2f", position.liquidationPrice()))c")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(position.equity(price: listing.sharePrice).rounded()))c")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                Text("\(position.profit(price: listing.sharePrice) >= 0 ? "+" : "")\(Int(position.profit(price: listing.sharePrice).rounded()))c")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(position.profit(price: listing.sharePrice) >= 0 ? HHTheme.forest : HHTheme.terracotta)
            }
        }
        .padding(7)
        .background(HHTheme.paperDeep.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Leverage ladder

struct LedgerLeverageLadder: View {
    let economy: ValleyEconomy

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LEVERAGE LADDER")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            ForEach(LeverageLadder.tiers, id: \.multiple) { tier in
                HStack(spacing: 6) {
                    Text("\(Int(tier.multiple))x")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(tier.minimumLevel <= economy.lastKnownLevel ? HHTheme.ink : HHTheme.muted)
                        .frame(width: 26, alignment: .leading)
                    Text(tier.blurb)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if tier.minimumLevel > economy.lastKnownLevel {
                        Text("Lv \(tier.minimumLevel)")
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                    }
                }
            }
        }
    }
}
#endif
