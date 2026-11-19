import Foundation

extension ValleyEconomy {
    /// Advances prices one trading session. The model is deliberately layered:
    /// rivals act first, policy is priced, then each listing is marked against
    /// its own fair value plus market, sector and technical pressure.
    mutating func advanceMarket(inputs: EconomyInputs, rng: inout GameRNG) {
        ensureInvestmentMarket()
        guard var market = self.market else { return }

        var businessByID: [UUID: AIBusiness] = [:]
        for firm in aiBusinesses { businessByID[firm.id] = firm }
        let totalOutput = max(1, aiBusinesses.reduce(0) { $0 + $1.output })
        let demandSignal = hhClamp(demand / max(1, supply), 0.45, 1.7)
        let previousSentiment = market.sentiment

        let activeBefore = market.listings.filter { !$0.isBankrupt }
        let averageBefore = activeBefore.isEmpty
            ? 0
            : activeBefore.map(\.sharePrice).reduce(0, +) / Double(activeBefore.count)

        // 1. Rivals move before the opening bell.
        advanceCompetitors(market: &market, rng: &rng)

        // 2. Any policy change since the last session is priced immediately.
        let policyReport = applyPolicyShock(to: &market, rng: &rng)

        // 3. Common market factor: everything shares a little of the same mood.
        let commonVol = hhClamp(
            0.0035 + market.volatilityIndex / 100 * 0.012 + (1 - previousSentiment) * 0.004 + pollution * 0.004,
            0.0015,
            0.02
        )
        let commonShock = hhGaussian(&rng) * commonVol
        var sectorShock: [AIBusinessKind: Double] = [:]
        for kind in AIBusinessKind.allCases {
            sectorShock[kind] = hhGaussian(&rng) * 0.004
        }
        let policyTailwind = (publicSpending - 0.16) * 0.55 - (taxRate - 0.17) * 1.35 + (0.04 - tariffRate) * 0.35
        let liquidity = hhClamp(
            0.25 + Double(market.listings.count) / 24 + previousSentiment * 0.35 - market.marginDebt / max(1, gdp * 4),
            0.03,
            1
        )

        for index in market.listings.indices {
            var listing = market.listings[index]
            guard let firm = businessByID[listing.businessID], !listing.isBankrupt else {
                if listing.sharePrice > 0 {
                    listing.isBankrupt = true
                    listing.sharePrice = 0
                    listing.dailyChangePercent = -1
                    listing.priceHistory.append(0)
                    listing.priceHistory = Array(listing.priceHistory.suffix(40))
                    listing.bars.append(
                        PriceBar(day: day, open: listing.bars.last?.close ?? 0, high: listing.bars.last?.close ?? 0, low: 0, close: 0, volume: 0)
                    )
                    listing.bars = Array(listing.bars.suffix(40))
                    market.listings[index] = listing
                }
                continue
            }

            // --- Firm books ------------------------------------------------
            let grossRevenue = max(0, firm.output * 6.5 * demandSignal)
            let afterTaxRevenue = grossRevenue * (1 - taxRate * 0.55)
            let wageBill = Double(firm.employees) * averageWage * 0.5
            let capitalCost = firm.capital * max(0, interestRate) / 12
            let pollutionCost = firm.pollution * 12
            let oldDebt = listing.fundamentals.debt
            let debtCost = oldDebt * max(0, interestRate) / 365
            let compliance = Double(firm.employees) * (0.4 + corruption * 3) + marketingDrag(market: market)
            let subsidyCredit = grossRevenue * subsidyRate * 0.35
            let publicBoost = grossRevenue * max(0, publicSpending - 0.16) * 0.25
            let expenses = wageBill + capitalCost + pollutionCost + debtCost + compliance
            let profit = afterTaxRevenue - expenses + subsidyCredit + publicBoost
            let oldRevenue = listing.fundamentals.revenue
            let growth = hhClamp((afterTaxRevenue - oldRevenue) / max(1, oldRevenue), -0.6, 0.6)
            let taxPaid = grossRevenue * taxRate * 0.55

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
            let grossDividend = profit > 0
                ? min(0.8, profit / max(1, listing.sharesOutstanding) * 0.16)
                : 0
            let dividend = grossDividend * (1 - taxRate * 0.8)
            let fundamentals = BusinessFundamentals(
                revenue: afterTaxRevenue,
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

            // --- Fair value -------------------------------------------------
            // Anchor on the listing's own recent average, then tilt it by the
            // books. That keeps prices inside a believable band while making
            // profit, reputation, risk, tax and policy genuinely matter.
            let bars = listing.effectiveBars
            let previousPrice = max(0.2, listing.sharePrice)
            let anchor = bars.averageClosingPrice(30)
            let tilt = (1 + hhClamp(growth, -0.4, 0.4) * 0.8)
                * (1 + reputation * 0.15)
                * (1 - risk * 0.30)
                * (0.94 + market.sentiment * 0.10)
                * (1 + policyTailwind * 0.55)
            let fair = max(0.3, anchor * tilt)
            let fairGap = hhClamp((fair - previousPrice) / max(0.2, previousPrice), -0.5, 0.5)

            // --- Technicals -------------------------------------------------
            let momentum = bars.returnOver(5)
            let stretch = bars.zScore(20)
            let drawdown = bars.drawdown(30)
            let rsi = bars.relativeStrengthIndex(14)
            let drift = fairGap * 0.10
            let trend = momentum * 0.06
            let bounce = -stretch * 0.008 - (drawdown > 0.25 ? drawdown * 0.006 : 0)
            let oversoldSnap = rsi < 28 ? 0.006 : rsi > 74 ? -0.005 : 0
            let squeeze = listing.shortInterest > 0.1
                ? listing.shortInterest * (momentum > 0 ? 0.10 : 0.03)
                : 0
            let insiderDrag = listing.insiderSales > 0.2 ? -listing.insiderSales * 0.012 : 0
            let beta = hhClamp(listing.beta, 0.35, 2.6)
            let sector = sectorShock[firm.kind] ?? 0
            let baseSigma = 0.003 + firm.kind.marketVolatility * 0.09
            let volatilityState = hhClamp(
                listing.volatilityState * 0.82
                    + abs(listing.dailyChangePercent) * 0.16
                    + baseSigma * 0.18
                    + market.volatilityIndex / 100 * 0.0004,
                0.002,
                0.06
            )
            let noise = hhGaussian(&rng) * volatilityState
            var jump = 0.0
            if rng.chance(0.035 + risk * 0.06) {
                jump = hhGaussian(&rng) * (0.012 + risk * 0.02) * (rng.chance(0.5) ? 1 : -1) * 1.6
            }
            let competitionDrag = -market.competitionHeat * 0.006 * (1 - reputation)

            let rawChange = drift + trend + bounce + oversoldSnap + squeeze + insiderDrag
                + commonShock * beta + sector + noise + jump + competitionDrag
            // Circuit breaker: no listing moves more than 18% in a session.
            var closeChange = hhClamp(rawChange, -0.16, 0.16)
            if listing.isBankrupt { closeChange = 0 }
            let gap = hhGaussian(&rng) * volatilityState * 0.35
            let open = hhClamp(previousPrice * (1 + gap), 0.2, 999)
            let close = hhClamp(open * (1 + closeChange), 0.2, 1_200)
            let wick = abs(hhGaussian(&rng)) * volatilityState * 0.7
            let high = max(open, close) * (1 + wick * 0.6)
            let low = min(open, close) * (1 - wick * 0.6)
            let turnover = 0.006 + abs(closeChange) * 0.7 + rng.double01() * 0.012
            let volume = (listing.sharesOutstanding * max(0.0005, turnover)).rounded()

            listing.sharePrice = close
            listing.dailyChange = close - previousPrice
            listing.dailyChangePercent = previousPrice > 0 ? (close - previousPrice) / previousPrice : 0
            listing.volume = volume
            listing.volatilityState = volatilityState
            listing.beta = hhClamp(beta + (firm.kind == .techStudio ? 0.004 : -0.001) * 0.5, 0.35, 2.6)
            listing.earningsSurprise = hhClamp(growth - 0.01 + (rng.double01() - 0.5) * 0.04, -0.2, 0.2)
            listing.insiderSales = hhClamp(
                listing.insiderSales * 0.86 + (risk > 0.35 ? rng.double01() * 0.12 : -0.02),
                0, 1
            )
            listing.priceTarget = hhClamp(fair * (0.94 + rng.double01() * 0.12), 0.2, 1_500)
            listing.bidAskSpread = hhClamp(
                0.0035 + volatilityState * 0.12 + (1 - liquidity) * 0.004,
                0.001,
                0.04
            )
            listing.fundamentals = fundamentals
            listing.priceHistory.append(close)
            listing.priceHistory = Array(listing.priceHistory.suffix(40))
            listing.bars.append(PriceBar(day: day, open: open, high: high, low: low, close: close, volume: volume))
            listing.bars = Array(listing.bars.suffix(40))
            market.listings[index] = listing
        }

        // 4. Shorts pay borrow fees and can be squeezed out.
        for positionIndex in market.shortPositions.indices {
            market.shortPositions[positionIndex].peakPrice = max(
                market.shortPositions[positionIndex].peakPrice,
                market.listings.first(where: { $0.businessID == market.shortPositions[positionIndex].businessID })?.sharePrice ?? 0
            )
        }
        settleShorts(market: &market, rng: &rng)
        refreshShortInterest(&market)

        // 5. Long margin: interest, dividends, and forced liquidation.
        for index in market.holdings.indices.reversed() {
            var holding = market.holdings[index]
            guard let listing = market.listings.first(where: { $0.businessID == holding.businessID }) else {
                continue
            }
            let price = listing.sharePrice
            let value = holding.marketValue(price: price)
            if holding.marginDebt > 0 {
                let implied = value / max(0.01, value - holding.marginDebt)
                let tierRate = LeverageLadder.borrowRate(for: min(10, max(2, implied)))
                let dailyRate = (max(0, interestRate) + tierRate) / 365
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
            let implied = value / max(0.01, max(0.01, equity))
            let maintenance = LeverageLadder.maintenanceRatio(for: min(10, max(2, implied)))
            if holding.marginDebt > 0.5, value > 0, equity < value * max(0.12, maintenance) {
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

        // 6. The index: a weighted tape of every living firm.
        let active = market.listings.filter { !$0.isBankrupt }
        let averagePrice = active.isEmpty
            ? 0
            : active.map(\.sharePrice).reduce(0, +) / Double(active.count)
        let previousIndex = market.marketIndex
        // Chain-link the index from the equal-weighted return of the firms that
        // were already trading this morning, so a new listing cannot jump the
        // tape and a failure cannot fake a crash.
        let survivorIDs = Set(activeBefore.map(\.businessID))
        let survivorReturns = market.listings
            .filter { survivorIDs.contains($0.businessID) && !$0.isBankrupt }
            .map(\.dailyChangePercent)
        let survivorMove = survivorReturns.isEmpty
            ? 0
            : survivorReturns.reduce(0, +) / Double(survivorReturns.count)
        if previousIndex > 0 {
            market.marketIndex = hhClamp(previousIndex * (1 + hhClamp(survivorMove, -0.2, 0.2)), 1, 100_000)
        }
        let indexOpen = market.indexBars.last?.close ?? previousIndex
        let indexHigh = max(indexOpen, market.marketIndex) * (1 + abs(commonShock) * 0.4)
        let indexLow = min(indexOpen, market.marketIndex) * (1 - abs(commonShock) * 0.4)
        market.indexBars.append(
            PriceBar(
                day: day,
                open: indexOpen,
                high: indexHigh,
                low: indexLow,
                close: market.marketIndex,
                volume: active.reduce(0) { $0 + $1.volume }
            )
        )
        market.indexBars = Array(market.indexBars.suffix(40))
        market.marketHistory.append(market.marketIndex)
        market.marketHistory = Array(market.marketHistory.suffix(40))
        market.volatilityIndex = hhClamp(
            (market.indexBars.volatility(20) * 1_400) + (1 - market.sentiment) * 10 + market.competitionHeat * 6,
            8,
            90
        )

        // 7. Sentiment, regime, factors.
        let averageChange = market.listings.isEmpty
            ? 0
            : market.listings.map(\.dailyChangePercent).reduce(0, +) / Double(market.listings.count)
        let targetSentiment = hhClamp(
            0.42
                + consumerConfidence * 0.26
                + (1 - crime) * 0.08
                - max(0, inflation - 0.05) * 0.5
                - max(0, interestRate - 0.05) * 0.9
                + averageChange * 1.0
                + (1 - corruption) * 0.04
                - (taxRate - 0.17) * 0.4,
            0.05, 1
        )
        market.sentiment = hhClamp(market.sentiment * 0.72 + targetSentiment * 0.28, 0.05, 1)
        market.regime = MarketRegime.classify(
            indexChange: market.todayChangePercent,
            volatility: market.indexBars.volatility(20),
            sentiment: market.sentiment
        )
        market.sessionsPlayed += 1
        market.trades = Array(market.trades.prefix(48))

        var contextEconomy = self
        contextEconomy.market = nil
        let shortInterest = market.listings.isEmpty
            ? 0
            : market.listings.map(\.shortInterest).reduce(0, +) / Double(market.listings.count)
        let worstShort = market.listings.map(\.shortInterest).max() ?? 0
        let breadth = market.breadth
        let context = MarketFactorContext(
            economy: contextEconomy,
            sentiment: market.sentiment,
            volatility: market.indexBars.volatility(20),
            indexChange: market.todayChangePercent,
            breadth: breadth,
            shortInterest: shortInterest,
            worstShortInterest: worstShort,
            liquidity: liquidity,
            day: day
        )
        let readouts = MarketFactorModel.catalogue.map { spec in
            let outcome = spec.probe(context)
            return MarketFactorReadout(
                id: spec.id,
                title: spec.title,
                group: spec.group,
                valueText: outcome.value,
                score: outcome.score,
                impactBps: outcome.impactBps,
                note: outcome.note
            )
        }
        let totalBps = readouts.reduce(0) { $0 + $1.impactBps }
        market.factorBook = MarketFactorBook(
            day: day,
            readouts: readouts,
            indexImpactBps: totalBps,
            regime: market.regime,
            updatedAt: day
        )
        market.policyReport = policyReport
        market.rumour = rumour(of: market)
        market.portfolioHistory.append(
            PortfolioPoint(
                day: day,
                value: market.marketValue + market.shortCollateral,
                cost: market.costBasis,
                debt: market.marginDebt
            )
        )
        market.portfolioHistory = Array(market.portfolioHistory.suffix(40))
        market.lastUpdateDay = day
        self.market = market
    }

    /// A one-line story the exchange puts at the top of the page every morning.
    private func rumour(of market: InvestmentMarket) -> String {
        if let notice = market.lastNotice, notice.contains("Margin call") || notice.contains("squeeze") {
            return notice
        }
        let movers = market.listings.filter { !$0.isBankrupt }
        if let best = movers.max(by: { $0.dailyChangePercent < $1.dailyChangePercent }),
           let worst = movers.min(by: { $0.dailyChangePercent < $1.dailyChangePercent }) {
            if best.dailyChangePercent > 0.03 {
                return "\(best.name) leads the square, up \(Int((best.dailyChangePercent * 100).rounded()))%."
            }
            if worst.dailyChangePercent < -0.03 {
                return "\(worst.name) drags the tape down \(Int((worst.dailyChangePercent * -100).rounded()))%."
            }
        }
        if market.competitionHeat > 0.5 {
            return "A price war is chewing through margins across the square."
        }
        if let policy = market.policyReport, abs(policy.indexPercent) > 1 {
            return policy.headline
        }
        return market.regime.blurb
    }

    /// Marketing and compliance costs taken out of every firm by the rivals'
    /// behaviour on the day.
    private func marketingDrag(market: InvestmentMarket) -> Double {
        Double(market.listings.count) * market.competitorMarketing * 0.0006
    }
}
