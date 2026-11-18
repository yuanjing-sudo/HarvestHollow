#if canImport(SwiftUI)
import SwiftUI
import Foundation
import HarvestHollowCore

// MARK: - Business books and trading

struct BusinessDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var businessID: UUID
    @State private var side: InvestmentSide = .buy
    @State private var shareCount: Double = 5
    @State private var leverage: Double = 1
    @State private var message: String?
    @State private var messagePositive = true

    init(businessID: UUID) {
        _businessID = State(initialValue: businessID)
    }

    private var economy: ValleyEconomy { store.state.economy }
    private var market: InvestmentMarket { economy.investmentMarket }
    private var listing: BusinessListing? { market.listing(for: businessID) }
    private var holding: InvestmentHolding? { market.holding(for: businessID) }
    private var firm: AIBusiness? { economy.aiBusinesses.first { $0.id == businessID } }
    private var maxLeverage: Double { economy.maxInvestmentLeverage }
    private var requestedShares: Double { max(1, floor(shareCount)) }
    private var tradeShares: Double {
        side == .sell ? max(0, min(requestedShares, holdingShares)) : requestedShares
    }
    private var quote: Double { listing?.sharePrice ?? 0 }
    private var notional: Double { tradeShares * quote }
    private var fee: Double { max(1, (notional * 0.005).rounded(.up)) }
    private var effectiveLeverage: Double {
        side == .buy ? min(max(1, leverage), maxLeverage) : 1
    }
    private var buyCost: Double {
        (notional / effectiveLeverage + fee).rounded(.up)
    }
    private var marginAdded: Double {
        side == .buy ? max(0, notional - notional / effectiveLeverage) : 0
    }
    private var marginRepayment: Double {
        guard let holding, holding.shares > 0 else { return 0 }
        return holding.marginDebt * min(tradeShares, holding.shares) / holding.shares
    }
    private var sellProceeds: Double {
        floor(max(0, notional - marginRepayment - fee))
    }
    private var holdingShares: Double { holding?.shares ?? 0 }
    private var maxBuyShares: Double {
        max(1, floor(Double(store.state.coins) / max(0.25, quote) * maxLeverage))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                if let listing {
                    priceCard(listing)
                    tradeCard(listing)
                    fundamentalsCard(listing)
                    tradesCard(listing)
                    peersCard(listing)
                    incidentsCard(listing)
                    auditCard(listing)
                } else {
                    notFound
                }
            }
            .padding(18)
        }
        .background(HHTheme.backgroundGradient.ignoresSafeArea())
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 11) {
            if let listing {
                Image(systemName: listing.kind.icon)
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
            } else {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(HHTheme.muted, in: RoundedRectangle(cornerRadius: 15))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(listing?.name ?? "Business books")
                    .font(.hhTitle(21))
                    .foregroundStyle(HHTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let listing {
                    Text("\(listing.kind.title) · \(listing.fundamentals.employees) staff · \(listing.analystRating)")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                }
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
    }

    private var notFound: some View {
        CozyCard(padding: 16) {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(HHTheme.terracotta)
                Text("This business is no longer listed.")
                    .font(.hhHeadline(15))
                    .foregroundStyle(HHTheme.ink)
                Text("Failed firms can leave worthless shares behind. Check the exchange for a surviving competitor.")
                    .font(.hhCaption(11))
                    .foregroundStyle(HHTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func priceCard(_ listing: BusinessListing) -> some View {
        CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("\(String(format: "%.2f", listing.sharePrice))c")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.ink)
                    Text("\(listing.dailyChangePercent >= 0 ? "+" : "")\(String(format: "%.2f", listing.dailyChangePercent * 100))%")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(listing.dailyChangePercent >= 0 ? HHTheme.forest : HHTheme.terracotta)
                    Spacer(minLength: 0)
                    Text(listing.analystRating.uppercased())
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.goldDeep)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(HHTheme.gold.opacity(0.12), in: Capsule())
                }
                LedgerPriceChart(
                    values: listing.priceHistory,
                    tint: listing.dailyChangePercent >= 0 ? HHTheme.forest : HHTheme.terracotta,
                    height: 92
                )
                HStack(spacing: 7) {
                    LedgerMiniStat(title: "MARKET CAP", value: "\(Int(listing.marketCap.rounded()))c", tint: HHTheme.goldDeep)
                    LedgerMiniStat(title: "P/E", value: (listing.priceToEarnings.map { String(format: "%.1f", $0) } ?? "—"), tint: HHTheme.sky)
                    LedgerMiniStat(title: "P/B", value: String(format: "%.1f", listing.priceToBook), tint: HHTheme.lavender)
                    LedgerMiniStat(title: "DIV", value: String(format: "%.1f%%", listing.dividendYield * 100), tint: HHTheme.leaf)
                }
                if let firm {
                    Text("Founded day \(firm.foundedDay) · \(firm.employees) staff · capital \(Int(firm.capital))c")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                }
            }
        }
    }

    private func tradeCard(_ listing: BusinessListing) -> some View {
        CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .bottom) {
                    SectionHeader(
                        "Trade the books",
                        subtitle: "Prices move every morning. Leverage magnifies both sides.",
                        icon: "arrow.left.arrow.right.circle.fill",
                        accent: HHTheme.goldDeep
                    )
                    Spacer(minLength: 0)
                    Text("\(store.state.coins)c free")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.goldDeep)
                }

                if let holding {
                    HStack(spacing: 8) {
                        LedgerMiniStat(
                            title: "SHARES",
                            value: "\(Int(holding.shares))",
                            tint: HHTheme.forest
                        )
                        LedgerMiniStat(
                            title: "EQUITY",
                            value: "\(Int(holding.equity(price: listing.sharePrice).rounded()))c",
                            tint: HHTheme.goldDeep
                        )
                        LedgerMiniStat(
                            title: "P&L",
                            value: "\(holding.unrealized(price: listing.sharePrice) >= 0 ? "+" : "")\(Int(holding.unrealized(price: listing.sharePrice).rounded()))c",
                            tint: holding.unrealized(price: listing.sharePrice) >= 0 ? HHTheme.forest : HHTheme.terracotta
                        )
                        LedgerMiniStat(
                            title: "LEVERAGE",
                            value: String(format: "%.1fx", holding.leverage(price: listing.sharePrice)),
                            tint: holding.marginDebt > 0 ? HHTheme.terracotta : HHTheme.muted
                        )
                    }
                }

                HStack(spacing: 6) {
                    ForEach([InvestmentSide.buy, .sell]) { option in
                        Button {
                            side = option
                            shareCount = 1
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: option == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text(option.title)
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(side == option ? .white : HHTheme.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                side == option
                                    ? (option == .buy ? HHTheme.forest : HHTheme.terracotta)
                                    : HHTheme.paperDeep,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(option == .sell && holding == nil)
                        .opacity(option == .sell && holding == nil ? 0.45 : 1)
                    }
                }

                let shareLimit = side == .sell
                    ? max(1, holdingShares)
                    : max(1, min(999, maxBuyShares))
                HStack {
                    Text("SHARES")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                    Stepper(
                        value: $shareCount,
                        in: 1...shareLimit,
                        step: 1
                    ) {
                        Text("\(Int(min(shareCount, shareLimit)))")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.ink)
                    }
                    .labelsHidden()
                    Spacer(minLength: 0)
                    Text("\(Int(min(shareCount, shareLimit))) shares")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                }

                HStack(spacing: 5) {
                    ForEach([1.0, 5.0, 10.0, 25.0], id: \.self) { amount in
                        Button("\(Int(amount))") {
                            shareCount = min(amount, shareLimit)
                        }
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.forest)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(HHTheme.forest.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        .buttonStyle(.plain)
                    }
                }

                if side == .buy {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("LEVERAGE")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(HHTheme.muted)
                            Spacer(minLength: 0)
                            Text(maxLeverage < 1.5 ? "Cash only" : "Up to \(Int(maxLeverage))x")
                                .font(.hhCaption(9))
                                .foregroundStyle(HHTheme.muted)
                        }
                        HStack(spacing: 5) {
                            ForEach([1.0, 2.0, 3.0], id: \.self) { level in
                                Button {
                                    leverage = level
                                } label: {
                                    VStack(spacing: 1) {
                                        Text("\(Int(level))x")
                                            .font(.system(size: 11, weight: .black, design: .rounded))
                                        Text(level == 1 ? "cash" : "margin")
                                            .font(.system(size: 7, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(leverage == level ? .white : (level <= maxLeverage ? HHTheme.forest : HHTheme.muted))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        leverage == level ? HHTheme.goldDeep : HHTheme.paperDeep,
                                        in: RoundedRectangle(cornerRadius: 9)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(level > maxLeverage)
                                .opacity(level > maxLeverage ? 0.4 : 1)
                            }
                        }
                    }
                }

                VStack(spacing: 4) {
                    if side == .buy {
                        LedgerPreviewRow(title: "Order value", value: "\(Int(notional.rounded()))c")
                        LedgerPreviewRow(title: "Your cash", value: "\(Int(buyCost))c", tint: buyCost > Double(store.state.coins) ? HHTheme.terracotta : HHTheme.ink)
                        LedgerPreviewRow(title: "Borrowed", value: "\(Int(marginAdded))c", tint: marginAdded > 0 ? HHTheme.goldDeep : HHTheme.muted)
                        LedgerPreviewRow(title: "Fee", value: "\(Int(fee))c")
                    } else {
                        LedgerPreviewRow(title: "Gross value", value: "\(Int(notional.rounded()))c")
                        LedgerPreviewRow(title: "Margin repaid", value: "\(Int(marginRepayment.rounded()))c", tint: HHTheme.terracotta)
                        LedgerPreviewRow(title: "Fee", value: "\(Int(fee))c")
                        LedgerPreviewRow(title: "You receive", value: "\(Int(sellProceeds))c", tint: HHTheme.forest)
                    }
                }
                .padding(8)
                .background(HHTheme.paperDeep.opacity(0.4), in: RoundedRectangle(cornerRadius: 11))

                if let message {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: messagePositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(messagePositive ? HHTheme.forest : HHTheme.terracotta)
                        Text(message)
                            .font(.hhCaption(10))
                            .foregroundStyle(messagePositive ? HHTheme.forest : HHTheme.terracotta)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .background((messagePositive ? HHTheme.forest : HHTheme.terracotta).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    executeTrade(listing)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: side == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(side == .buy ? "Buy \(Int(tradeShares)) shares" : "Sell \(Int(tradeShares)) shares")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        side == .buy ? HHTheme.forest : HHTheme.terracotta,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .disabled(side == .buy ? buyCost > Double(store.state.coins) : holdingShares < 1)

                if holding != nil {
                    Button("Sell entire position") {
                        let result = store.sellBusinessShares(businessID: businessID, shares: holdingShares)
                        message = result.message
                        messagePositive = result.success
                        shareCount = 1
                    }
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.terracotta)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func executeTrade(_ listing: BusinessListing) {
        let quantity = tradeShares
        guard quantity >= 1 else {
            message = "Choose at least one share."
            messagePositive = false
            return
        }
        let result: InvestmentExecution
        if side == .buy {
            result = store.buyBusinessShares(
                businessID: listing.businessID,
                shares: quantity,
                leverage: effectiveLeverage
            )
        } else {
            result = store.sellBusinessShares(
                businessID: listing.businessID,
                shares: quantity
            )
        }
        message = result.message
        messagePositive = result.success
        if result.success {
            shareCount = 1
            leverage = 1
        }
    }

    private func fundamentalsCard(_ listing: BusinessListing) -> some View {
        let f = listing.fundamentals
        return CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeader(
                    "The books",
                    subtitle: "Revenue, debt, growth, reputation, and fraud risk explain the chart.",
                    icon: "doc.text.magnifyingglass",
                    accent: HHTheme.forest
                )
                HStack(spacing: 6) {
                    Text(f.healthLabel)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(f.profit >= 0 ? HHTheme.forest : HHTheme.terracotta)
                    Text("·")
                        .foregroundStyle(HHTheme.muted)
                    Text(f.riskLabel)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(f.fraudRisk > 0.3 ? HHTheme.terracotta : HHTheme.forest)
                    Spacer(minLength: 0)
                    Text("Updated day \(f.lastUpdatedDay)")
                        .font(.hhCaption(9))
                        .foregroundStyle(HHTheme.muted)
                }
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                    spacing: 6
                ) {
                    FundamentalCell(title: "REVENUE", value: "\(Int(f.revenue.rounded()))c", tint: HHTheme.forest)
                    FundamentalCell(title: "EXPENSES", value: "\(Int(f.expenses.rounded()))c", tint: HHTheme.terracotta)
                    FundamentalCell(title: "PROFIT", value: "\(f.profit >= 0 ? "+" : "")\(Int(f.profit.rounded()))c", tint: f.profit >= 0 ? HHTheme.forest : HHTheme.terracotta)
                    FundamentalCell(title: "MARGIN", value: "\(Int((f.margin * 100).rounded()))%", tint: f.margin >= 0 ? HHTheme.leaf : HHTheme.terracotta)
                    FundamentalCell(title: "CASH", value: "\(Int(f.cash.rounded()))c", tint: HHTheme.goldDeep)
                    FundamentalCell(title: "DEBT", value: "\(Int(f.debt.rounded()))c", tint: HHTheme.soil)
                    FundamentalCell(title: "BOOK VALUE", value: "\(Int(f.bookValue.rounded()))c", tint: HHTheme.lavender)
                    FundamentalCell(title: "MARKET CAP", value: "\(Int(listing.marketCap.rounded()))c", tint: HHTheme.goldDeep)
                    FundamentalCell(title: "P/E", value: (listing.priceToEarnings.map { String(format: "%.1f", $0) } ?? "—"), tint: HHTheme.sky)
                    FundamentalCell(title: "P/B", value: String(format: "%.1f", listing.priceToBook), tint: HHTheme.lavender)
                    FundamentalCell(title: "GROWTH", value: "\(f.growth >= 0 ? "+" : "")\(Int((f.growth * 100).rounded()))%", tint: f.growth >= 0 ? HHTheme.forest : HHTheme.terracotta)
                    FundamentalCell(title: "MARKET SHARE", value: "\(Int((f.marketShare * 100).rounded()))%", tint: HHTheme.sky)
                    FundamentalCell(title: "REPUTATION", value: "\(Int((f.reputation * 100).rounded()))%", tint: HHTheme.leaf)
                    FundamentalCell(title: "FRAUD RISK", value: "\(Int((f.fraudRisk * 100).rounded()))%", tint: f.fraudRisk > 0.3 ? HHTheme.terracotta : HHTheme.muted)
                    FundamentalCell(title: "EMPLOYEES", value: "\(f.employees)", tint: HHTheme.ink)
                    FundamentalCell(title: "DIVIDEND", value: String(format: "%.1f%%", listing.dividendYield * 100), tint: HHTheme.goldDeep)
                }
                HStack(spacing: 7) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(HHTheme.sky)
                    Text("Profit is revenue minus wages, capital cost, pollution, debt service, and losses. A high chart with falling profit is a warning, not a bargain.")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(HHTheme.sky.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func tradesCard(_ listing: BusinessListing) -> some View {
        let trades = market.trades.filter { $0.businessID == listing.businessID }.prefix(6)
        return CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(
                    "Your trade blotter",
                    subtitle: "Every fill records cash paid, fees, and realized gains or losses.",
                    icon: "list.bullet.rectangle.fill",
                    accent: HHTheme.sky
                )
                if trades.isEmpty {
                    Text("No trades in this business yet.")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                } else {
                    ForEach(trades) { trade in
                        HStack(spacing: 7) {
                            Image(systemName: trade.side == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(trade.side == .buy ? HHTheme.forest : HHTheme.terracotta)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(trade.side.title) \(Int(trade.shares)) @ \(String(format: "%.2f", trade.price))c")
                                    .font(.hhCaption(10))
                                    .foregroundStyle(HHTheme.ink)
                                Text("Day \(trade.day) · \(trade.note.isEmpty ? "market order" : trade.note)")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HHTheme.muted)
                            }
                            Spacer(minLength: 0)
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(trade.cashDelta >= 0 ? "+" : "")\(Int(trade.cashDelta.rounded()))c")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(trade.cashDelta >= 0 ? HHTheme.forest : HHTheme.terracotta)
                                if trade.side == .sell {
                                    Text("P&L \(trade.realizedProfit >= 0 ? "+" : "")\(Int(trade.realizedProfit.rounded()))c")
                                        .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(trade.realizedProfit >= 0 ? HHTheme.forest : HHTheme.terracotta)
                                }
                            }
                        }
                        .padding(7)
                        .background(HHTheme.paperDeep.opacity(0.33), in: RoundedRectangle(cornerRadius: 9))
                    }
                }
            }
        }
    }

    private func peersCard(_ listing: BusinessListing) -> some View {
        let peers = market.listings.filter {
            $0.kind == listing.kind && $0.businessID != listing.businessID && !$0.isBankrupt
        }
        return CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(
                    "Sector peers",
                    subtitle: "Competitors in \(listing.kind.title.lowercased()) compete for the same customers and workers.",
                    icon: "person.3.sequence.fill",
                    accent: HHTheme.lavender
                )
                if peers.isEmpty {
                    Text("No direct competitor listed yet. Healthy demand may attract a new firm.")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(peers) { peer in
                                Button {
                                    businessID = peer.businessID
                                    side = .buy
                                    shareCount = 1
                                    leverage = 1
                                    message = nil
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 4) {
                                            Image(systemName: peer.kind.icon)
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(HHTheme.lavender)
                                            Text(peer.name)
                                                .font(.hhCaption(9.5))
                                                .foregroundStyle(HHTheme.ink)
                                                .lineLimit(1)
                                        }
                                        Text("\(String(format: "%.2f", peer.sharePrice))c · \(peer.dailyChangePercent >= 0 ? "+" : "")\(Int((peer.dailyChangePercent * 100).rounded()))%")
                                            .font(.system(size: 8, weight: .black, design: .rounded))
                                            .foregroundStyle(peer.dailyChangePercent >= 0 ? HHTheme.forest : HHTheme.terracotta)
                                        Text("Profit \(Int(peer.fundamentals.profit))c · risk \(Int((peer.fundamentals.fraudRisk * 100).rounded()))%")
                                            .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                                            .foregroundStyle(HHTheme.muted)
                                            .lineLimit(1)
                                    }
                                    .padding(7)
                                    .frame(width: 136, alignment: .leading)
                                    .background(HHTheme.paper.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func incidentsCard(_ listing: BusinessListing) -> some View {
        let incidents = economy.justiceLedger.incidents.filter { $0.businessID == listing.businessID }
        return CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(
                    "Court record",
                    subtitle: "Fraud, tax cases, and market crimes tied to this business.",
                    icon: "shield.lefthalf.filled",
                    accent: HHTheme.terracotta
                )
                if incidents.isEmpty {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(HHTheme.forest)
                        Text("No incidents on file. A clean record supports a higher share price.")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .padding(8)
                    .background(HHTheme.forest.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                } else {
                    ForEach(incidents.prefix(5)) { incident in
                        HStack(alignment: .top, spacing: 7) {
                            Image(systemName: incident.kind.icon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(HHTheme.terracotta)
                                .frame(width: 24, height: 24)
                                .background(HHTheme.terracotta.opacity(0.1), in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text(incident.title)
                                    .font(.hhCaption(10))
                                    .foregroundStyle(HHTheme.ink)
                                Text("\(incident.status.title) · loss \(Int(incident.loss.rounded()))c · fine \(Int(incident.fine.rounded()))c")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                                    .foregroundStyle(incident.status == .prosecuted ? HHTheme.forest : HHTheme.muted)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private func auditCard(_ listing: BusinessListing) -> some View {
        CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(
                    "Forensic audit",
                    subtitle: "Pay the auditors to look for hidden losses and recover a bounty.",
                    icon: "doc.text.magnifyingglass",
                    accent: HHTheme.goldDeep
                )
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fraud risk \(Int((listing.fundamentals.fraudRisk * 100).rounded()))%")
                            .font(.hhCaption(11))
                            .foregroundStyle(listing.fundamentals.fraudRisk > 0.3 ? HHTheme.terracotta : HHTheme.forest)
                        Text(listing.auditNote ?? "No audit on file.")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                    if economy.investmentAuditUnlocked {
                        Button {
                            let result = store.auditBusiness(id: listing.businessID)
                            message = result.message
                            messagePositive = result.success
                        } label: {
                            Text("Audit · 40c")
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HHTheme.goldDeep, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(store.state.coins < 40)
                    } else {
                        Text("Level 8")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(HHTheme.paperDeep, in: Capsule())
                    }
                }
                if !economy.investmentAuditUnlocked {
                    Text("Forensic audits unlock at level 8 with the Market Town tier.")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                }
            }
        }
    }
}

// MARK: - Small detail rows

private struct LedgerPreviewRow: View {
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

private struct FundamentalCell: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(HHTheme.muted)
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
    }
}
#endif
