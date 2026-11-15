import XCTest
@testable import HarvestHollowCore

final class EconomyTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testSubsistenceStartsWithOnlyBasicEconomicFactors() {
        let economy = ValleyEconomy(level: 1)
        XCTAssertEqual(economy.tier, .subsistence)
        XCTAssertEqual(EconomyFactor.allCases.count, 29)
        let unlocked = EconomyFactor.allCases.filter { economy.isUnlocked($0) }
        XCTAssertEqual(unlocked.count, 6)
        XCTAssertTrue(economy.isUnlocked(.landSoil))
        XCTAssertTrue(economy.isUnlocked(.playerProgression))
        XCTAssertFalse(economy.isUnlocked(.livestockHealth))
        XCTAssertFalse(economy.isUnlocked(.importsExports))
        XCTAssertEqual(economy.unlockedFactorCount, 6)
    }

    func testEveryFactorHasAReasonAndMostFeedSomethingElse() {
        for factor in EconomyFactor.allCases {
            XCTAssertFalse(factor.explanation.isEmpty)
            XCTAssertFalse(factor.title.isEmpty)
            XCTAssertGreaterThanOrEqual(factor.minimumLevel, 1)
        }
        XCTAssertTrue(EconomyFactor.cropTypesYields.dependencies.contains(.landSoil))
        XCTAssertTrue(EconomyFactor.supplyDemandPrices.dependencies.contains(.consumerDemand))
        XCTAssertTrue(EconomyFactor.happinessHealthEducation.dependencies.contains(.pollutionSustainability))
        XCTAssertTrue(EconomyFactor.playerProgression.dependencies.count >= 20)
    }

    func testLevelingUnlocksTiersAndPolicyAuthority() {
        var economy = ValleyEconomy(level: 1)
        let unlocked = economy.synchronize(level: 8)
        XCTAssertEqual(economy.tier, .marketTown)
        XCTAssertFalse(unlocked.isEmpty)
        XCTAssertTrue(economy.isUnlocked(.taxationSubsidies))
        XCTAssertTrue(economy.setTaxRate(0.24))
        XCTAssertEqual(economy.taxRate, 0.24, accuracy: 0.0001)
        XCTAssertTrue(economy.setPublicSpending(0.21))
        XCTAssertEqual(economy.publicSpending, 0.21, accuracy: 0.0001)
    }

    func testDailySimulationFeedsWeatherSoilSupplyAndPrices() {
        let state = GameState.newGame(now: fixedDate, seed: 42)
        var economy = state.economy
        var rng = GameRNG(state: state.rngState)
        let inputs = EconomyInputs(
            day: 2,
            level: 4,
            weather: .rainy,
            season: .spring,
            coins: 500,
            cropCount: 8,
            readyCrops: 2,
            wateredCrops: 8,
            animalCount: 2,
            animalHappiness: 0.8,
            animalAffection: 0.5,
            storedGoods: 3,
            inventoryValue: 40
        )
        let report = economy.advanceDay(inputs, rng: &rng)
        XCTAssertEqual(economy.day, 2)
        XCTAssertEqual(report.tier, .village)
        XCTAssertFalse(report.summary.isEmpty)
        XCTAssertGreaterThan(economy.farmYield, 0)
        XCTAssertGreaterThan(economy.supply, 0)
        XCTAssertGreaterThan(economy.demand, 0)
        XCTAssertGreaterThan(economy.priceIndex, 0)
        XCTAssertGreaterThan(economy.gdp, 0)
        XCTAssertEqual(economy.history.count, 2)
        XCTAssertTrue(economy.history.last!.day == 2)
    }

    func testInvestmentMovesLandWaterAndPollution() {
        var economy = ValleyEconomy(level: 8)
        let oldYield = economy.farmYield
        let oldIrrigation = economy.irrigation
        XCTAssertTrue(economy.invest(.irrigation))
        XCTAssertGreaterThan(economy.irrigation, oldIrrigation)
        XCTAssertGreaterThan(economy.farmYield, oldYield)
        let oldPollution = economy.pollution
        XCTAssertTrue(economy.invest(.cleanup))
        XCTAssertLessThan(economy.pollution, oldPollution)
    }

    func testLoansRequireUnlockAndCanBeRepaid() {
        var economy = ValleyEconomy(level: 1)
        XCTAssertFalse(economy.canBorrow(100))
        economy.synchronize(level: 8)
        XCTAssertTrue(economy.canBorrow(100))
        let loan = economy.takeLoan(amount: 100, purpose: "Irrigation", day: 3)
        XCTAssertNotNil(loan)
        XCTAssertEqual(economy.loans.count, 1)
        XCTAssertEqual(economy.totalLoanBalance, 100, accuracy: 0.0001)
        let paid = economy.repayLoan(id: loan!.id, amount: 40)
        XCTAssertEqual(paid, 40, accuracy: 0.0001)
        XCTAssertEqual(economy.totalLoanBalance, 60, accuracy: 0.0001)
    }

    func testSaveRoundTripIncludesTheWholeEconomy() throws {
        var state = GameState.newGame(now: fixedDate, seed: 8)
        state.economy.synchronize(level: 16)
        state.economy.takeLoan(amount: 200, purpose: "Roads", day: state.day)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(decoded.version, GameConstants.saveVersion)
        XCTAssertEqual(decoded.economy.tier, .regional)
        XCTAssertEqual(decoded.economy.loans.count, 1)
        XCTAssertEqual(decoded.economy.aiBusinesses.count, state.economy.aiBusinesses.count)
        XCTAssertEqual(decoded.economy.aiCitizens.count, state.economy.aiCitizens.count)
    }

    func testLegacySaveWithoutEconomyGetsACompatibleDefault() throws {
        var state = GameState.newGame(now: fixedDate, seed: 9)
        state.level = 9
        let data = try JSONEncoder().encode(state)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "economy")
        let stripped = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(GameState.self, from: stripped)
        XCTAssertEqual(decoded.version, GameConstants.saveVersion)
        XCTAssertEqual(decoded.economy.tier, .marketTown)
        XCTAssertTrue(decoded.economy.isUnlocked(.taxationSubsidies))
        XCTAssertEqual(decoded.economy.history.count, 1)
    }

    func testEnginePolicyAndLoanActionsUpdateTheFarmLedger() {
        var state = GameState.newGame(now: fixedDate, seed: 10)
        state.level = 8
        state.economy.synchronize(level: 8)
        state.coins = 900
        let engine = GameEngine(state: state, clock: { self.fixedDate })
        XCTAssertTrue(engine.setEconomyTaxRate(0.2))
        XCTAssertEqual(engine.state.economy.taxRate, 0.2, accuracy: 0.0001)
        XCTAssertTrue(engine.investInEconomy(.irrigation))
        XCTAssertLessThan(engine.state.coins, 900)
        XCTAssertTrue(engine.takeEconomyLoan(amount: 100))
        XCTAssertEqual(engine.state.economy.loans.count, 1)
    }
}
