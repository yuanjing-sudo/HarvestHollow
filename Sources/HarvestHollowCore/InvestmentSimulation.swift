import Foundation

// MARK: - Seeding

extension InvestmentMarket {
    public static func seed(businesses: [AIBusiness], day: Int) -> InvestmentMarket {
        let listings = businesses.enumerated().map { index, firm in
            BusinessListing.seed(firm: firm, index: index, day: day)
        }
        return InvestmentMarket(
            listings: listings,
            marketIndex: 100,
            marketHistory: [100],
            lastUpdateDay: day
        )
    }
}

extension BusinessListing {
    static func seed(firm: AIBusiness, index: Int, day: Int) -> BusinessListing {
        let base = max(3.5, 5.5 + firm.capital * 0.18 + Double(index) * 1.15)
        let shares = max(40, (firm.capital * 5.2).rounded())
        let history = (0..<12).map { offset -> Double in
            let wave = sin(Double(offset) * 0.9 + Double(firm.name.count) * 0.37) * 0.035
            let drift = Double(offset - 11) * 0.004
            return max(0.5, base * (1 + wave + drift))
        }
        let revenue = firm.output * 6.5
        let wage = Double(firm.employees) * 22
        let expenses = wage + firm.capital * 0.02 + firm.pollution * 12
        let profit = revenue - expenses
        let fundamentals = BusinessFundamentals(
            revenue: revenue,
            expenses: expenses,
            profit: profit,
            cash: max(0, firm.capital * 0.18),
            debt: max(0, firm.capital * 0.22),
            bookValue: max(1, firm.capital),
            marketShare: 1 / Double(max(1, index + 2)),
            growth: 0.01,
            reputation: firm.mood,
            fraudRisk: firm.kind.fraudBaseline,
            volatility: firm.kind.marketVolatility,
            employees: firm.employees,
            output: firm.output,
            dividendPerShare: profit > 0 ? profit / shares * 0.18 : 0,
            lastUpdatedDay: day
        )
        return BusinessListing(
            businessID: firm.id,
            name: firm.name,
            kind: firm.kind,
            sharePrice: base,
            sharesOutstanding: shares,
            priceHistory: history,
            dailyChange: 0,
            dailyChangePercent: 0,
            fundamentals: fundamentals
        )
    }
}

extension AIBusinessKind {
    var marketVolatility: Double {
        switch self {
        case .bakery, .dairy: return 0.07
        case .mill, .marketStall: return 0.09
        case .workshop, .transport: return 0.12
        case .bank: return 0.1
        case .techStudio: return 0.2
        }
    }

    var fraudBaseline: Double {
        switch self {
        case .bakery, .dairy, .marketStall: return 0.045
        case .mill, .workshop, .transport: return 0.07
        case .bank: return 0.12
        case .techStudio: return 0.09
        }
    }
}

// MARK: - Ledger access

extension ValleyEconomy {
    public var investmentMarket: InvestmentMarket {
        market ?? InvestmentMarket.seed(businesses: aiBusinesses, day: day)
    }

    public var justiceLedger: JusticeLedger {
        justice ?? JusticeLedger()
    }

    public var maxInvestmentLeverage: Double {
        if lastKnownLevel >= 8 { return 3 }
        if lastKnownLevel >= 4 { return 2 }
        return 1
    }

    public var investmentAuditUnlocked: Bool { lastKnownLevel >= 8 }

    public var investmentTradingUnlocked: Bool { true }

    public mutating func ensureLedgers() {
        ensureInvestmentMarket()
        if justice == nil { justice = JusticeLedger() }
    }

