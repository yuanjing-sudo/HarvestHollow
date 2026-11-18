import XCTest
@testable import HarvestHollowCore

final class InvestmentTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    private func inputs(day: Int, level: Int) -> EconomyInputs {
        EconomyInputs(
            day: day,
            level: level,
            weather: .sunny,
            season: .summer,
            coins: 900,
            cropCount: 6,
            readyCrops: 2,
            wateredCrops: 6,
            animalCount: 2,
            animalHappiness: 0.8,
            animalAffection: 0.5,
            storedGoods: 4,
            inventoryValue: 80
        )
    }

    func testExchangeListsEveryFirmWithFluentHistory() {
        let economy = ValleyEconomy(level: 4)
        let market = economy.investmentMarket
        XCTAssertEqual(market.listings.count, economy.aiBusinesses.count)
        XCTAssertFalse(market.listings.isEmpty)
        XCTAssertEqual(market.marketHistory.count, 1)
        for listing in market.listings {
            XCTAssertGreaterThan(listing.sharePrice, 0)
            XCTAssertGreaterThanOrEqual(listing.priceHistory.count, 2)
            XCTAssertGreaterThan(listing.sharesOutstanding, 0)
        }
    }

    func testSharePricesMoveWithFundamentalsEveryDay() {
        var economy = ValleyEconomy(level: 8)
        let before = economy.investmentMarket.listings.map(\.sharePrice)
        var rng = GameRNG(state: 42)
        _ = economy.advanceDay(inputs(day: 2, level: 8), rng: &rng)
        let after = economy.investmentMarket.listings.map(\.sharePrice)
        XCTAssertNotEqual(before, after)
        XCTAssertEqual(economy.investmentMarket.marketHistory.count, 2)
        XCTAssertTrue(economy.investmentMarket.listings.allSatisfy {
            !$0.priceHistory.isEmpty && $0.fundamentals.lastUpdatedDay == 2
        })
    }

    func testBuyAndSellSharesMoveCashAndRealizeGainOrLoss() {
        var economy = ValleyEconomy(level: 4)
        let listing = economy.investmentMarket.listings[0]
        let buy = economy.buyShares(
            businessID: listing.businessID,
            shares: 4,
            leverage: 1,
            availableCoins: 10_000
        )
        XCTAssertTrue(buy.success)
        XCTAssertLessThan(buy.cashDelta, 0)
        XCTAssertEqual(economy.investmentMarket.holdings.count, 1)
        let holding = economy.investmentMarket.holdings[0]
        XCTAssertEqual(holding.shares, 4, accuracy: 0.0001)
        XCTAssertEqual(holding.marginDebt, 0, accuracy: 0.0001)

        let sell = economy.sellShares(businessID: listing.businessID, shares: 2)
        XCTAssertTrue(sell.success)
        XCTAssertGreaterThan(sell.cashDelta, 0)
        XCTAssertEqual(economy.investmentMarket.holdings[0].shares, 2, accuracy: 0.0001)
        XCTAssertNotNil(sell.trade)
    }

    func testLeverageBorrowsPartOfThePurchaseAndUnlocksProgressively() {
        var low = ValleyEconomy(level: 1)
        let lowListing = low.investmentMarket.listings[0]
        XCTAssertEqual(low.maxInvestmentLeverage, 1, accuracy: 0.0001)
        let blocked = low.buyShares(
            businessID: lowListing.businessID,
            shares: 2,
            leverage: 2,
            availableCoins: 10_000
        )
        XCTAssertFalse(blocked.success)

        var economy = ValleyEconomy(level: 8)
        let listing = economy.investmentMarket.listings[0]
        XCTAssertEqual(economy.maxInvestmentLeverage, 3, accuracy: 0.0001)
        let buy = economy.buyShares(
            businessID: listing.businessID,
            shares: 4,
            leverage: 3,
            availableCoins: 10_000
        )
        XCTAssertTrue(buy.success)
        let holding = economy.investmentMarket.holding(for: listing.businessID)
        XCTAssertNotNil(holding)
        XCTAssertGreaterThan(holding?.marginDebt ?? 0, 0)
        let notional = 4 * listing.sharePrice
        XCTAssertLessThan(abs(buy.cashDelta), notional)
    }

    func testFallingPriceProducesARealizedLoss() {
        var economy = ValleyEconomy(level: 4)
        let listing = economy.investmentMarket.listings[0]
        let buy = economy.buyShares(
            businessID: listing.businessID,
            shares: 4,
            leverage: 1,
            availableCoins: 10_000
        )
        XCTAssertTrue(buy.success)
        guard let index = economy.market?.listings.firstIndex(where: { $0.businessID == listing.businessID }) else {
            return XCTFail("Listing disappeared")
        }
        economy.market?.listings[index].sharePrice *= 0.5
        let sell = economy.sellShares(businessID: listing.businessID, shares: 4)
        XCTAssertTrue(sell.success)
        XCTAssertLessThan(sell.cashDelta, abs(buy.cashDelta))
        XCTAssertLessThan(sell.trade?.realizedProfit ?? 0, 0)
        XCTAssertLessThan(economy.investmentMarket.realizedProfit, 0)
    }

    func testMarginCallForcesLiquidation() {
        var economy = ValleyEconomy(level: 8)
        let listing = economy.investmentMarket.listings[0]
        let buy = economy.buyShares(
            businessID: listing.businessID,
            shares: 10,
            leverage: 3,
            availableCoins: 10_000
        )
        XCTAssertTrue(buy.success)
        guard let index = economy.market?.listings.firstIndex(where: { $0.businessID == listing.businessID }) else {
            return XCTFail("Listing disappeared")
        }
        economy.market?.listings[index].sharePrice *= 0.1
        var rng = GameRNG(state: 9)
        economy.advanceMarket(inputs: inputs(day: 2, level: 8), rng: &rng)
        XCTAssertTrue(economy.investmentMarket.holdings.isEmpty)
        XCTAssertGreaterThan(economy.investmentMarket.forcedLiquidations, 0)
    }

    func testInsufficientCoinsCannotBuyShares() {
        var economy = ValleyEconomy(level: 4)
        let listing = economy.investmentMarket.listings[0]
        let result = economy.buyShares(
            businessID: listing.businessID,
            shares: 100,
            leverage: 1,
            availableCoins: 1
        )
        XCTAssertFalse(result.success)
        XCTAssertTrue(economy.investmentMarket.holdings.isEmpty)
    }

    func testForensicAuditCostsAndUpdatesTheRecord() {
        var economy = ValleyEconomy(level: 8)
        let listing = economy.investmentMarket.listings[0]
        var rng = GameRNG(state: 77)
        let result = economy.auditBusiness(id: listing.businessID, cost: 40, rng: &rng)
        XCTAssertTrue(result.success)
        XCTAssertEqual(economy.justiceLedger.auditsFunded, 1)
        XCTAssertEqual(economy.justiceLedger.lastAuditDay, economy.day)
        XCTAssertNotNil(economy.investmentMarket.listing(for: listing.businessID)?.auditNote)
    }

    func testCrimeAndFraudProduceCourtCases() {
        var economy = ValleyEconomy(level: 12)
        economy.crime = 0.9
        economy.corruption = 0.9
        economy.inequality = 0.9
        economy.poverty = 0.9
        var rng = GameRNG(state: 123)
        for _ in 0..<80 {
            _ = economy.advanceJustice(rng: &rng)
        }
        XCTAssertFalse(economy.justiceLedger.incidents.isEmpty)
        XCTAssertGreaterThan(economy.justiceLedger.totalLoss, 0)
        XCTAssertGreaterThan(economy.justiceLedger.openCases, 0)
    }

    func testEngineTradesSharesAndReturnsCashToTheFarm() {
        var state = GameState.newGame(now: fixedDate, seed: 15)
        state.level = 8
        state.economy.synchronize(level: 8)
        state.coins = 900
        let engine = GameEngine(state: state, clock: { self.fixedDate })
        let listing = engine.state.economy.investmentMarket.listings[0]
        let buy = engine.buyBusinessShares(
            businessID: listing.businessID,
            shares: 3,
            leverage: 1
        )
        XCTAssertTrue(buy.success)
        XCTAssertLessThan(engine.state.coins, 900)
        let sell = engine.sellBusinessShares(
            businessID: listing.businessID,
            shares: 3
        )
        XCTAssertTrue(sell.success)
        XCTAssertGreaterThan(engine.state.coins, 900 - Int(abs(buy.cashDelta)))
    }

    func testLegacySaveWithoutMarketIsUpgradedOnLoad() throws {
        var state = GameState.newGame(now: fixedDate, seed: 21)
        state.economy.market = nil
        state.economy.justice = nil
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertNil(decoded.economy.market)
        XCTAssertNil(decoded.economy.justice)
        let engine = GameEngine(state: decoded, clock: { self.fixedDate })
        XCTAssertNotNil(engine.state.economy.market)
        XCTAssertNotNil(engine.state.economy.justice)
        XCTAssertFalse(engine.state.economy.investmentMarket.listings.isEmpty)
    }

    func testMarketSurvivesSaveRoundTrip() throws {
        var state = GameState.newGame(now: fixedDate, seed: 18)
        state.level = 8
        state.economy.synchronize(level: 8)
        let listing = state.economy.investmentMarket.listings[0]
        _ = state.economy.buyShares(
            businessID: listing.businessID,
            shares: 2,
            leverage: 1,
            availableCoins: 10_000
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertNotNil(decoded.economy.market)
        XCTAssertEqual(decoded.economy.investmentMarket.holdings.count, 1)
        XCTAssertEqual(decoded.economy.justiceLedger.incidents.count, 0)
    }
}
