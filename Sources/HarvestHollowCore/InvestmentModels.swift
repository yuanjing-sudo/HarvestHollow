import Foundation

// MARK: - Market fundamentals

/// The numbers behind a share price. These are deliberately readable: a player
/// can judge a business from its profit, debt, growth, reputation, and fraud
/// risk instead of guessing at a chart.
public struct BusinessFundamentals: Codable, Equatable, Sendable {
    public var revenue: Double
    public var expenses: Double
    public var profit: Double
    public var cash: Double
    public var debt: Double
    public var bookValue: Double
    public var marketShare: Double
    public var growth: Double
    public var reputation: Double
    public var fraudRisk: Double
    public var volatility: Double
    public var employees: Int
    public var output: Double
    public var dividendPerShare: Double
    public var lastUpdatedDay: Int

    public init(
        revenue: Double = 0,
        expenses: Double = 0,
        profit: Double = 0,
        cash: Double = 0,
        debt: Double = 0,
        bookValue: Double = 1,
        marketShare: Double = 0,
        growth: Double = 0,
        reputation: Double = 0.5,
        fraudRisk: Double = 0.05,
        volatility: Double = 0.08,
        employees: Int = 0,
        output: Double = 0,
        dividendPerShare: Double = 0,
        lastUpdatedDay: Int = 1
    ) {
        self.revenue = revenue
        self.expenses = expenses
        self.profit = profit
        self.cash = cash
        self.debt = debt
        self.bookValue = bookValue
        self.marketShare = marketShare
        self.growth = growth
        self.reputation = reputation
        self.fraudRisk = fraudRisk
        self.volatility = volatility
        self.employees = employees
        self.output = output
        self.dividendPerShare = dividendPerShare
        self.lastUpdatedDay = lastUpdatedDay
    }

    public var margin: Double {
        revenue > 0 ? profit / revenue : 0
    }

    public var netWorth: Double {
        max(0, cash + bookValue - debt)
    }

    public var riskLabel: String {
        switch fraudRisk {
        case ..<0.12: return "Low risk"
        case ..<0.28: return "Watch"
        case ..<0.5: return "Elevated"
        default: return "Severe"
        }
    }

    public var healthLabel: String {
        if profit < 0 { return "Loss-making" }
        if margin > 0.18 { return "Strong margins" }
        if margin > 0.06 { return "Steady" }
        return "Thin margins"
    }
}

// MARK: - Listings

public struct BusinessListing: Codable, Identifiable, Equatable, Sendable {
    public var businessID: UUID
    public var name: String
    public var kind: AIBusinessKind
    public var sharePrice: Double
    public var sharesOutstanding: Double
    public var priceHistory: [Double]
    public var dailyChange: Double
    public var dailyChangePercent: Double
    public var fundamentals: BusinessFundamentals
    public var lastAuditDay: Int?
    public var auditNote: String?
    public var isBankrupt: Bool

    // Trading structure added with the deeper exchange. Every field has a
    // default so saves written before the candles existed still decode.
    public var bars: [PriceBar]
    public var volume: Double
    public var shortInterest: Double
    /// Other valley traders' short book, as a fraction of shares outstanding.
    public var ambientShortInterest: Double
    public var insiderSales: Double
    public var beta: Double
    public var earningsSurprise: Double
    public var volatilityState: Double
    public var bidAskSpread: Double
    public var priceTarget: Double

    public var id: UUID { businessID }