    public mutating func ensureInvestmentMarket() {
        guard var existing = market else {
            market = InvestmentMarket.seed(businesses: aiBusinesses, day: day)
            return
        }
        let businessByID = Dictionary(uniqueKeysWithValues: aiBusinesses.map { ($0.id, $0) })
        var known = Set(existing.listings.map(\.businessID))

        for (index, firm) in aiBusinesses.enumerated() where !known.contains(firm.id) {
            existing.listings.append(BusinessListing.seed(firm: firm, index: index, day: day))
            known.insert(firm.id)
        }

        for listingIndex in existing.listings.indices {
            let id = existing.listings[listingIndex].businessID
            if let firm = businessByID[id] {
                existing.listings[listingIndex].name = firm.name
                existing.listings[listingIndex].kind = firm.kind
                existing.listings[listingIndex].isBankrupt = false
            } else if existing.listings[listingIndex].sharePrice > 0 {
                existing.listings[listingIndex].isBankrupt = true
                existing.listings[listingIndex].sharePrice = 0
                existing.listings[listingIndex].dailyChange = 0
                existing.listings[listingIndex].dailyChangePercent = -1
                existing.listings[listingIndex].priceHistory.append(0)
            }
        }

        if existing.marketHistory.isEmpty { existing.marketHistory = [existing.marketIndex] }
        if existing.portfolioHistory.isEmpty {
            existing.portfolioHistory = [
                PortfolioPoint(day: day, value: existing.marketValue, cost: existing.costBasis, debt: existing.marginDebt)
            ]
        }
        existing.marketHistory = Array(existing.marketHistory.suffix(30))
        existing.portfolioHistory = Array(existing.portfolioHistory.suffix(30))
        existing.trades = Array(existing.trades.prefix(40))
        market = existing
    }

    /// Moves forced-liquidation proceeds and dividends back into farm coins.
    public mutating func collectInvestmentCash() -> Double {
        guard var existing = market, existing.pendingCash >= 0.5 else { return 0 }
        let cash = existing.pendingCash
        existing.pendingCash = 0
        market = existing
        return cash
    }
}

// MARK: - Daily market

