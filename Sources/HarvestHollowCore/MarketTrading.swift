import Foundation

// MARK: - Leverage

/// The exchange offers a ladder of leverage. More borrowing means bigger
/// positions, a higher borrow rate, and a much tighter maintenance margin, so a
/// 10x book can be wiped out by a single bad morning.
public struct LeverageTier: Codable, Identifiable, Equatable, Sendable {
    public var multiple: Double
    public var minimumLevel: Int
    public var annualBorrowRate: Double
    public var maintenanceRatio: Double
    public var title: String

    public var id: Double { multiple }

    public init(
        multiple: Double,
        minimumLevel: Int,
        annualBorrowRate: Double,
        maintenanceRatio: Double,
        title: String
    ) {
        self.multiple = multiple
        self.minimumLevel = minimumLevel
        self.annualBorrowRate = annualBorrowRate
        self.maintenanceRatio = maintenanceRatio
        self.title = title
    }

    public var isCash: Bool { multiple <= 1.0001 }

    public var blurb: String {
        if isCash { return "Cash only. No borrow, no margin call." }
        let percent = Int((maintenanceRatio * 100).rounded())
        let rate = String(format: "%.1f", annualBorrowRate * 100)
        return "\(Int(multiple))x · \(rate)% a year · forced sale at \(percent)% equity."
    }
}

public enum LeverageLadder {
    public static let tiers: [LeverageTier] = [
        LeverageTier(multiple: 1, minimumLevel: 1, annualBorrowRate: 0, maintenanceRatio: 0, title: "Cash"),
        LeverageTier(multiple: 2, minimumLevel: 4, annualBorrowRate: 0.055, maintenanceRatio: 0.45, title: "Double"),
        LeverageTier(multiple: 3, minimumLevel: 8, annualBorrowRate: 0.068, maintenanceRatio: 0.33, title: "Triple"),
        LeverageTier(multiple: 5, minimumLevel: 12, annualBorrowRate: 0.082, maintenanceRatio: 0.25, title: "Aggressive"),
        LeverageTier(multiple: 10, minimumLevel: 16, annualBorrowRate: 0.105, maintenanceRatio: 0.15, title: "Reckless")
    ]

    public static func tier(for multiple: Double) -> LeverageTier {
        tiers.first { abs($0.multiple - multiple) < 0.001 }
            ?? tiers.min { abs($0.multiple - multiple) < abs($1.multiple - multiple) }
            ?? tiers[0]
    }

    public static func available(level: Int) -> [LeverageTier] {
        tiers.filter { $0.minimumLevel <= level }
    }

    public static func maxMultiple(level: Int) -> Double {
        available(level: level).map(\.multiple).max() ?? 1
    }

    /// Shorts use the same ladder as longs, but the borrow desk caps the top
    /// rung because squeezes make 10x shorts an exchange-level risk.
    public static func maxShortMultiple(level: Int) -> Double {
        min(5, maxMultiple(level: level))
    }

    public static func maintenanceRatio(for multiple: Double) -> Double {
        tier(for: multiple).maintenanceRatio
    }

    public static func borrowRate(for multiple: Double) -> Double {
        tier(for: multiple).annualBorrowRate
    }
}

// MARK: - Short positions

public struct ShortPosition: Codable, Identifiable, Equatable, Sendable {
    public var businessID: UUID
    public var businessName: String
    public var shares: Double
    public var entryPrice: Double
    /// Cash the player posted as collateral. The exchange holds it while the
    /// position is open and returns it on cover.
    public var collateral: Double
    public var leverage: Double
    public var borrowFeeRate: Double
    public var openedDay: Int
    public var lastTradeDay: Int
    public var totalBorrowFees: Double
    public var peakPrice: Double

    public var id: UUID { businessID }

    public init(
        businessID: UUID,
        businessName: String,
        shares: Double,
        entryPrice: Double,
        collateral: Double,
        leverage: Double,
        borrowFeeRate: Double,
        openedDay: Int,
        lastTradeDay: Int,
        totalBorrowFees: Double = 0,
        peakPrice: Double? = nil
    ) {
        self.businessID = businessID
        self.businessName = businessName
        self.shares = shares
        self.entryPrice = entryPrice
        self.collateral = collateral
        self.leverage = leverage
        self.borrowFeeRate = borrowFeeRate
        self.openedDay = openedDay
        self.lastTradeDay = lastTradeDay
        self.totalBorrowFees = totalBorrowFees
        self.peakPrice = peakPrice ?? entryPrice
    }

