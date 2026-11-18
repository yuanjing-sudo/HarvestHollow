#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Hollow Exchange

/// The live share market. Prices are tied to each firm's profit, debt,
/// reputation, and fraud risk, and rise or fall every in-game morning.
struct LedgerExchangeSection: View {
    @EnvironmentObject private var store: GameStore
    let onSelect: (BusinessListing) -> Void

    private var economy: ValleyEconomy { store.state.economy }
    private var market: InvestmentMarket { economy.investmentMarket }

    var body: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .bottom) {
                    SectionHeader(
                        "Hollow Exchange",
                        subtitle: "Share prices move with real firm fundamentals. Buy, sell, or use margin.",
                        icon: "chart.line.uptrend.xyaxis",
                        accent: HHTheme.goldDeep
                    )
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("HVI")
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                        Text(String(format: "%.1f", market.marketIndex))
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.ink)
                    }
                }

                marketPulse
                portfolioSummary
                realizedLine

                if let notice = market.lastNotice {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: market.forcedLiquidations > 0 ? "exclamationmark.triangle.fill" : "bell.badge.fill")
                            .foregroundStyle(market.forcedLiquidations > 0 ? HHTheme.terracotta : HHTheme.goldDeep)
                        Text(notice)
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .background(
                        (market.forcedLiquidations > 0 ? HHTheme.terracotta : HHTheme.gold).opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }

                if market.holdings.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundStyle(HHTheme.leaf)
                        Text("No positions yet. Tap a business below to inspect its books before buying a slice.")
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(9)
                    .background(HHTheme.leaf.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR POSITIONS")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                        ForEach(market.holdings) { holding in
                            if let listing = market.listing(for: holding.businessID) {
                                Button {
                                    onSelect(listing)
                                } label: {
                                    LedgerHoldingRow(holding: holding, listing: listing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack(alignment: .bottom) {
                    Text("VALLEY COMPETITORS")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                    Spacer(minLength: 0)
                    Text("\(market.listings.count) listed")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(market.listings) { listing in
                        Button {
                            onSelect(listing)
                        } label: {
                            LedgerMarketCard(listing: listing)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 7) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HHTheme.goldDeep)
                    Text(leverageCopy)
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text("\(store.state.coins)c free")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.goldDeep)
                }
                .padding(9)
                .background(HHTheme.gold.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var leverageCopy: String {
        if economy.maxInvestmentLeverage >= 3 {
            return "Margin up to 3x. Interest accrues daily; a 25% equity buffer triggers a forced sale."
        }
        if economy.maxInvestmentLeverage >= 2 {
            return "Margin up to 2x. Reach level 8 for 3x leverage and forensic audits."
        }
        return "Leverage unlocks at level 4. Until then every purchase is cash-only."
    }

    private var marketPulse: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(market.todayChange >= 0 ? "RISING" : "FALLING")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(market.todayChange >= 0 ? HHTheme.forest : HHTheme.terracotta)
                    Text("\(market.todayChange >= 0 ? "+" : "")\(String(format: "%.2f", market.todayChange))")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(market.todayChange >= 0 ? HHTheme.forest : HHTheme.terracotta)
                }
                Text(sentimentTitle)
                    .font(.hhHeadline(13))
                    .foregroundStyle(HHTheme.ink)
                Text("Sentiment \(Int((market.sentiment * 100).rounded()))% · \(market.openPositions) open")
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
            }
            .frame(width: 118, alignment: .leading)
            LedgerPriceChart(
                values: market.marketHistory,
                tint: market.todayChange >= 0 ? HHTheme.forest : HHTheme.terracotta,
                height: 54
            )
        }
        .padding(9)
        .background(HHTheme.paper.opacity(0.8), in: RoundedRectangle(cornerRadius: 13))
    }

    private var sentimentTitle: String {
        switch market.sentiment {
        case ..<0.25: return "Fear in the square"
        case ..<0.45: return "Cautious trading"
        case ..<0.65: return "Steady confidence"
        case ..<0.82: return "Optimistic valley"
        default: return "Euphoric market"
        }
    }

    private var portfolioSummary: some View {
        HStack(spacing: 7) {
            LedgerMiniStat(
                title: "PORTFOLIO",
                value: "\(Int(market.marketValue.rounded()))c",
                tint: HHTheme.forest
            )
            LedgerMiniStat(
                title: "EQUITY",
                value: "\(Int(market.equity.rounded()))c",
                tint: HHTheme.goldDeep
            )
            LedgerMiniStat(
                title: "P&L",
                value: "\(market.unrealizedProfit >= 0 ? "+" : "")\(Int(market.unrealizedProfit.rounded()))c",
                tint: market.unrealizedProfit >= 0 ? HHTheme.forest : HHTheme.terracotta
            )
            LedgerMiniStat(
                title: "MARGIN",
                value: "\(String(format: "%.1f", market.leverage))x",
                tint: market.marginDebt > 0 ? HHTheme.terracotta : HHTheme.muted
            )
        }
    }

    private var realizedLine: some View {
        HStack(spacing: 8) {
            Text("Realized \(market.realizedProfit >= 0 ? "+" : "")\(Int(market.realizedProfit.rounded()))c")
                .foregroundStyle(market.realizedProfit >= 0 ? HHTheme.forest : HHTheme.terracotta)
            Text("· fees \(Int(market.totalFees.rounded()))c")
                .foregroundStyle(HHTheme.muted)
            Text("· dividends \(Int(market.totalDividends.rounded()))c")
                .foregroundStyle(HHTheme.goldDeep)
            Spacer(minLength: 0)
        }
        .font(.system(size: 8, weight: .semibold, design: .rounded))
    }
}