extension ValleyEconomy {
    mutating func advanceMarket(inputs: EconomyInputs, rng: inout GameRNG) {
        ensureInvestmentMarket()
        guard var market else { return }

        let businessByID = Dictionary(uniqueKeysWithValues: aiBusinesses.map { ($0.id, $0) })
        let totalOutput = max(1, aiBusinesses.reduce(0) { $0 + $1.output })
        let demandSignal = hhClamp(demand / max(1, supply), 0.45, 1.7)
        let baseAverage = market.listings
            .compactMap { $0.priceHistory.first }
            .filter { $0 > 0 }
            .reduce(0, +) / Double(max(1, market.listings.count))
        let previousSentiment = market.sentiment

        for index in market.listings.indices {
            var listing = market.listings[index]
            guard let firm = businessByID[listing.businessID], !listing.isBankrupt else {
                if listing.sharePrice > 0 {
                    listing.isBankrupt = true
                    listing.sharePrice = 0
                    listing.dailyChangePercent = -1
                    listing.priceHistory.append(0)
                    listing.priceHistory = Array(listing.priceHistory.suffix(30))
                    market.listings[index] = listing
                }
                continue
            }

            let revenue = max(0, firm.output * 6.5 * demandSignal * (1 - taxRate * 0.5))
            let wageBill = Double(firm.employees) * averageWage * 0.5
            let capitalCost = firm.capital * max(0, interestRate) / 12
            let pollutionCost = firm.pollution * 12
            let oldDebt = listing.fundamentals.debt
            let debtCost = oldDebt * max(0, interestRate) / 365
            let expenses = wageBill + capitalCost + pollutionCost + debtCost
            let profit = revenue - expenses
            let oldRevenue = listing.fundamentals.revenue
            let growth = hhClamp((revenue - oldRevenue) / max(1, oldRevenue), -0.6, 0.6)
            let risk = hhClamp(
                listing.fundamentals.fraudRisk * 0.72
                    + firm.kind.fraudBaseline * 0.35
                    + corruption * 0.22
                    + (1 - education) * 0.08
                    + max(0, -profit) * 0.008
                    + competition * 0.03
                    - publicServices * 0.06,
                0.01, 0.95
            )
            let reputation = hhClamp(
                firm.mood * 0.68 + (1 - risk) * 0.22 + previousSentiment * 0.1,
                0.05, 1
            )
            let bookValue = max(1, firm.capital + listing.fundamentals.cash - oldDebt * 0.55 + profit * 0.15)
            let dividend = profit > 0
                ? min(0.8, profit / max(1, listing.sharesOutstanding) * 0.16)
                : 0
            let fundamentals = BusinessFundamentals(
                revenue: revenue,
                expenses: expenses,
                profit: profit,
                cash: max(0, listing.fundamentals.cash + profit * 0.22),
                debt: max(0, oldDebt + max(0, -profit) * 0.05),
                bookValue: bookValue,
                marketShare: firm.output / totalOutput,
                growth: growth,
                reputation: reputation,
                fraudRisk: risk,
                volatility: firm.kind.marketVolatility,
                employees: firm.employees,
                output: firm.output,
                dividendPerShare: dividend,
                lastUpdatedDay: day
            )

            let fair = max(
                0.35,
                bookValue / max(1, listing.sharesOutstanding)
                    * (1 + growth * 2.6)
                    * (1 + reputation * 0.28)
                    * (1 - risk * 0.35)
                    * (0.78 + market.sentiment * 0.44)
            )
            let drift = (fair - listing.sharePrice) / max(0.5, listing.sharePrice) * 0.28
            let noise = (rng.double01() * 2 - 1) * fundamentals.volatility * 0.16
            let cycle = sin(Double(day) * 0.63 + Double(listing.name.count) * 0.41) * 0.012
            let previousPrice = listing.sharePrice
            let price = hhClamp(previousPrice * (1 + drift + noise + cycle), 0.25, 999)
            listing.sharePrice = price
            listing.dailyChange = price - previousPrice
            listing.dailyChangePercent = previousPrice > 0 ? (price - previousPrice) / previousPrice : 0
            listing.fundamentals = fundamentals
            listing.priceHistory.append(price)
            listing.priceHistory = Array(listing.priceHistory.suffix(30))
            market.listings[index] = listing
        }

        // Margin interest, dividends, and forced liquidation. Interest makes
        // leverage a real cost; a sharp fall can wipe out the equity.
        for index in market.holdings.indices.reversed() {
            var holding = market.holdings[index]
            guard let listing = market.listings.first(where: { $0.businessID == holding.businessID }) else {
                continue
            }
            let price = listing.sharePrice
            let value = holding.marketValue(price: price)
            if holding.marginDebt > 0 {
                let dailyRate = max(0, interestRate + 0.055) / 365
                let interest = holding.marginDebt * dailyRate
                holding.marginDebt += interest
                holding.totalInterest += interest
                market.totalInterest += interest
            }
            if listing.fundamentals.dividendPerShare > 0 {
                let dividend = holding.shares * listing.fundamentals.dividendPerShare
                market.pendingCash += dividend
                market.totalDividends += dividend
            }
            let equity = value - holding.marginDebt
            if holding.marginDebt > 0.5, value > 0, equity < value * 0.25 {
                let fee = max(1, value * 0.005)
                let cash = max(0, value - holding.marginDebt - fee)
                let realized = cash - holding.shares * holding.averageCost
                market.pendingCash += cash
                market.realizedProfit += realized
                market.forcedLiquidations += 1
                market.lastNotice = "Margin call: \(listing.name) was liquidated for \(Int(cash))c."
                market.trades.insert(
                    InvestmentTrade(
                        day: day,
                        businessID: holding.businessID,
                        businessName: listing.name,
                        side: .sell,
                        shares: holding.shares,
                        price: price,
                        notional: value,
                        fee: fee,
                        leverage: 1,
                        cashDelta: cash,
                        realizedProfit: realized,
                        note: "Forced liquidation"
                    ),
                    at: 0
                )
                market.holdings.remove(at: index)
            } else {
                market.holdings[index] = holding
            }
        }

        let averagePrice = market.listings
            .filter { !$0.isBankrupt }
            .map(\.sharePrice)
            .reduce(0, +) / Double(max(1, market.listings.filter { !$0.isBankrupt }.count))
        market.marketIndex = baseAverage > 0 ? 100 * averagePrice / baseAverage : 100
        market.marketHistory.append(market.marketIndex)
        market.marketHistory = Array(market.marketHistory.suffix(30))

        let averageChange = market.listings.isEmpty
            ? 0
            : market.listings.map(\.dailyChangePercent).reduce(0, +) / Double(market.listings.count)
        let targetSentiment = hhClamp(
            0.42
                + consumerConfidence * 0.26
                + (1 - crime) * 0.08
                - max(0, inflation - 0.05) * 0.5
                - max(0, interestRate - 0.05) * 0.9
                + averageChange * 2.2
                + (1 - corruption) * 0.04,
            0.05, 1
        )
        market.sentiment = hhClamp(market.sentiment * 0.72 + targetSentiment * 0.28, 0.05, 1)
        market.trades = Array(market.trades.prefix(40))
        market.portfolioHistory.append(
            PortfolioPoint(
                day: day,
                value: market.marketValue,
                cost: market.costBasis,
                debt: market.marginDebt
            )
        )
        market.portfolioHistory = Array(market.portfolioHistory.suffix(30))
        market.lastUpdateDay = day
        self.market = market
    }
}

