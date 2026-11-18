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
        isBankrupt: Bool = false
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
    }

    public var marketCap: Double {
        sharePrice * sharesOutstanding
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

    public var id: String { rawValue }
    public var title: String { self == .buy ? "Buy" : "Sell" }
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
        realizedProfit: Double = 0
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