    public init(
        businessID: UUID,
        name: String,
        kind: AIBusinessKind,
        sharePrice: Double,
        sharesOutstanding: Double,
        priceHistory: [Double] = [],
        dailyChange: Double = 0,
        dailyChangePercent: Double = 0,
        fundamentals: BusinessFundamentals = BusinessFundamentals(),
        lastAuditDay: Int? = nil,
        auditNote: String? = nil,
        isBankrupt: Bool = false,
        bars: [PriceBar] = [],
        volume: Double = 0,
        shortInterest: Double = 0,
        ambientShortInterest: Double = 0.02,
        insiderSales: Double = 0,
        beta: Double = 1,
        earningsSurprise: Double = 0,
        volatilityState: Double = 0.012,
        bidAskSpread: Double = 0.004,
        priceTarget: Double = 0
    ) {
        self.businessID = businessID
        self.name = name
        self.kind = kind
        self.sharePrice = sharePrice
        self.sharesOutstanding = max(1, sharesOutstanding)
        self.priceHistory = priceHistory
        self.dailyChange = dailyChange
        self.dailyChangePercent = dailyChangePercent
        self.fundamentals = fundamentals
        self.lastAuditDay = lastAuditDay
        self.auditNote = auditNote
        self.isBankrupt = isBankrupt
        self.bars = bars
        self.volume = volume
        self.shortInterest = shortInterest
        self.ambientShortInterest = ambientShortInterest
        self.insiderSales = insiderSales
        self.beta = beta
        self.earningsSurprise = earningsSurprise
        self.volatilityState = volatilityState
        self.bidAskSpread = bidAskSpread
        self.priceTarget = priceTarget
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        businessID = try container.decode(UUID.self, forKey: .businessID)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decode(AIBusinessKind.self, forKey: .kind)
        sharePrice = try container.decode(Double.self, forKey: .sharePrice)
        sharesOutstanding = max(1, try container.decodeIfPresent(Double.self, forKey: .sharesOutstanding) ?? 1)
        priceHistory = try container.decodeIfPresent([Double].self, forKey: .priceHistory) ?? [sharePrice]
        dailyChange = try container.decodeIfPresent(Double.self, forKey: .dailyChange) ?? 0
        dailyChangePercent = try container.decodeIfPresent(Double.self, forKey: .dailyChangePercent) ?? 0
        fundamentals = try container.decodeIfPresent(BusinessFundamentals.self, forKey: .fundamentals)
            ?? BusinessFundamentals()
        lastAuditDay = try container.decodeIfPresent(Int.self, forKey: .lastAuditDay)
        auditNote = try container.decodeIfPresent(String.self, forKey: .auditNote)
        isBankrupt = try container.decodeIfPresent(Bool.self, forKey: .isBankrupt) ?? false
        bars = try container.decodeIfPresent([PriceBar].self, forKey: .bars) ?? []
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0
        shortInterest = try container.decodeIfPresent(Double.self, forKey: .shortInterest) ?? 0
        ambientShortInterest = try container.decodeIfPresent(Double.self, forKey: .ambientShortInterest) ?? 0.02
        insiderSales = try container.decodeIfPresent(Double.self, forKey: .insiderSales) ?? 0
        beta = try container.decodeIfPresent(Double.self, forKey: .beta) ?? 1
        earningsSurprise = try container.decodeIfPresent(Double.self, forKey: .earningsSurprise) ?? 0
        volatilityState = try container.decodeIfPresent(Double.self, forKey: .volatilityState) ?? 0.012
        bidAskSpread = try container.decodeIfPresent(Double.self, forKey: .bidAskSpread) ?? 0.004
        priceTarget = try container.decodeIfPresent(Double.self, forKey: .priceTarget) ?? 0
    }

    public var marketCap: Double {
        sharePrice * sharesOutstanding
    }

    /// Half the quoted bid-ask spread, in coins per share. Buys pay it, sells
    /// receive less, and shorts pay it again when they cover.
    public var halfSpread: Double {
        sharePrice * max(0.0005, bidAskSpread) / 2
    }

    public var fairValueGap: Double {
        guard priceTarget > 0 else { return 0 }
        return (priceTarget - sharePrice) / max(0.01, priceTarget)
    }

    public var priceToBook: Double {
        marketCap / max(1, fundamentals.bookValue)
    }

    public var priceToEarnings: Double? {
        guard fundamentals.profit > 0.4 else { return nil }
        return marketCap / (fundamentals.profit * 24)
    }

    public var dividendYield: Double {
        guard sharePrice > 0 else { return 0 }
        return fundamentals.dividendPerShare / sharePrice
    }

    public var analystRating: String {
        if isBankrupt { return "Failed" }
        if fundamentals.profit < 0 { return "Sell" }
        if fundamentals.fraudRisk > 0.4 { return "Avoid" }
        if fundamentals.growth > 0.08, fundamentals.reputation > 0.55 { return "Buy" }
        if fundamentals.growth > 0, fundamentals.reputation > 0.45 { return "Hold" }
        return "Watch"
    }

    public var changeTint: String {
        dailyChangePercent >= 0 ? "4F8A5A" : "B64B3F"
    }
}