// MARK: - Trading

extension ValleyEconomy {
    @discardableResult
    public mutating func buyShares(
        businessID: UUID,
        shares requestedShares: Double,
        leverage requestedLeverage: Double,
        availableCoins: Int
    ) -> InvestmentExecution {
        ensureInvestmentMarket()
        guard var market,
              let listing = market.listing(for: businessID),
              !listing.isBankrupt,
              listing.sharePrice > 0 else {
            return InvestmentExecution(success: false, message: "That business is not trading.", cashDelta: 0)
        }
        let quantity = floor(requestedShares)
        guard quantity >= 1 else {
            return InvestmentExecution(success: false, message: "Buy at least one share.", cashDelta: 0)
        }
        let leverage = min(max(1, requestedLeverage), maxInvestmentLeverage)
        if requestedLeverage > maxInvestmentLeverage {
            let unlock = maxInvestmentLeverage < 2 ? 4 : 8
            return InvestmentExecution(
                success: false,
                message: "That leverage unlocks at level \(unlock).",
                cashDelta: 0
            )
        }
        let notional = quantity * listing.sharePrice
        let fee = max(1, (notional * 0.005).rounded(.up))
        let equity = notional / leverage
        let cash = (equity + fee).rounded(.up)
        guard cash <= Double(availableCoins) else {
            return InvestmentExecution(
                success: false,
                message: "You need \(Int(cash))c for this \(Int(leverage))x position.",
                cashDelta: 0
            )
        }
        let margin = max(0, notional - equity)
        let trade = InvestmentTrade(
            day: day,
            businessID: businessID,
            businessName: listing.name,
            side: .buy,
            shares: quantity,
            price: listing.sharePrice,
            notional: notional,
            fee: fee,
            leverage: leverage,
            cashDelta: -cash,
            marginAdded: margin,
            note: "\(Int(leverage))x leverage"
        )
        if let index = market.holdings.firstIndex(where: { $0.businessID == businessID }) {
            var holding = market.holdings[index]
            let newShares = holding.shares + quantity
            holding.averageCost = (holding.averageCost * holding.shares + cash) / max(1, newShares)
            holding.shares = newShares
            holding.marginDebt += margin
            holding.totalFees += fee
            holding.lastTradeDay = day
            market.holdings[index] = holding
        } else {
            market.holdings.append(
                InvestmentHolding(
                    businessID: businessID,
                    shares: quantity,
                    averageCost: cash / quantity,
                    marginDebt: margin,
                    openedDay: day,
                    lastTradeDay: day,
                    totalFees: fee
                )
            )
        }
        market.trades.insert(trade, at: 0)
        market.lastNotice = "Bought \(Int(quantity)) \(listing.name) shares at \(String(format: "%.2f", listing.sharePrice))c."
        self.market = market
        return InvestmentExecution(
            success: true,
            message: "Bought \(Int(quantity)) shares of \(listing.name).",
            cashDelta: -cash,
            trade: trade
        )
    }