struct LedgerMarketCard: View {
    let listing: BusinessListing

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: listing.kind.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HHTheme.lavender)
                Text(listing.name)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(listing.analystRating.uppercased())
                    .font(.system(size: 6.5, weight: .black, design: .rounded))
                    .foregroundStyle(ratingTint)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(ratingTint.opacity(0.1), in: Capsule())
            }
            Text("\(listing.kind.title) · \(listing.fundamentals.employees) staff")
                .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                .foregroundStyle(HHTheme.muted)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(String(format: "%.2f", listing.sharePrice))c")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                Text("\(listing.dailyChangePercent >= 0 ? "+" : "")\(String(format: "%.1f", listing.dailyChangePercent * 100))%")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(listing.dailyChangePercent >= 0 ? HHTheme.forest : HHTheme.terracotta)
                Spacer(minLength: 0)
            }

            LedgerPriceChart(
                values: listing.priceHistory,
                tint: listing.dailyChangePercent >= 0 ? HHTheme.forest : HHTheme.terracotta,
                height: 27
            )

            HStack(spacing: 5) {
                Text("P/E \((listing.priceToEarnings.map { String(format: "%.1f", $0) } ?? "—"))")
                Text("Profit \(Int(listing.fundamentals.profit))c")
                Text("Risk \(Int((listing.fundamentals.fraudRisk * 100).rounded()))%")
            }
            .font(.system(size: 7, weight: .semibold, design: .rounded))
            .foregroundStyle(HHTheme.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(HHTheme.paper.opacity(0.94), in: RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(ratingTint.opacity(0.16), lineWidth: 1)
        )
    }

    private var ratingTint: Color {
        switch listing.analystRating {
        case "Buy": return HHTheme.forest
        case "Hold": return HHTheme.goldDeep
        case "Sell", "Avoid": return HHTheme.terracotta
        default: return HHTheme.muted
        }
    }
}

struct LedgerHoldingRow: View {
    let holding: InvestmentHolding
    let listing: BusinessListing