    public var notionalAtEntry: Double { shares * entryPrice }

    /// Gain on the borrowed shares themselves, before fees. Price down = profit.
    public func grossProfit(price: Double) -> Double {
        (entryPrice - price) * shares
    }

    public func profit(price: Double) -> Double {
        grossProfit(price: price) - totalBorrowFees
    }

    public func equity(price: Double) -> Double {
        collateral + profit(price: price)
    }

    public func requiredMaintenance(price: Double) -> Double {
        max(0, shares * price) * LeverageLadder.maintenanceRatio(for: leverage)
    }

    /// Where the exchange steps in and buys the shares back.
    public func liquidationPrice() -> Double {
        let maintenance = LeverageLadder.maintenanceRatio(for: leverage)
        guard shares > 0 else { return 0 }
        let denominator = shares * (1 + maintenance)
        guard denominator > 0 else { return 0 }
        return max(0.01, (collateral - totalBorrowFees + shares * entryPrice) / denominator)
    }

    public func returnPercent(price: Double) -> Double {
        guard collateral > 0 else { return 0 }
        return profit(price: price) / collateral
    }

    public func isUnderMaintenance(price: Double) -> Bool {
        guard leverage > 1.0001 else { return false }
        return equity(price: price) < requiredMaintenance(price: price)
    }
}

// MARK: - Short side of the exchange

extension InvestmentMarket {
    public var shortPositions: [ShortPosition] {
        get { shorts ?? [] }
        set { shorts = newValue }
    }

    public var shortMarketValue: Double {
        shortPositions.reduce(0) { total, position in
            guard let listing = listing(for: position.businessID) else { return total }
            return total + position.shares * listing.sharePrice
        }
    }

    public var shortCollateral: Double {
        shortPositions.reduce(0) { $0 + $1.collateral }
    }

    public var shortProfit: Double {
        shortPositions.reduce(0) { total, position in
            guard let listing = listing(for: position.businessID) else { return total }
            return total + position.profit(price: listing.sharePrice)
        }
    }

    public var shortBorrowFees: Double {
        shortPositions.reduce(0) { $0 + $1.totalBorrowFees }
    }

    public var openShorts: Int { shortPositions.count }

    /// Long equity plus short equity: the number the player actually owns.
    public var combinedEquity: Double {
        equity + shortCollateral + shortProfit
    }

    public var grossExposure: Double {
        marketValue + shortMarketValue
    }

    public func short(for id: UUID) -> ShortPosition? {
        shortPositions.first { $0.businessID == id }
    }
}

extension ValleyEconomy {
    public var maxShortLeverage: Double {
        lastKnownLevel >= 4 ? LeverageLadder.maxShortMultiple(level: lastKnownLevel) : 1
    }

    public var leverageTiers: [LeverageTier] {
        LeverageLadder.available(level: lastKnownLevel)
    }

    public var shortSellingUnlocked: Bool { lastKnownLevel >= 4 }
}

// MARK: - Opening and closing shorts