// MARK: - Holdings and trades

public struct InvestmentHolding: Codable, Identifiable, Equatable, Sendable {
    public var businessID: UUID
    public var shares: Double
    /// The player's own cash basis per share. Borrowed money is tracked in
    /// `marginDebt`, so leverage magnifies both gains and losses.
    public var averageCost: Double
    public var marginDebt: Double
    public var openedDay: Int
    public var lastTradeDay: Int
    public var realizedProfit: Double
    public var totalFees: Double
    public var totalInterest: Double

    public var id: UUID { businessID }

    public init(
        businessID: UUID,
        shares: Double,
        averageCost: Double,
        marginDebt: Double = 0,
        openedDay: Int,
        lastTradeDay: Int,
        realizedProfit: Double = 0,
        totalFees: Double = 0,
        totalInterest: Double = 0
    ) {
        self.businessID = businessID
        self.shares = shares
        self.averageCost = averageCost
        self.marginDebt = marginDebt
        self.openedDay = openedDay
        self.lastTradeDay = lastTradeDay
        self.realizedProfit = realizedProfit
        self.totalFees = totalFees
        self.totalInterest = totalInterest
    }

    public func marketValue(price: Double) -> Double { shares * price }
    public func equity(price: Double) -> Double { marketValue(price: price) - marginDebt }
    public func unrealized(price: Double) -> Double {
        equity(price: price) - shares * averageCost
    }
    public func leverage(price: Double) -> Double {
        let equity = equity(price: price)
        let value = marketValue(price: price)
        guard equity > 0 else { return 5 }
        return value / equity
    }
}

public enum InvestmentSide: String, Codable, Sendable, Identifiable {
    case buy
    case sell
    case short
    case cover

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .short: return "Short"
        case .cover: return "Cover"
        }
    }
}

public struct InvestmentTrade: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var day: Int
    public var businessID: UUID
    public var businessName: String
    public var side: InvestmentSide
    public var shares: Double
    public var price: Double
    public var notional: Double
    public var fee: Double
    public var leverage: Double
    public var cashDelta: Double
    public var realizedProfit: Double
    public var marginAdded: Double
    public var note: String

    public init(
        id: UUID = UUID(),
        day: Int,
        businessID: UUID,
        businessName: String,
        side: InvestmentSide,
        shares: Double,
        price: Double,
        notional: Double,
        fee: Double,
        leverage: Double,
        cashDelta: Double,
        realizedProfit: Double = 0,
        marginAdded: Double = 0,
        note: String = ""
    ) {
        self.id = id
        self.day = day
        self.businessID = businessID
        self.businessName = businessName
        self.side = side
        self.shares = shares
        self.price = price
        self.notional = notional
        self.fee = fee
        self.leverage = leverage
        self.cashDelta = cashDelta
        self.realizedProfit = realizedProfit
        self.marginAdded = marginAdded
        self.note = note
    }
}

public struct PortfolioPoint: Codable, Equatable, Sendable {
    public var day: Int
    public var value: Double
    public var cost: Double
    public var debt: Double

    public init(day: Int, value: Double, cost: Double, debt: Double) {
        self.day = day
        self.value = value
        self.cost = cost
        self.debt = debt
    }
}

public struct InvestmentExecution: Sendable {
    public let success: Bool
    public let message: String
    public let cashDelta: Double
    public let trade: InvestmentTrade?

    public init(success: Bool, message: String, cashDelta: Double, trade: InvestmentTrade? = nil) {
        self.success = success
        self.message = message
        self.cashDelta = cashDelta
        self.trade = trade
    }
}

// MARK: - Market

public struct InvestmentMarket: Codable, Equatable, Sendable {
    public var listings: [BusinessListing]
    public var holdings: [InvestmentHolding]
    public var trades: [InvestmentTrade]
    public var marketIndex: Double
    public var marketHistory: [Double]
    public var portfolioHistory: [PortfolioPoint]
    public var sentiment: Double
    public var lastUpdateDay: Int
    public var pendingCash: Double
    public var lastNotice: String?
    public var forcedLiquidations: Int
    public var totalInterest: Double
    public var totalDividends: Double
    public var realizedProfit: Double

