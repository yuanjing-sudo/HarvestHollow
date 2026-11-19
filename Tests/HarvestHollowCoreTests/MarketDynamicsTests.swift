import XCTest
@testable import HarvestHollowCore

final class MarketDynamicsTests: XCTestCase {
    private func inputs(day: Int, level: Int = 12) -> EconomyInputs {
        EconomyInputs(
            day: day,
            level: level,
            weather: .sunny,
            season: .summer,
            coins: 5_000,
            cropCount: 6,
            readyCrops: 2,
            wateredCrops: 6,
            animalCount: 3,
            animalHappiness: 0.8,
            animalAffection: 0.5,
            storedGoods: 6,
            inventoryValue: 120
        )
    }

    // MARK: - Factors

    func testFactorCataloguePricesHundredsOfInputs() {
        XCTAssertGreaterThanOrEqual(MarketFactorModel.factorCount, 140)
        var economy = ValleyEconomy(level: 12)
        var rng = GameRNG(state: 404)
        _ = economy.advanceDay(inputs(day: 2), rng: &rng)
        let book = economy.investmentMarket.factorBook
        XCTAssertNotNil(book)
        XCTAssertEqual(book?.readouts.count, MarketFactorModel.factorCount)
        XCTAssertEqual(
            Set(book?.readouts.map(\.id) ?? []).count,
            MarketFactorModel.factorCount,
            "Every factor id should be unique"
        )
        XCTAssertTrue(book?.readouts.allSatisfy { !$0.note.isEmpty } ?? false)
        XCTAssertFalse(book?.strongestDrivers.isEmpty ?? true)
        for group in MarketFactorGroup.allCases {
            XCTAssertFalse(book?.readouts(in: group).isEmpty ?? true, "\(group) has no factors")
        }
    }

    func testIndexBouncesInsteadOfTrendingOneWay() {
        var economy = ValleyEconomy(level: 12)
        var rng = GameRNG(state: 909)
        var changes: [Double] = []
        for offset in 0..<24 {
            _ = economy.advanceDay(inputs(day: offset + 2), rng: &rng)
            changes.append(economy.investmentMarket.todayChangePercent)
        }
        XCTAssertTrue(changes.contains { $0 > 0.002 }, "The index never rose")
        XCTAssertTrue(changes.contains { $0 < -0.002 }, "The index never fell")
        XCTAssertTrue(changes.allSatisfy { abs($0) <= 0.22 }, "The index moved beyond the circuit breaker band")
        XCTAssertGreaterThan(economy.investmentMarket.indexBars.count, 12)
    }