    @discardableResult
    public mutating func sellShares(
        businessID: UUID,
        shares requestedShares: Double
    ) -> InvestmentExecution {
        ensureInvestmentMarket()
        guard var market,
              let holdingIndex = market.holdings.firstIndex(where: { $0.businessID == businessID }),
              let listing = market.listing(for: businessID) else {
            return InvestmentExecution(success: false, message: "You do not own that business.", cashDelta: 0)
        }
        var holding = market.holdings[holdingIndex]
        let quantity = min(floor(requestedShares), holding.shares)
        guard quantity >= 1, listing.sharePrice > 0 else {
            return InvestmentExecution(success: false, message: "No shares available to sell.", cashDelta: 0)
        }
        let gross = quantity * listing.sharePrice
        let marginRepayment = holding.shares > 0
            ? holding.marginDebt * (quantity / holding.shares)
            : 0
        let fee = max(1, (gross * 0.005).rounded(.up))
        let cash = floor(max(0, gross - marginRepayment - fee))
        let cost = holding.averageCost * quantity
        let realized = cash - cost
        holding.shares -= quantity
        holding.marginDebt = max(0, holding.marginDebt - marginRepayment)
        holding.realizedProfit += realized
        holding.totalFees += fee
        holding.lastTradeDay = day
        market.realizedProfit += realized
        let trade = InvestmentTrade(
            day: day,
            businessID: businessID,
            businessName: listing.name,
            side: .sell,
            shares: quantity,
            price: listing.sharePrice,
            notional: gross,
            fee: fee,
            leverage: 1,
            cashDelta: cash,
            realizedProfit: realized,
            note: realized >= 0 ? "Realized gain" : "Realized loss"
        )
        if holding.shares < 0.001 {
            market.holdings.remove(at: holdingIndex)
        } else {
            market.holdings[holdingIndex] = holding
        }
        market.trades.insert(trade, at: 0)
        market.lastNotice = "Sold \(Int(quantity)) \(listing.name) shares for \(Int(cash))c."
        self.market = market
        return InvestmentExecution(
            success: true,
            message: "Sold \(Int(quantity)) shares for \(Int(cash))c. \(realized >= 0 ? "Gain" : "Loss") \(Int(abs(realized)))c.",
            cashDelta: cash,
            trade: trade
        )
    }