    // Deeper exchange state. All optional or defaulted so older saves load.
    public var shorts: [ShortPosition]?
    public var indexBars: [PriceBar]
    public var volatilityIndex: Double
    public var regime: MarketRegime
    public var factorBook: MarketFactorBook?
    public var policyReport: PolicyImpactReport?
    public var competitors: [CompetitorProfile]?
    public var competitionHeat: Double
    public var openRoles: Int
    public var competitorRnd: Double
    public var competitorMarketing: Double
    public var supplierAgreements: Int
    public var takeoverTalk: Int
    public var rumour: String?
    public var sessionsPlayed: Int

    public init(
        listings: [BusinessListing] = [],
        holdings: [InvestmentHolding] = [],
        trades: [InvestmentTrade] = [],
        marketIndex: Double = 100,
        marketHistory: [Double] = [100],
        portfolioHistory: [PortfolioPoint] = [],
        sentiment: Double = 0.55,
        lastUpdateDay: Int = 1,
        pendingCash: Double = 0,
        lastNotice: String? = nil,
        forcedLiquidations: Int = 0,
        totalInterest: Double = 0,
        totalDividends: Double = 0,
        realizedProfit: Double = 0,
        shorts: [ShortPosition]? = nil,
        indexBars: [PriceBar] = [],
        volatilityIndex: Double = 22,
        regime: MarketRegime = .choppy,
        factorBook: MarketFactorBook? = nil,
        policyReport: PolicyImpactReport? = nil,
        competitors: [CompetitorProfile]? = nil,
        competitionHeat: Double = 0,
        openRoles: Int = 0,
        competitorRnd: Double = 0,
        competitorMarketing: Double = 0,
        supplierAgreements: Int = 0,
        takeoverTalk: Int = 0,
        rumour: String? = nil,
        sessionsPlayed: Int = 0
    ) {
        self.listings = listings
        self.holdings = holdings
        self.trades = trades
        self.marketIndex = marketIndex
        self.marketHistory = marketHistory
        self.portfolioHistory = portfolioHistory
        self.sentiment = sentiment
        self.lastUpdateDay = lastUpdateDay
        self.pendingCash = pendingCash
        self.lastNotice = lastNotice
        self.forcedLiquidations = forcedLiquidations
        self.totalInterest = totalInterest
        self.totalDividends = totalDividends
        self.realizedProfit = realizedProfit
        self.shorts = shorts
        self.indexBars = indexBars
        self.volatilityIndex = volatilityIndex
        self.regime = regime
        self.factorBook = factorBook
        self.policyReport = policyReport
        self.competitors = competitors
        self.competitionHeat = competitionHeat
        self.openRoles = openRoles
        self.competitorRnd = competitorRnd
        self.competitorMarketing = competitorMarketing
        self.supplierAgreements = supplierAgreements
        self.takeoverTalk = takeoverTalk
        self.rumour = rumour
        self.sessionsPlayed = sessionsPlayed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        listings = try container.decodeIfPresent([BusinessListing].self, forKey: .listings) ?? []
        holdings = try container.decodeIfPresent([InvestmentHolding].self, forKey: .holdings) ?? []
        trades = try container.decodeIfPresent([InvestmentTrade].self, forKey: .trades) ?? []
        marketIndex = try container.decodeIfPresent(Double.self, forKey: .marketIndex) ?? 100
        marketHistory = try container.decodeIfPresent([Double].self, forKey: .marketHistory) ?? [marketIndex]
        portfolioHistory = try container.decodeIfPresent([PortfolioPoint].self, forKey: .portfolioHistory) ?? []
        sentiment = try container.decodeIfPresent(Double.self, forKey: .sentiment) ?? 0.55
        lastUpdateDay = try container.decodeIfPresent(Int.self, forKey: .lastUpdateDay) ?? 1
        pendingCash = try container.decodeIfPresent(Double.self, forKey: .pendingCash) ?? 0
        lastNotice = try container.decodeIfPresent(String.self, forKey: .lastNotice)
        forcedLiquidations = try container.decodeIfPresent(Int.self, forKey: .forcedLiquidations) ?? 0
        totalInterest = try container.decodeIfPresent(Double.self, forKey: .totalInterest) ?? 0
        totalDividends = try container.decodeIfPresent(Double.self, forKey: .totalDividends) ?? 0
        realizedProfit = try container.decodeIfPresent(Double.self, forKey: .realizedProfit) ?? 0
        shorts = try container.decodeIfPresent([ShortPosition].self, forKey: .shorts)
        indexBars = try container.decodeIfPresent([PriceBar].self, forKey: .indexBars) ?? []
        volatilityIndex = try container.decodeIfPresent(Double.self, forKey: .volatilityIndex) ?? 22
        regime = try container.decodeIfPresent(MarketRegime.self, forKey: .regime) ?? .choppy
        factorBook = try container.decodeIfPresent(MarketFactorBook.self, forKey: .factorBook)
        policyReport = try container.decodeIfPresent(PolicyImpactReport.self, forKey: .policyReport)
        competitors = try container.decodeIfPresent([CompetitorProfile].self, forKey: .competitors)
        competitionHeat = try container.decodeIfPresent(Double.self, forKey: .competitionHeat) ?? 0
        openRoles = try container.decodeIfPresent(Int.self, forKey: .openRoles) ?? 0
        competitorRnd = try container.decodeIfPresent(Double.self, forKey: .competitorRnd) ?? 0
        competitorMarketing = try container.decodeIfPresent(Double.self, forKey: .competitorMarketing) ?? 0
        supplierAgreements = try container.decodeIfPresent(Int.self, forKey: .supplierAgreements) ?? 0
        takeoverTalk = try container.decodeIfPresent(Int.self, forKey: .takeoverTalk) ?? 0
        rumour = try container.decodeIfPresent(String.self, forKey: .rumour)
        sessionsPlayed = try container.decodeIfPresent(Int.self, forKey: .sessionsPlayed) ?? 0
    }