    private var equity: Double { holding.equity(price: listing.sharePrice) }
    private var pnl: Double { holding.unrealized(price: listing.sharePrice) }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: listing.kind.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(HHTheme.goldDeep)
                .frame(width: 26, height: 26)
                .background(HHTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 1) {
                Text(listing.name)
                    .font(.hhCaption(11))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                Text("\(Int(holding.shares)) shares · \(String(format: "%.1f", holding.leverage(price: listing.sharePrice)))x")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(equity.rounded()))c")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                Text("\(pnl >= 0 ? "+" : "")\(Int(pnl.rounded()))c")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(pnl >= 0 ? HHTheme.forest : HHTheme.terracotta)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(HHTheme.muted)
        }
        .padding(7)
        .background(HHTheme.paperDeep.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Chart

struct LedgerPriceChart: View {
    let values: [Double]
    let tint: Color
    var height: CGFloat = 54

    var body: some View {
        Canvas { context, size in
            guard values.count >= 2 else {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: size.height / 2))
                line.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                context.stroke(line, with: .color(tint.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                return
            }
            let low = values.min() ?? 0
            let high = values.max() ?? 1
            let span = max(0.001, high - low)
            let points = values.enumerated().map { index, value in
                CGPoint(
                    x: size.width * CGFloat(index) / CGFloat(values.count - 1),
                    y: size.height - size.height * CGFloat((value - low) / span)
                )
            }
            var area = Path()
            area.move(to: CGPoint(x: 0, y: size.height))
            area.addLine(to: points[0])
            for point in points.dropFirst() { area.addLine(to: point) }
            area.addLine(to: CGPoint(x: size.width, y: size.height))
            area.closeSubpath()
            context.fill(
                area,
                with: .linearGradient(
                    Gradient(colors: [tint.opacity(0.24), tint.opacity(0.01)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
            var line = Path()
            line.move(to: points[0])
            for point in points.dropFirst() { line.addLine(to: point) }
            context.stroke(
                line,
                with: .color(tint),
                style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
            )
            if let last = points.last {
                context.fill(
                    Path(ellipseIn: CGRect(x: last.x - 2, y: last.y - 2, width: 4, height: 4)),
                    with: .color(tint)
                )
            }
        }
        .frame(height: height)
    }
}

// MARK: - Crime and justice

struct LedgerJusticeSection: View {
    @EnvironmentObject private var store: GameStore
    let onInspect: (BusinessListing) -> Void

    private var economy: ValleyEconomy { store.state.economy }
    private var ledger: JusticeLedger { economy.justiceLedger }
    private var market: InvestmentMarket { economy.investmentMarket }

    var body: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    "Crime & fraud",
                    subtitle: "The constable, tax office, and forensic auditors all work the same crooked ledgers.",
                    icon: "shield.lefthalf.filled",
                    accent: HHTheme.terracotta
                )

                HStack(spacing: 7) {
                    LedgerMiniStat(
                        title: "OPEN CASES",
                        value: "\(ledger.openCases)",
                        tint: ledger.openCases > 0 ? HHTheme.terracotta : HHTheme.forest
                    )
                    LedgerMiniStat(
                        title: "CONVICTIONS",
                        value: "\(ledger.convictions)",
                        tint: HHTheme.forest
                    )
                    LedgerMiniStat(
                        title: "LOSSES",
                        value: "\(Int(ledger.totalLoss.rounded()))c",
                        tint: HHTheme.soil
                    )
                    LedgerMiniStat(
                        title: "FINES",
                        value: "\(Int(ledger.totalFines.rounded()))c",
                        tint: HHTheme.goldDeep
                    )
                }

                if ledger.incidents.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(HHTheme.forest)
                        Text("No open incidents. Low crime and healthy public services keep the ledgers clean.")
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(9)
                    .background(HHTheme.forest.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 6) {
                        ForEach(ledger.incidents.prefix(6)) { incident in
                            LedgerIncidentRow(
                                incident: incident,
                                listing: incident.businessID.flatMap { market.listing(for: $0) },
                                onInspect: onInspect
                            )
                        }
                    }
                }

                if let risky = market.listings
                    .filter({ !$0.isBankrupt })
                    .max(by: { $0.fundamentals.fraudRisk < $1.fundamentals.fraudRisk }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundStyle(HHTheme.goldDeep)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Highest fraud risk: \(risky.name)")
                                .font(.hhCaption(11))
                                .foregroundStyle(HHTheme.ink)
                            Text("Risk \(Int((risky.fundamentals.fraudRisk * 100).rounded()))% · \(risky.fundamentals.riskLabel)")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(HHTheme.muted)
                        }
                        Spacer(minLength: 0)
                        Button("Inspect") { onInspect(risky) }
                            .font(.hhCaption(10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(HHTheme.terracotta, in: Capsule())
                            .buttonStyle(.plain)
                    }
                    .padding(9)
                    .background(HHTheme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                Text(economy.investmentAuditUnlocked
                    ? "Forensic audits are open. Fund one from a business's books to uncover hidden losses and earn a recovery bounty."
                    : "Forensic audits unlock at level 8. Until then, watch fraud risk and the court record before buying.")
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct LedgerIncidentRow: View {
    let incident: CrimeIncident
    let listing: BusinessListing?
    let onInspect: (BusinessListing) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: incident.kind.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(incident.status == .unsolved ? HHTheme.muted : HHTheme.terracotta)
                .frame(width: 28, height: 28)
                .background(
                    (incident.status == .unsolved ? HHTheme.muted : HHTheme.terracotta).opacity(0.1),
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(incident.title)
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("D\(incident.day)")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
                Text(incident.detail)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 5) {
                    Text(incident.status.title.uppercased())
                        .font(.system(size: 6.5, weight: .black, design: .rounded))
                        .foregroundStyle(statusTint)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(statusTint.opacity(0.1), in: Capsule())
                    Text("Loss \(Int(incident.loss.rounded()))c")
                    if incident.fine > 0 {
                        Text("Fine \(Int(incident.fine.rounded()))c")
                    }
                }
                .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
            if let listing {
                Button("Books") { onInspect(listing) }
                    .font(.hhCaption(9))
                    .foregroundStyle(HHTheme.terracotta)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(HHTheme.terracotta.opacity(0.08), in: Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(HHTheme.paperDeep.opacity(0.35), in: RoundedRectangle(cornerRadius: 11))
    }

    private var statusTint: Color {
        switch incident.status {
        case .reported: return HHTheme.goldDeep
        case .investigating: return HHTheme.sky
        case .prosecuted: return HHTheme.forest
        case .unsolved: return HHTheme.muted
        }
    }
}
#endif