extension ValleyEconomy {
    /// Opens (or adds to) a short position. The exchange holds the collateral
    /// and lends the shares; borrow fees accrue every morning.
    @discardableResult
    public mutating func shortShares(
        businessID: UUID,
        shares requestedShares: Double,
        leverage requestedLeverage: Double,
        availableCoins: Int
    ) -> InvestmentExecution {
        ensureInvestmentMarket()
        guard shortSellingUnlocked else {
            return InvestmentExecution(
                success: false,
                message: "Short selling unlocks at level 4 with the Village tier.",
                cashDelta: 0
            )
        }
        guard var market,
              let listing = market.listing(for: businessID),
              !listing.isBankrupt,
              listing.sharePrice > 0 else {
            return InvestmentExecution(success: false, message: "That business cannot be shorted.", cashDelta: 0)
        }
        let quantity = floor(requestedShares)
        guard quantity >= 1 else {
            return InvestmentExecution(success: false, message: "Short at least one share.", cashDelta: 0)
        }
        let cap = maxShortLeverage
        guard requestedLeverage <= cap + 0.001 else {
            let unlock = LeverageLadder.tiers.first { $0.multiple > cap }?.minimumLevel ?? 16
            return InvestmentExecution(
                success: false,
                message: "That short leverage unlocks at level \(unlock).",
                cashDelta: 0
            )
        }
        let leverage = max(1, requestedLeverage)
        let notional = quantity * listing.sharePrice
        let fee = max(1, (notional * 0.006).rounded(.up))
        let collateral = (notional / leverage).rounded(.up)
        let cash = collateral + fee
        guard cash <= Double(availableCoins) else {
            return InvestmentExecution(
                success: false,
                message: "You need \(Int(cash))c of collateral for this \(Int(leverage))x short.",
                cashDelta: 0
            )
        }
        let tier = LeverageLadder.tier(for: leverage)
        let borrowRate = hhClamp(0.045 + tier.annualBorrowRate + listing.fundamentals.fraudRisk * 0.25, 0.02, 0.9)
        if let index = market.shortPositions.firstIndex(where: { $0.businessID == businessID }) {
            var position = market.shortPositions[index]
            let newShares = position.shares + quantity
            position.entryPrice = (position.entryPrice * position.shares + listing.sharePrice * quantity) / max(1, newShares)
            position.shares = newShares
            position.collateral += collateral
            position.leverage = hhClamp((newShares * position.entryPrice) / max(1, position.collateral), 1, 10)
            position.lastTradeDay = day
            position.peakPrice = max(position.peakPrice, listing.sharePrice)
            market.shortPositions[index] = position
        } else {
            market.shortPositions.append(
                ShortPosition(
                    businessID: businessID,
                    businessName: listing.name,
                    shares: quantity,
                    entryPrice: listing.sharePrice,
                    collateral: collateral,
                    leverage: leverage,
                    borrowFeeRate: borrowRate,
                    openedDay: day,
                    lastTradeDay: day
                )
            )
        }
        refreshShortInterest(&market)
        let trade = InvestmentTrade(
            day: day,
            businessID: businessID,
            businessName: listing.name,
            side: .short,
            shares: quantity,
            price: listing.sharePrice,
            notional: notional,
            fee: fee,
            leverage: leverage,
            cashDelta: -cash,
            marginAdded: max(0, notional - collateral),
            note: "\(Int(leverage))x short · borrow \(String(format: "%.1f", borrowRate * 100))%"
        )
        market.trades.insert(trade, at: 0)
        market.lastNotice = "Shorted \(Int(quantity)) \(listing.name) shares at \(String(format: "%.2f", listing.sharePrice))c."
        self.market = market
        return InvestmentExecution(
            success: true,
            message: "Shorted \(Int(quantity)) shares of \(listing.name). Collateral \(Int(collateral))c.",
            cashDelta: -cash,
            trade: trade
        )
    }

    /// Buys back borrowed shares and returns collateral plus profit.
    @discardableResult
    public mutating func coverShort(
        businessID: UUID,
        shares requestedShares: Double
    ) -> InvestmentExecution {
        ensureInvestmentMarket()
        guard var market,
              let index = market.shortPositions.firstIndex(where: { $0.businessID == businessID }),
              let listing = market.listing(for: businessID) else {
            return InvestmentExecution(success: false, message: "You have no short position there.", cashDelta: 0)
        }
        var position = market.shortPositions[index]
        let quantity = min(floor(requestedShares), position.shares)
        guard quantity >= 1, listing.sharePrice > 0 else {
            return InvestmentExecution(success: false, message: "Nothing to cover.", cashDelta: 0)
        }
        let shareFraction = quantity / max(0.001, position.shares)
        let releasedCollateral = position.collateral * shareFraction
        let gross = position.grossProfit(price: listing.sharePrice) * shareFraction
        let fees = position.totalBorrowFees * shareFraction
        let fee = max(1, (quantity * listing.sharePrice * 0.006).rounded(.up))
        let cash = floor(max(0, releasedCollateral + gross - fees - fee))
        let realized = cash - releasedCollateral
        position.shares -= quantity
        position.collateral = max(0, position.collateral - releasedCollateral)
        position.totalBorrowFees = max(0, position.totalBorrowFees - fees)
        position.lastTradeDay = day
        market.realizedProfit += realized
        let trade = InvestmentTrade(
            day: day,
            businessID: businessID,
            businessName: listing.name,
            side: .cover,
            shares: quantity,
            price: listing.sharePrice,
            notional: quantity * listing.sharePrice,
            fee: fee,
            leverage: position.leverage,
            cashDelta: cash,
            realizedProfit: realized,
            note: realized >= 0 ? "Short covered at a profit" : "Short covered at a loss"
        )
        if position.shares < 0.001 {
            market.shortPositions.remove(at: index)
        } else {
            market.shortPositions[index] = position
        }
        refreshShortInterest(&market)
        market.trades.insert(trade, at: 0)
        market.lastNotice = "Covered \(Int(quantity)) \(listing.name) shares for \(Int(cash))c."
        self.market = market
        return InvestmentExecution(
            success: true,
            message: "Covered \(Int(quantity)) shares. \(realized >= 0 ? "Profit" : "Loss") \(Int(abs(realized)))c.",
            cashDelta: cash,
            trade: trade
        )
    }