    /// A short book plus long equity is what the player really owns.
    public var netWorth: Double {
        marketValue - marginDebt + shortCollateral + shortProfit
    }

    public func listing(for id: UUID) -> BusinessListing? {
        listings.first { $0.businessID == id }
    }

    public func holding(for id: UUID) -> InvestmentHolding? {
        holdings.first { $0.businessID == id }
    }

    public var marketValue: Double {
        holdings.reduce(0) { total, holding in
            guard let listing = listing(for: holding.businessID) else { return total }
            return total + holding.marketValue(price: listing.sharePrice)
        }
    }

    public var costBasis: Double {
        holdings.reduce(0) { $0 + $1.shares * $1.averageCost }
    }

    public var marginDebt: Double {
        holdings.reduce(0) { $0 + $1.marginDebt }
    }

    public var equity: Double { marketValue - marginDebt }

    public var unrealizedProfit: Double { equity - costBasis }

    public var totalFees: Double {
        trades.reduce(0) { $0 + $1.fee }
    }

    public var leverage: Double {
        guard equity > 0 else { return marginDebt > 0 ? 5 : 1 }
        return marketValue / equity
    }

    public var openPositions: Int { holdings.count }

    public var todayChange: Double {
        guard marketHistory.count >= 2 else { return 0 }
        return marketHistory[marketHistory.count - 1] - marketHistory[marketHistory.count - 2]
    }

    public var todayChangePercent: Double {
        guard marketHistory.count >= 2 else { return 0 }
        let previous = marketHistory[marketHistory.count - 2]
        guard previous > 0 else { return 0 }
        return (marketHistory[marketHistory.count - 1] - previous) / previous
    }

    public var gainers: Int { listings.filter { $0.dailyChangePercent > 0 && !$0.isBankrupt }.count }
    public var losers: Int { listings.filter { $0.dailyChangePercent < 0 && !$0.isBankrupt }.count }
    public var breadth: Double {
        let active = listings.filter { !$0.isBankrupt }
        guard !active.isEmpty else { return 0.5 }
        return Double(active.filter { $0.dailyChangePercent > 0 }.count) / Double(active.count)
    }

    public var effectiveIndexBars: [PriceBar] {
        if !indexBars.isEmpty { return indexBars }
        return marketHistory.enumerated().map { index, value in
            PriceBar(day: index + 1, open: value, high: value * 1.004, low: value * 0.996, close: value, volume: 1000)
        }
    }
}

// MARK: - Crime and justice