    @discardableResult
    public mutating func auditBusiness(
        id: UUID,
        cost: Double,
        rng: inout GameRNG
    ) -> BusinessAuditResult {
        ensureLedgers()
        guard investmentAuditUnlocked else {
            return BusinessAuditResult(
                success: false,
                cost: 0,
                discoveredFraud: false,
                recovered: 0,
                message: "Forensic audits unlock at level 8."
            )
        }
        guard var market,
              let listingIndex = market.listings.firstIndex(where: { $0.businessID == id }) else {
            return BusinessAuditResult(
                success: false,
                cost: 0,
                discoveredFraud: false,
                recovered: 0,
                message: "That business cannot be audited."
            )
        }
        var listing = market.listings[listingIndex]
        guard !listing.isBankrupt else {
            return BusinessAuditResult(
                success: false,
                cost: 0,
                discoveredFraud: false,
                recovered: 0,
                message: "The business has already failed."
            )
        }
        var justice = justiceLedger
        let risk = listing.fundamentals.fraudRisk
        let findsFraud = rng.chance(hhClamp(0.12 + risk * 1.35 + corruption * 0.25, 0.05, 0.9))
        listing.lastAuditDay = day
        justice.auditsFunded += 1
        justice.lastAuditDay = day
        if findsFraud {
            let severity = hhClamp(0.25 + risk * 0.9, 0.2, 0.98)
            let loss = max(6, listing.fundamentals.revenue * 0.12 * severity)
            let fine = (loss * 0.7).rounded(.up)
            let incident = CrimeIncident(
                day: day,
                kind: .fraud,
                status: .prosecuted,
                severity: severity,
                loss: loss,
                fine: fine,
                businessID: listing.businessID,
                businessName: listing.name,
                title: "Audit uncovers fraud at \(listing.name)",
                detail: "Forensic accountants found \(Int(loss))c missing from the books. The valley recovered \(Int(fine))c.",
                evidence: 0.85
            )
            justice.incidents.insert(incident, at: 0)
            justice.incidents = Array(justice.incidents.prefix(14))
            justice.totalLoss += loss
            justice.totalFines += fine
            justice.convictions += 1
            justice.openCases = justice.incidents.filter { $0.status == .reported || $0.status == .investigating }.count
            justice.lastNotice = incident.title
            let recovered = (fine * 0.18).rounded()
            listing.fundamentals.fraudRisk = hhClamp(risk - 0.4, 0.01, 0.95)
            listing.fundamentals.profit -= loss
            listing.fundamentals.reputation = hhClamp(listing.fundamentals.reputation - 0.18, 0.05, 1)
            listing.sharePrice = max(0.25, listing.sharePrice * 0.94)
            listing.auditNote = "Fraud found · \(Int(fine))c recovered"
            if let firmIndex = aiBusinesses.firstIndex(where: { $0.id == listing.businessID }) {
                aiBusinesses[firmIndex].capital = max(1, aiBusinesses[firmIndex].capital - loss * 0.5)
                aiBusinesses[firmIndex].mood = hhClamp(aiBusinesses[firmIndex].mood - severity * 0.3, 0, 1)
            }
            market.listings[listingIndex] = listing
            self.market = market
            self.justice = justice
            return BusinessAuditResult(
                success: true,
                cost: cost,
                discoveredFraud: true,
                recovered: recovered,
                message: "Audit found fraud. \(Int(fine))c fined, \(Int(recovered))c bounty.",
                incident: incident
            )
        }
        listing.fundamentals.fraudRisk = hhClamp(risk - 0.14, 0.01, 0.95)
        listing.auditNote = "Books clean · risk lowered"
        listing.sharePrice = min(999, listing.sharePrice * 1.015)
        justice.lastNotice = "Audit cleared \(listing.name)."
        market.listings[listingIndex] = listing
        self.market = market
        self.justice = justice
        return BusinessAuditResult(
            success: true,
            cost: cost,
            discoveredFraud: false,
            recovered: 0,
            message: "The books are clean. Risk lowered for \(listing.name)."
        )
    }
}

// MARK: - Justice