    func testCandlesCarryOpenHighLowCloseAndVolume() {
        var economy = ValleyEconomy(level: 12)
        var rng = GameRNG(state: 77)
        let before = economy.investmentMarket.listings[0].bars.count
        _ = economy.advanceDay(inputs(day: 2), rng: &rng)
        let listing = economy.investmentMarket.listings[0]
        XCTAssertEqual(listing.bars.count, before + 1)
        guard let bar = listing.bars.last else { return XCTFail("no candle") }
        XCTAssertGreaterThanOrEqual(bar.high, max(bar.open, bar.close))
        XCTAssertLessThanOrEqual(bar.low, min(bar.open, bar.close))
        XCTAssertGreaterThan(bar.volume, 0)
        XCTAssertEqual(bar.close, listing.sharePrice, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(listing.volatilityState, 0.001)
        XCTAssertGreaterThan(listing.priceTarget, 0)
    }

    // MARK: - Tax and politics

    func testTaxRiseCutsFirmProfitAndPricesTheMarketDown() {
        // Two identical valleys, two tax rates, one day of trading each: the
        // only difference in the tape should be the tax.
        var lowTax = ValleyEconomy(level: 12)
        var highTax = ValleyEconomy(level: 12)
        var lowRng = GameRNG(state: 31)
        var highRng = GameRNG(state: 31)
        _ = lowTax.advanceDay(inputs(day: 2), rng: &lowRng)
        _ = highTax.advanceDay(inputs(day: 2), rng: &highRng)
        XCTAssertTrue(highTax.setTaxRate(0.32))
        _ = lowTax.advanceDay(inputs(day: 3), rng: &lowRng)
        _ = highTax.advanceDay(inputs(day: 3), rng: &highRng)

        let report = highTax.investmentMarket.policyReport
        XCTAssertNotNil(report)
        XCTAssertLessThan(report?.indexPercent ?? 0, 0, "A tax rise should be priced as a headwind")
        XCTAssertTrue(report?.lines.contains { $0.kind == .corporateTax } ?? false)

        let lowProfit = lowTax.investmentMarket.listings.map(\.fundamentals.profit).reduce(0, +)
        let highProfit = highTax.investmentMarket.listings.map(\.fundamentals.profit).reduce(0, +)
        XCTAssertLessThan(highProfit, lowProfit, "Higher tax should leave firms with less profit")
        XCTAssertEqual(highTax.pricedPolicy.taxRate, 0.32, accuracy: 0.0001)
    }

    func testPublicSpendingAndSubsidiesLiftTheTape() {
        var economy = ValleyEconomy(level: 12)
        var rng = GameRNG(state: 55)
        _ = economy.advanceDay(inputs(day: 2), rng: &rng)
        XCTAssertTrue(economy.setPublicSpending(0.32))
        XCTAssertTrue(economy.setSubsidyRate(0.18))
        _ = economy.advanceDay(inputs(day: 3), rng: &rng)
        let report = economy.investmentMarket.policyReport
        XCTAssertNotNil(report)
        XCTAssertGreaterThan(report?.indexPercent ?? 0, 0, "Spending and subsidies should be a tailwind")
        XCTAssertTrue(report?.winners.isEmpty == false)
        XCTAssertGreaterThan(report?.dailyCoinImpact ?? 0, -10_000)
    }

    func testElectionForecastAddsToWholeAndPicksALeader() {
        let economy = ValleyEconomy(level: 16)
        let forecast = economy.electionForecast
        let total = PoliticalParty.allCases.reduce(0.0) { $0 + forecast.share(for: $1) }
        XCTAssertEqual(total, 1, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(forecast.share(for: forecast.leader), forecast.share(for: economy.rulingParty) - 0.0001)
        XCTAssertFalse(forecast.note.isEmpty)
        XCTAssertEqual(forecast.ordered.count, PoliticalParty.allCases.count)
    }

    func testElectionAdoptsAPlatformAndMovesPolicy() {
        var economy = ValleyEconomy(level: 16)
        economy.electionInDays = 1
        economy.taxRate = 0.05
        var rng = GameRNG(state: 12)
        _ = economy.advanceDay(inputs(day: 2, level: 16), rng: &rng)
        XCTAssertEqual(economy.rulingParty.taxBias, economy.taxRate, accuracy: 0.12)
        XCTAssertTrue(economy.eventHistory.contains { $0.kind == .election })
    }

    // MARK: - Leverage ladder

    func testLeverageLadderUnlocksWithLevel() {
        XCTAssertEqual(LeverageLadder.maxMultiple(level: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(LeverageLadder.maxMultiple(level: 4), 2, accuracy: 0.0001)
        XCTAssertEqual(LeverageLadder.maxMultiple(level: 8), 3, accuracy: 0.0001)
        XCTAssertEqual(LeverageLadder.maxMultiple(level: 12), 5, accuracy: 0.0001)
        XCTAssertEqual(LeverageLadder.maxMultiple(level: 16), 10, accuracy: 0.0001)
        XCTAssertEqual(LeverageLadder.maxShortMultiple(level: 16), 5, accuracy: 0.0001)
        XCTAssertEqual(LeverageLadder.maintenanceRatio(for: 10), 0.15, accuracy: 0.0001)
        let economy = ValleyEconomy(level: 16)
        XCTAssertEqual(economy.maxInvestmentLeverage, 10, accuracy: 0.0001)
        XCTAssertEqual(economy.maxShortLeverage, 5, accuracy: 0.0001)
        XCTAssertTrue(economy.shortSellingUnlocked)
    }

    // MARK: - Short selling

    func testShortSellingUnlocksAtVillageTier() {
        var economy = ValleyEconomy(level: 1)
        let listing = economy.investmentMarket.listings[0]
        let blocked = economy.shortShares(
            businessID: listing.businessID,
            shares: 2,
            leverage: 1,
            availableCoins: 10_000
        )
        XCTAssertFalse(blocked.success)
        XCTAssertFalse(economy.shortSellingUnlocked)
    }

    func testShortProfitsWhenThePriceFalls() {
        var economy = ValleyEconomy(level: 8)
        let listing = economy.investmentMarket.listings[0]
        let open = economy.shortShares(
            businessID: listing.businessID,
            shares: 4,
            leverage: 2,
            availableCoins: 20_000
        )
        XCTAssertTrue(open.success)
        XCTAssertEqual(economy.investmentMarket.shortPositions.count, 1)
        XCTAssertEqual(economy.investmentMarket.shortPositions[0].shares, 4, accuracy: 0.0001)
        let position = economy.investmentMarket.shortPositions[0]
        XCTAssertGreaterThan(position.collateral, 0)
        guard let index = economy.market?.listings.firstIndex(where: { $0.businessID == listing.businessID }) else {
            return XCTFail("listing vanished")
        }
        economy.market?.listings[index].sharePrice *= 0.6
        let cover = economy.coverShort(businessID: listing.businessID, shares: 4)
        XCTAssertTrue(cover.success)
        XCTAssertGreaterThan(cover.cashDelta, position.collateral)
        XCTAssertGreaterThan(cover.trade?.realizedProfit ?? 0, 0)
        XCTAssertTrue(economy.investmentMarket.shortPositions.isEmpty)
    }

    func testShortLosesWhenThePriceRises() {
        var economy = ValleyEconomy(level: 8)
        let listing = economy.investmentMarket.listings[0]
        _ = economy.shortShares(
            businessID: listing.businessID,
            shares: 4,
            leverage: 1,
            availableCoins: 20_000
        )
        guard let index = economy.market?.listings.firstIndex(where: { $0.businessID == listing.businessID }) else {
            return XCTFail("listing vanished")
        }
        economy.market?.listings[index].sharePrice *= 1.4
        let cover = economy.coverShort(businessID: listing.businessID, shares: 4)
        XCTAssertTrue(cover.success)
        XCTAssertLessThan(cover.trade?.realizedProfit ?? 0, 0)
    }

    func testShortBorrowFeesAccrueEveryMorning() {
        var economy = ValleyEconomy(level: 8)
        let listing = economy.investmentMarket.listings[0]
        _ = economy.shortShares(
            businessID: listing.businessID,
            shares: 3,
            leverage: 1,
            availableCoins: 20_000
        )
        var rng = GameRNG(state: 8)
        for offset in 0..<4 {
            _ = economy.advanceDay(inputs(day: offset + 2, level: 8), rng: &rng)
        }
        let fees = economy.investmentMarket.shortPositions.first?.totalBorrowFees ?? 0
        XCTAssertGreaterThan(fees, 0)
        XCTAssertGreaterThan(economy.investmentMarket.shortBorrowFees, 0)
    }

    func testShortSqueezeForcesACover() {
        var economy = ValleyEconomy(level: 12)
        let listing = economy.investmentMarket.listings[0]
        let open = economy.shortShares(
            businessID: listing.businessID,
            shares: 8,
            leverage: 5,
            availableCoins: 50_000
        )
        XCTAssertTrue(open.success)
        guard let index = economy.market?.listings.firstIndex(where: { $0.businessID == listing.businessID }) else {
            return XCTFail("listing vanished")
        }
        economy.market?.listings[index].sharePrice *= 2.4
        var rng = GameRNG(state: 4)
        economy.advanceMarket(inputs: inputs(day: 3), rng: &rng)
        XCTAssertTrue(economy.investmentMarket.shortPositions.isEmpty)
        XCTAssertGreaterThan(economy.investmentMarket.forcedLiquidations, 0)
        XCTAssertTrue(economy.investmentMarket.trades.contains { $0.side == .cover })
    }

    func testEngineShortAndCoverMoveFarmCoins() {
        var state = GameState.newGame(now: Date(timeIntervalSince1970: 1_800_000_000), seed: 91)
        state.level = 8
        state.economy.synchronize(level: 8)
        state.coins = 4_000
        let engine = GameEngine(state: state, clock: { Date(timeIntervalSince1970: 1_800_000_000) })
        let listing = engine.state.economy.investmentMarket.listings[0]
        let open = engine.shortBusinessShares(businessID: listing.businessID, shares: 2, leverage: 1)
        XCTAssertTrue(open.success)
        XCTAssertLessThan(engine.state.coins, 4_000)
        let cover = engine.coverBusinessShares(businessID: listing.businessID, shares: 2)
        XCTAssertTrue(cover.success)
        XCTAssertTrue(engine.state.economy.investmentMarket.shortPositions.isEmpty)
    }

    // MARK: - Competitors

    func testCompetitorDossiersExistAndReactToTheValley() {
        var economy = ValleyEconomy(level: 16)
        var rng = GameRNG(state: 2024)
        for offset in 0..<14 {
            _ = economy.advanceDay(inputs(day: offset + 2, level: 16), rng: &rng)
        }
        let profiles = economy.investmentMarket.competitors ?? []
        XCTAssertFalse(profiles.isEmpty)
        XCTAssertEqual(profiles.count, Set(profiles.map(\.businessID)).count)
        for profile in profiles {
            XCTAssertFalse(profile.dossier.isEmpty)
            XCTAssertFalse(profile.strategy.title.isEmpty)
            XCTAssertGreaterThanOrEqual(profile.threat, 0)
            XCTAssertLessThanOrEqual(profile.threat, 1)
            XCTAssertFalse(profile.momentumLine.isEmpty)
        }
        XCTAssertGreaterThanOrEqual(economy.investmentMarket.competitionHeat, 0)
        XCTAssertTrue(
            profiles.contains { !$0.recentActions.isEmpty },
            "Rivals should have taken at least one action in two weeks"
        )
    }

    // MARK: - Persistence

    func testMarketRoundTripKeepsCandlesShortsAndFactors() throws {
        var economy = ValleyEconomy(level: 12)
        var rng = GameRNG(state: 6)
        _ = economy.advanceDay(inputs(day: 2), rng: &rng)
        let listing = economy.investmentMarket.listings[0]
        _ = economy.shortShares(
            businessID: listing.businessID,
            shares: 2,
            leverage: 2,
            availableCoins: 30_000
        )
        let data = try JSONEncoder().encode(economy)
        let decoded = try JSONDecoder().decode(ValleyEconomy.self, from: data)
        let market = decoded.investmentMarket
        XCTAssertEqual(market.shortPositions.count, 1)
        XCTAssertEqual(market.listings[0].bars.count, economy.investmentMarket.listings[0].bars.count)
        XCTAssertEqual(market.factorBook?.readouts.count, MarketFactorModel.factorCount)
        XCTAssertNotNil(market.policyReport)
        XCTAssertFalse(market.competitors?.isEmpty ?? true)
        XCTAssertGreaterThan(market.volatilityIndex, 0)
        XCTAssertFalse(market.effectiveIndexBars.isEmpty)
    }

    func testOldMarketJSONWithoutNewKeysStillDecodes() throws {
        var economy = ValleyEconomy(level: 8)
        var rng = GameRNG(state: 3)
        _ = economy.advanceDay(inputs(day: 2, level: 8), rng: &rng)
        let data = try JSONEncoder().encode(economy.investmentMarket)
        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return XCTFail("market did not encode as an object")
        }
        for key in ["shorts", "indexBars", "factorBook", "policyReport", "competitors", "regime", "volatilityIndex"] {
            object.removeValue(forKey: key)
        }
        if var listings = object["listings"] as? [[String: Any]] {
            for index in listings.indices {
                for key in ["bars", "shortInterest", "beta", "volume", "priceTarget", "bidAskSpread"] {
                    listings[index].removeValue(forKey: key)
                }
            }
            object["listings"] = listings
        }
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(InvestmentMarket.self, from: legacy)
        XCTAssertFalse(decoded.listings.isEmpty)
        XCTAssertTrue(decoded.shortPositions.isEmpty)
        XCTAssertEqual(decoded.regime, .choppy)
        XCTAssertTrue(decoded.factorBook == nil)
        XCTAssertFalse(decoded.effectiveIndexBars.isEmpty)
        XCTAssertFalse(decoded.listings[0].effectiveBars.isEmpty)
    }
}