public enum CrimeKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case theft
    case fraud
    case embezzlement
    case taxEvasion
    case bribery
    case smuggling
    case arson
    case priceFixing
    case vandalism

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .theft: return "Market theft"
        case .fraud: return "Accounting fraud"
        case .embezzlement: return "Embezzlement"
        case .taxEvasion: return "Tax evasion"
        case .bribery: return "Bribery"
        case .smuggling: return "Smuggling"
        case .arson: return "Arson"
        case .priceFixing: return "Price fixing"
        case .vandalism: return "Vandalism"
        }
    }

    public var icon: String {
        switch self {
        case .theft: return "hand.raised.fill"
        case .fraud: return "doc.text.magnifyingglass"
        case .embezzlement: return "banknote.fill"
        case .taxEvasion: return "percent"
        case .bribery: return "handshake.fill"
        case .smuggling: return "shippingbox.fill"
        case .arson: return "flame.fill"
        case .priceFixing: return "chart.line.uptrend.xyaxis"
        case .vandalism: return "paintbrush.fill"
        }
    }

    public var isBusinessCrime: Bool {
        switch self {
        case .fraud, .embezzlement, .taxEvasion, .bribery, .priceFixing: return true
        case .theft, .smuggling, .arson, .vandalism: return false
        }
    }
}

public enum CrimeStatus: String, Codable, Sendable, Identifiable {
    case reported
    case investigating
    case prosecuted
    case unsolved

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .reported: return "Reported"
        case .investigating: return "Investigating"
        case .prosecuted: return "Prosecuted"
        case .unsolved: return "Unsolved"
        }
    }
}

public struct CrimeIncident: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var day: Int
    public var kind: CrimeKind
    public var status: CrimeStatus
    public var severity: Double
    public var loss: Double
    public var fine: Double
    public var businessID: UUID?
    public var businessName: String
    public var title: String
    public var detail: String
    public var evidence: Double

    public init(
        id: UUID = UUID(),
        day: Int,
        kind: CrimeKind,
        status: CrimeStatus = .reported,
        severity: Double,
        loss: Double,
        fine: Double = 0,
        businessID: UUID? = nil,
        businessName: String = "",
        title: String,
        detail: String,
        evidence: Double = 0
    ) {
        self.id = id
        self.day = day
        self.kind = kind
        self.status = status
        self.severity = severity
        self.loss = loss
        self.fine = fine
        self.businessID = businessID
        self.businessName = businessName
        self.title = title
        self.detail = detail
        self.evidence = evidence
    }
}

public struct JusticeLedger: Codable, Equatable, Sendable {
    public var incidents: [CrimeIncident]
    public var totalLoss: Double
    public var totalFines: Double
    public var convictions: Int
    public var openCases: Int
    public var auditsFunded: Int
    public var lastAuditDay: Int
    public var lastIncidentDay: Int
    public var lastNotice: String?

    public init(
        incidents: [CrimeIncident] = [],
        totalLoss: Double = 0,
        totalFines: Double = 0,
        convictions: Int = 0,
        openCases: Int = 0,
        auditsFunded: Int = 0,
        lastAuditDay: Int = 0,
        lastIncidentDay: Int = 0,
        lastNotice: String? = nil
    ) {
        self.incidents = incidents
        self.totalLoss = totalLoss
        self.totalFines = totalFines
        self.convictions = convictions
        self.openCases = openCases
        self.auditsFunded = auditsFunded
        self.lastAuditDay = lastAuditDay
        self.lastIncidentDay = lastIncidentDay
        self.lastNotice = lastNotice
    }

    public var recent: [CrimeIncident] { Array(incidents.prefix(8)) }
    public var prosecutionRate: Double {
        let closed = incidents.filter { $0.status == .prosecuted || $0.status == .unsolved }.count
        guard closed > 0 else { return 0 }
        return Double(incidents.filter { $0.status == .prosecuted }.count) / Double(closed)
    }
}

public struct BusinessAuditResult: Sendable {
    public let success: Bool
    public let cost: Double
    public let discoveredFraud: Bool
    public let recovered: Double
    public let message: String
    public let incident: CrimeIncident?

    public init(
        success: Bool,
        cost: Double,
        discoveredFraud: Bool,
        recovered: Double,
        message: String,
        incident: CrimeIncident? = nil
    ) {
        self.success = success
        self.cost = cost
        self.discoveredFraud = discoveredFraud
        self.recovered = recovered
        self.message = message
        self.incident = incident
    }
}