extension ValleyEconomy {
    mutating func advanceJustice(rng: inout GameRNG) -> CrimeIncident? {
        ensureLedgers()
        var justice = justiceLedger

        // Cases move through the courts one step each day.
        for index in justice.incidents.indices {
            var incident = justice.incidents[index]
            guard incident.status == .reported || incident.status == .investigating else { continue }
            let progress = hhClamp(
                0.16 + publicServices * 0.38 + education * 0.2 + corruption * -0.12,
                0.05, 0.85
            )
            if rng.chance(progress) {
                if incident.status == .reported {
                    incident.status = .investigating
                } else if rng.chance(hhClamp(0.35 + incident.evidence * 0.5, 0.1, 0.95)) {
                    incident.status = .prosecuted
                    incident.fine = (incident.loss * 0.65).rounded(.up)
                    justice.totalFines += incident.fine
                    justice.convictions += 1
                } else {
                    incident.status = .unsolved
                }
            }
            justice.incidents[index] = incident
        }
        justice.openCases = justice.incidents.filter {
            $0.status == .reported || $0.status == .investigating
        }.count

        let pressure = hhClamp(
            crime * 0.55 + corruption * 0.45 + inequality * 0.15
                + max(0, -(market?.todayChange ?? 0)) * 0.12
                + poverty * 0.12,
            0, 1
        )
        let chance = hhClamp(0.018 + pressure * 0.13, 0.015, 0.22)
        guard rng.chance(chance) else {
            self.justice = justice
            return nil
        }

        let businessCrime = rng.chance(0.56)
        let business = aiBusinesses.isEmpty
            ? nil
            : aiBusinesses[rng.int(in: 0...(aiBusinesses.count - 1))]
        let kind: CrimeKind
        if businessCrime {
            let options: [CrimeKind] = [.fraud, .embezzlement, .taxEvasion, .bribery, .priceFixing]
            kind = options[rng.int(in: 0...(options.count - 1))]
        } else {
            let options: [CrimeKind] = [.theft, .smuggling, .arson, .vandalism]
            kind = options[rng.int(in: 0...(options.count - 1))]
        }
        let severity = hhClamp(0.15 + rng.double01() * 0.72, 0.12, 0.95)
        let name = business?.name ?? "Hollowmere market"
        let revenueBase = business.flatMap { firm in
            market?.listing(for: firm.id)?.fundamentals.revenue
        } ?? 18
        let loss = max(4, revenueBase * 0.14 * severity)
        let evidence = hhClamp(0.18 + publicServices * 0.35 + rng.double01() * 0.35, 0.05, 0.95)
        let incident = CrimeIncident(
            day: day,
            kind: kind,
            status: .reported,
            severity: severity,
            loss: loss,
            businessID: business?.id,
            businessName: name,
            title: "\(kind.title) at \(name)",
            detail: crimeDetail(kind: kind, name: name, severity: severity),
            evidence: evidence
        )
        justice.incidents.insert(incident, at: 0)
        justice.incidents = Array(justice.incidents.prefix(14))
        justice.totalLoss += loss
        justice.openCases += 1
        justice.lastIncidentDay = day
        justice.lastNotice = incident.title

        crime = hhClamp(crime + severity * 0.025, 0.01, 0.8)
        consumerConfidence = hhClamp(consumerConfidence - severity * 0.022, 0.05, 1)
        if let business,
           let firmIndex = aiBusinesses.firstIndex(where: { $0.id == business.id }) {
            aiBusinesses[firmIndex].capital = max(1, aiBusinesses[firmIndex].capital - loss * 0.35)
            aiBusinesses[firmIndex].mood = hhClamp(aiBusinesses[firmIndex].mood - severity * 0.22, 0, 1)
            if var market,
               let listingIndex = market.listings.firstIndex(where: { $0.businessID == business.id }) {
                var listing = market.listings[listingIndex]
                let previous = listing.sharePrice
                listing.sharePrice = max(0.25, previous * (1 - severity * 0.15))
                listing.dailyChange = listing.sharePrice - previous
                listing.dailyChangePercent = previous > 0 ? listing.dailyChange / previous : 0
                listing.fundamentals.profit -= loss
                listing.fundamentals.reputation = hhClamp(listing.fundamentals.reputation - severity * 0.18, 0.05, 1)
                listing.fundamentals.fraudRisk = hhClamp(listing.fundamentals.fraudRisk + severity * 0.18, 0.01, 0.95)
                if let last = listing.priceHistory.indices.last {
                    listing.priceHistory[last] = listing.sharePrice
                }
                market.listings[listingIndex] = listing
                market.lastNotice = incident.title
                self.market = market
            }
        }
        self.justice = justice
        return incident
    }

    private func crimeDetail(kind: CrimeKind, name: String, severity: Double) -> String {
        switch kind {
        case .theft:
            return "Cash and stock vanished from \(name) overnight. The constable has a short list of suspects."
        case .fraud:
            return "Invoices at \(name) do not match the warehouse. Auditors estimate \(Int(severity * 100))% confidence in a hidden loss."
        case .embezzlement:
            return "A manager at \(name) moved valley funds into a private account. The ledgers were altered."
        case .taxEvasion:
            return "\(name) under-reported sales for several weeks. The tax office opened a case."
        case .bribery:
            return "A procurement clerk at \(name) accepted payments to overlook a contract."
        case .smuggling:
            return "Unstamped crates were found on the river road near \(name)."
        case .arson:
            return "A fire damaged a storehouse near \(name). The cause is being investigated."
        case .priceFixing:
            return "\(name) and a rival were caught agreeing on prices before market day."
        case .vandalism:
            return "Market stalls near \(name) were damaged before dawn."
        }
    }
}