    /// Recomputes each listing's short interest from open player positions plus
    /// the shares other valley traders are short.
    mutating func refreshShortInterest(_ market: inout InvestmentMarket) {
        for index in market.listings.indices {
            var listing = market.listings[index]
            let playerShorts = market.shortPositions
                .filter { $0.businessID == listing.businessID }
                .reduce(0) { $0 + $1.shares }
            let otherShorts = listing.sharesOutstanding * listing.ambientShortInterest
            listing.shortInterest = hhClamp(
                (playerShorts + otherShorts) / max(1, listing.sharesOutstanding),
                0,
                0.85
            )
            market.listings[index] = listing
        }
    }

    /// Charges borrow fees, marks shorts to market, and forces a cover when the
    /// collateral no longer covers the maintenance requirement.
    mutating func settleShorts(
        market: inout InvestmentMarket,
        rng: inout GameRNG
    ) {
        guard !market.shortPositions.isEmpty else { return }
        for index in market.shortPositions.indices.reversed() {
            var position = market.shortPositions[index]
            guard let listing = market.listings.first(where: { $0.businessID == position.businessID }) else {
                continue
            }
            let price = max(0.01, listing.sharePrice)
            let notional = position.shares * price
            let dailyFee = notional * position.borrowFeeRate / 365
            position.collateral = max(0, position.collateral - dailyFee)
            position.totalBorrowFees += dailyFee
            position.peakPrice = max(position.peakPrice, price)
            if position.isUnderMaintenance(price: price) {
                let buyback = position.shares * price
                let released = max(0, position.collateral)
                let cash = floor(max(0, released - buyback * 0.002))
                let realized = -max(0, released)
                market.realizedProfit += realized
                market.forcedLiquidations += 1
                market.lastNotice = "Short squeeze: \(listing.name) forced a cover at \(String(format: "%.2f", price))c."
                market.trades.insert(
                    InvestmentTrade(
                        day: day,
                        businessID: position.businessID,
                        businessName: listing.name,
                        side: .cover,
                        shares: position.shares,
                        price: price,
                        notional: buyback,
                        fee: max(1, buyback * 0.002),
                        leverage: position.leverage,
                        cashDelta: cash,
                        realizedProfit: realized,
                        note: "Forced short cover"
                    ),
                    at: 0
                )
                market.shortPositions.remove(at: index)
                if let listingIndex = market.listings.firstIndex(where: { $0.businessID == position.businessID }) {
                    let outstanding = max(1, market.listings[listingIndex].sharesOutstanding)
                    market.listings[listingIndex].shortInterest = hhClamp(
                        market.listings[listingIndex].shortInterest - position.shares / outstanding,
                        0,
                        0.85
                    )
                }
            } else if rng.chance(0.004) {
                market.lastNotice = "Borrow desk raised the fee on \(listing.name); shorts pay more to stay open."
                position.borrowFeeRate = hhClamp(position.borrowFeeRate * 1.08, 0.02, 0.95)
                market.shortPositions[index] = position
            } else {
                market.shortPositions[index] = position
            }
        }
    }
}

// MARK: - Trade sides

extension InvestmentSide {
    public static var allTradingSides: [InvestmentSide] { [.buy, .sell, .short, .cover] }

    public var isOpening: Bool { self == .buy || self == .short }
    public var isShortSide: Bool { self == .short || self == .cover }

    public var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .short: return "arrow.down.forward.circle.fill"
        case .cover: return "arrow.up.forward.circle.fill"
        }
    }

    public var explanation: String {
        switch self {
        case .buy: return "Own shares. Profit when the price rises."
        case .sell: return "Sell shares you own and bank the difference."
        case .short: return "Borrow shares and sell them. Profit when the price falls."
        case .cover: return "Buy borrowed shares back and close a short."
        }
    }
}
