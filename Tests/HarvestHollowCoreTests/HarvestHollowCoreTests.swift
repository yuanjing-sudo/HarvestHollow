import XCTest
@testable import HarvestHollowCore

final class HarvestHollowCoreTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Helpers

    final class TestClock {
        var now: Date
        init(_ date: Date) { now = date }
        func advance(_ seconds: Double) { now = now.addingTimeInterval(seconds) }
    }

    func makeEngine(
        seed: UInt64 = 7,
        configure: (inout GameState) -> Void = { _ in }
    ) -> (GameEngine, TestClock) {
        let clock = TestClock(fixedDate)
        var state = GameState.newGame(now: fixedDate, seed: seed)
        configure(&state)
        state.lastTick = fixedDate
        let engine = GameEngine(state: state, clock: { clock.now })
        return (engine, clock)
    }

    func growWheat(_ engine: GameEngine, clock: TestClock, plot: Int = 0) {
        XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: plot).isSuccess)
        XCTAssertTrue(engine.water(plotID: plot).isSuccess)
        clock.advance(120)
        engine.simulate()
        XCTAssertTrue(engine.state.plots[plot].crop?.isReady == true)
    }

    // MARK: - New game

    func testNewGameStartsWithAStarterFarm() {
        let state = GameState.newGame(now: fixedDate, seed: 1)
        XCTAssertEqual(state.coins, GameConstants.startingCoins)
        XCTAssertEqual(state.level, 1)
        XCTAssertEqual(state.day, 1)
        XCTAssertEqual(state.plots.count, GameConstants.farmPlotCount)
        XCTAssertEqual(state.plots.filter(\.unlocked).count, GameConstants.startingPlots)
        XCTAssertEqual(state.pens.filter(\.unlocked).count, GameConstants.startingPens)
        XCTAssertEqual(state.inventory["seed.wheat"], 4)
        XCTAssertEqual(state.inventory["supply.feed"], 2)
        XCTAssertNotNil(state.dailyOrder)
        XCTAssertEqual(state.quests.storyIndex, 0)
        XCTAssertTrue(state.themesOwned.contains("cozy"))
    }

    // MARK: - Crops

    func testPlantingConsumesSeedAndWaterIsRequiredForGrowth() {
        let (engine, clock) = makeEngine()
        let result = engine.plant(cropID: "wheat", inPlot: 0)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(engine.state.inventory["seed.wheat"], 3)
        XCTAssertEqual(engine.state.stats.cropsPlanted, 1)
        XCTAssertFalse(engine.state.plots[0].crop?.watered ?? true)

        clock.advance(45)
        engine.simulate()
        XCTAssertEqual(engine.state.plots[0].crop?.growth ?? -1, 0, accuracy: 0.0001)

        XCTAssertTrue(engine.water(plotID: 0).isSuccess)
        clock.advance(10)
        engine.simulate()
        let growth = engine.state.plots[0].crop?.growth ?? 0
        XCTAssertGreaterThan(growth, 0)
        XCTAssertLessThan(growth, 1)
    }

    func testHarvestAddsProduceAndClearsThePlot() {
        let (engine, clock) = makeEngine()
        growWheat(engine, clock: clock)

        let result = engine.harvest(plotID: 0)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertNil(engine.state.plots[0].crop)
        let harvested = engine.state.inventory["crop.wheat"] ?? 0
        XCTAssertGreaterThanOrEqual(harvested, 2)
        XCTAssertGreaterThanOrEqual(engine.state.stats.cropsHarvested, 2)
        XCTAssertGreaterThanOrEqual(engine.state.stats.coinsEarned, 0)
        XCTAssertGreaterThan(engine.state.xp, 0)
    }

    func testHarvestRequiresReadyCrop() {
        let (engine, clock) = makeEngine()
        XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: 0).isSuccess)
        XCTAssertTrue(engine.water(plotID: 0).isSuccess)
        clock.advance(5)
        engine.simulate()
        let result = engine.harvest(plotID: 0)
        XCTAssertFalse(result.isSuccess)
        XCTAssertTrue(result.message.contains("not ready"))
    }

    func testHarvestAllAndWaterAll() {
        let (engine, clock) = makeEngine()
        for plot in 0..<4 {
            XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: plot).isSuccess)
        }
        XCTAssertTrue(engine.waterAll().isSuccess)
        clock.advance(120)
        engine.simulate()

        let result = engine.harvestAll()
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertTrue(engine.state.plots.prefix(4).allSatisfy { $0.crop == nil })
        XCTAssertGreaterThanOrEqual(engine.state.inventory["crop.wheat"] ?? 0, 8)
    }

    func testFertilizerAddsYieldAndConsumesSupply() {
        let (engine, clock) = makeEngine()
        XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: 0).isSuccess)
        XCTAssertTrue(engine.water(plotID: 0).isSuccess)
        XCTAssertTrue(engine.fertilize(plotID: 0).isSuccess)
        XCTAssertNil(engine.state.inventory["supply.fertilizer"])
        XCTAssertTrue(engine.state.plots[0].crop?.fertilized == true)

        clock.advance(120)
        engine.simulate()
        let result = engine.harvest(plotID: 0)
        XCTAssertTrue(result.isSuccess)
        // Base yield 2...4 plus one from fertilizer. 22% chance of a bonus seed.
        XCTAssertGreaterThanOrEqual(engine.state.inventory["crop.wheat"] ?? 0, 3)
    }

    func testRainWatersEverythingAtTheStartOfADay() {
        let (engine, clock) = makeEngine(seed: 7)
        for plot in 0..<3 {
            XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: plot).isSuccess)
            XCTAssertTrue(engine.water(plotID: plot).isSuccess)
        }

        // Roll forward until at least one rainy day has begun.
        var sawRain = false
        for _ in 0..<40 {
            clock.advance(GameConstants.dayLength)
            engine.simulate()
            if engine.state.weather == .rainy {
                sawRain = true
                break
            }
        }
        XCTAssertTrue(sawRain, "Weather should eventually include rain")
        for plot in engine.state.plots where plot.crop != nil {
            XCTAssertTrue(plot.crop?.watered == true)
        }
    }

    // MARK: - Animals

    func testAdoptingFeedingAndCollectingFromAChicken() {
        let (engine, clock) = makeEngine { state in
            state.level = 2
            state.coins = 2_000
        }

        let adopt = engine.adoptAnimal(speciesID: "chicken", penID: 0)
        XCTAssertTrue(adopt.isSuccess, adopt.message)
        XCTAssertEqual(engine.state.coins, 1_600)
        XCTAssertEqual(engine.state.stats.animalsBought, 1)
        XCTAssertNotNil(engine.state.pens[0].animal)

        let feed = engine.feed(penID: 0)
        XCTAssertTrue(feed.isSuccess, feed.message)
        XCTAssertEqual(engine.state.inventory["supply.feed"], 1)

        clock.advance(120)
        engine.simulate()
        let stored = engine.state.pens[0].animal?.stored ?? 0
        XCTAssertGreaterThanOrEqual(stored, 2)

        let collect = engine.collect(penID: 0)
        XCTAssertTrue(collect.isSuccess, collect.message)
        XCTAssertEqual(engine.state.pens[0].animal?.stored, 0)
        XCTAssertEqual(engine.state.inventory["product.egg"], stored)
        XCTAssertEqual(engine.state.stats.animalProducts, stored)
    }

    func testAnimalCannotBeAdoptedWithoutLevelOrCoins() {
        let (engine, _) = makeEngine()
        let result = engine.adoptAnimal(speciesID: "chicken", penID: 0)
        XCTAssertFalse(result.isSuccess)
        XCTAssertTrue(result.message.contains("level 2"))

        let (richLevelOne, _) = makeEngine { state in
            state.level = 2
            state.coins = 10
        }
        let broke = richLevelOne.adoptAnimal(speciesID: "chicken", penID: 0)
        XCTAssertFalse(broke.isSuccess)
        XCTAssertTrue(broke.message.contains("more coins"))
    }

    func testAllAnimalsCanBePurchasedAtTheirLevel() {
        let (engine, _) = makeEngine { state in
            state.level = 6
            state.coins = 20_000
            for index in state.pens.indices { state.pens[index].unlocked = true }
        }

        for (index, species) in GameCatalog.standard.animals.enumerated() {
            let result = engine.adoptAnimal(speciesID: species.id, penID: index)
            XCTAssertTrue(result.isSuccess, "\(species.id): \(result.message)")
        }
        XCTAssertEqual(engine.state.pens.compactMap(\.animal).count, GameCatalog.standard.animals.count)
    }

    // MARK: - Economy

    func testSellingUsesMarketPriceAndTracksStats() {
        let (engine, _) = makeEngine { state in
            state.inventory["crop.wheat"] = 5
        }
        let unit = engine.sellPrice(for: "crop.wheat")
        let before = engine.state.coins
        let result = engine.sell(itemID: "crop.wheat", quantity: 2)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.state.coins, before + unit * 2)
        XCTAssertEqual(engine.state.inventory["crop.wheat"], 3)
        XCTAssertEqual(engine.state.stats.itemsSold, 2)
        XCTAssertEqual(engine.state.stats.coinsEarned, unit * 2)
        XCTAssertEqual(engine.state.stats.soldByItem["crop.wheat"], 2)
    }

    func testMarketPricesAreDeterministicAndWithinRange() {
        for day in 1...20 {
            for item in GameCatalog.standard.sellableItems {
                let value = Market.multiplier(itemID: item.id, day: day)
                XCTAssertGreaterThanOrEqual(value, 0.82)
                XCTAssertLessThanOrEqual(value, 1.28)
                XCTAssertEqual(value, Market.multiplier(itemID: item.id, day: day))
            }
        }
    }

    func testComfortImprovesSellPrice() {
        let (plain, _) = makeEngine()
        let base = plain.sellPrice(for: "crop.wheat")
        let (decorated, _) = makeEngine { state in
            state.house.placed = [
                PlacedFurniture(id: UUID(), itemID: "furniture.bed", x: 0, y: 0),
                PlacedFurniture(id: UUID(), itemID: "furniture.piano", x: 3, y: 0)
            ]
        }
        XCTAssertGreaterThan(decorated.comfort, 0)
        XCTAssertGreaterThanOrEqual(decorated.sellPrice(for: "crop.wheat"), base)
    }

    func testDailyOrderCompletesWhenTheRightGoodsAreSold() throws {
        let (engine, _) = makeEngine { state in
            guard let order = state.dailyOrder else { return }
            state.inventory[order.itemID] = order.target + 2
        }
        let order = try XCTUnwrap(engine.state.dailyOrder)
        let before = engine.state.coins
        let result = engine.sell(itemID: order.itemID, quantity: order.target)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertTrue(engine.state.dailyOrder?.completed == true)
        XCTAssertGreaterThan(engine.state.coins, before)
        let events = engine.drainEvents()
        XCTAssertTrue(events.contains {
            if case .dailyOrderCompleted = $0 { return true }
            return false
        })
    }

    func testCannotSellItemsYouDoNotOwnOrFurniture() {
        let (engine, _) = makeEngine()
        XCTAssertFalse(engine.sell(itemID: "crop.wheat", quantity: 1).isSuccess)
        XCTAssertFalse(engine.sell(itemID: "furniture.chair", quantity: 1).isSuccess)
        XCTAssertFalse(engine.sell(itemID: "nope", quantity: 1).isSuccess)
    }

    func testBuyingSeedsAndSupplies() {
        let (engine, _) = makeEngine { state in
            state.coins = 1_000
        }
        let result = engine.buySeed(cropID: "carrot", quantity: 3)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(engine.state.inventory["seed.carrot"], 6)
        XCTAssertEqual(engine.state.coins, 1_000 - 75)

        XCTAssertTrue(engine.buySupply("supply.feed", quantity: 2).isSuccess)
        XCTAssertEqual(engine.state.inventory["supply.feed"], 4)
    }

    func testLockedCropsCannotBeBoughtAtLevelOne() {
        let (engine, _) = makeEngine()
        let result = engine.buySeed(cropID: "strawberry")
        XCTAssertFalse(result.isSuccess)
        XCTAssertTrue(result.message.contains("level 2"))
        XCTAssertFalse(engine.plant(cropID: "moonberry", inPlot: 0).isSuccess)
    }

    // MARK: - Land

    func testBuyingPlotsUnlocksThemAndRaisesThePrice() {
        let (engine, _) = makeEngine { state in
            state.level = 2
            state.coins = 1_000
        }
        let startingPrice = engine.plotPrice()
        let result = engine.buyPlot(6)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertTrue(engine.state.plots[6].unlocked)
        XCTAssertEqual(engine.state.coins, 1_000 - startingPrice)
        XCTAssertGreaterThan(engine.plotPrice(), startingPrice)
    }

    func testBuyingPensRequiresLevelTwo() {
        let (low, _) = makeEngine { state in state.coins = 5_000 }
        XCTAssertFalse(low.buyPen(2).isSuccess)

        let (high, _) = makeEngine { state in
            state.level = 2
            state.coins = 5_000
        }
        XCTAssertTrue(high.buyPen(2).isSuccess)
        XCTAssertTrue(high.state.pens[2].unlocked)
    }

    // MARK: - House

    func testFurniturePlacementComfortAndPickup() {
        let (engine, _) = makeEngine()
        XCTAssertTrue(engine.placeFurniture(itemID: "furniture.chair", x: 0, y: 0).isSuccess)
        XCTAssertTrue(engine.placeFurniture(itemID: "furniture.plant", x: 2, y: 0).isSuccess)
        XCTAssertEqual(engine.comfort, 5)
        XCTAssertEqual(engine.state.stats.decorationsPlaced, 2)

        let overlap = engine.placeFurniture(itemID: "furniture.chair", x: 0, y: 0)
        XCTAssertFalse(overlap.isSuccess)

        guard let placed = engine.state.house.placed.first else {
            return XCTFail("Expected furniture in the room")
        }
        XCTAssertTrue(engine.removeFurniture(id: placed.id).isSuccess)
        XCTAssertEqual(engine.state.inventory["furniture.chair"], 1)
        XCTAssertEqual(engine.comfort, 3)
    }

    func testFurnitureMustFitInsideTheRoom() {
        let (engine, _) = makeEngine()
        XCTAssertFalse(engine.placeFurniture(itemID: "furniture.bed", x: 11, y: 7).isSuccess)
        XCTAssertFalse(engine.placeFurniture(itemID: "furniture.chair", x: -1, y: 0).isSuccess)
    }

    func testThemesMustBePurchasedAndCanBeApplied() {
        let (engine, _) = makeEngine { state in
            state.coins = 2_000
        }
        XCTAssertFalse(engine.applyTheme("meadow").isSuccess)
        let buy = engine.buyTheme("meadow")
        XCTAssertTrue(buy.isSuccess, buy.message)
        XCTAssertTrue(engine.state.themesOwned.contains("meadow"))
        XCTAssertEqual(engine.state.house.themeID, "meadow")
        XCTAssertTrue(engine.applyTheme("cozy").isSuccess)
        XCTAssertEqual(engine.state.house.themeID, "cozy")
    }

    // MARK: - Quests & progression

    func testFirstStoryQuestCompletesFromPlantingAndHarvesting() {
        let (engine, clock) = makeEngine()
        for plot in 0..<3 {
            XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: plot).isSuccess)
            XCTAssertTrue(engine.water(plotID: plot).isSuccess)
        }
        clock.advance(120)
        engine.simulate()
        XCTAssertTrue(engine.harvestAll().isSuccess)

        XCTAssertEqual(engine.state.quests.storyIndex, 1)
        XCTAssertTrue(engine.state.quests.completedIDs.contains("story.01"))
        XCTAssertEqual(engine.state.stats.questsCompleted, 1)
        XCTAssertEqual(engine.state.inventory["seed.carrot"], 8)
        XCTAssertGreaterThanOrEqual(engine.state.coins, GameConstants.startingCoins + 60)
    }

    func testLevelUpGrantsCoinsAndUnlocksContent() {
        let (engine, _) = makeEngine { state in
            state.xp = 89
        }
        XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: 0).isSuccess)
        XCTAssertEqual(engine.state.level, 2)
        XCTAssertEqual(engine.state.xp, 1)
        XCTAssertEqual(engine.state.coins, GameConstants.startingCoins + 80)

        XCTAssertTrue(engine.buySeed(cropID: "strawberry").isSuccess)
    }

    func testQuestChainAdvancesThroughAnimalQuest() {
        let (engine, clock) = makeEngine { state in
            state.level = 2
            state.coins = 3_000
            state.stats.cropsPlanted = 3
            state.stats.cropsHarvested = 2
            state.stats.itemsSold = 8
            state.quests.storyIndex = 2
        }
        let result = engine.adoptAnimal(speciesID: "chicken", penID: 0)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(engine.state.quests.storyIndex, 3)
        XCTAssertEqual(engine.state.stats.questsCompleted, 1)
    }

    // MARK: - Time & persistence

    func testOfflineSimulationGrowsCropsAndFillsPens() throws {
        let (engine, clock) = makeEngine { state in
            state.level = 2
            state.coins = 2_000
        }

        XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: 0).isSuccess)
        XCTAssertTrue(engine.water(plotID: 0).isSuccess)
        XCTAssertTrue(engine.adoptAnimal(speciesID: "chicken", penID: 0).isSuccess)
        XCTAssertTrue(engine.feed(penID: 0).isSuccess)

        clock.advance(8 * 60 * 60)
        engine.simulate()

        XCTAssertTrue(engine.state.plots[0].crop?.isReady == true)
        XCTAssertGreaterThan(engine.state.day, 1)
        let stored = try XCTUnwrap(engine.state.pens[0].animal?.stored)
        XCTAssertGreaterThan(stored, 0)
        XCTAssertLessThanOrEqual(stored, 3)
    }

    func testSaveLoadRoundTripAndExportImport() throws {
        let (engine, _) = makeEngine { state in
            state.coins = 1_234
            state.day = 5
            state.inventory["crop.carrot"] = 9
            state.house.themeID = "cozy"
        }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HarvestHollowTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SaveStore(url: directory.appendingPathComponent("save.json"))
        try store.save(engine.state, at: fixedDate)
        let loaded = try XCTUnwrap(store.load())
        XCTAssertEqual(loaded.coins, 1_234)
        XCTAssertEqual(loaded.day, 5)
        XCTAssertEqual(loaded.inventory["crop.carrot"], 9)
        XCTAssertEqual(loaded.plots.count, engine.state.plots.count)

        let exported = try SaveCodec.exportString(loaded)
        let imported = try SaveCodec.importString(exported)
        XCTAssertEqual(imported.coins, 1_234)
        XCTAssertEqual(imported.inventory["crop.carrot"], 9)
    }

    func testCorruptAndFutureSavesAreRejected() throws {
        XCTAssertThrowsError(try SaveCodec.decode(Data("not json".utf8)))

        let state = GameState.newGame(now: fixedDate, seed: 2)
        let envelope = SaveEnvelope(version: 99, savedAt: fixedDate, state: state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(envelope)
        XCTAssertThrowsError(try SaveCodec.decode(data)) { error in
            XCTAssertEqual(error as? SaveError, .unsupportedVersion(99))
        }
    }

    func testSimulationIsIdempotentWhenTheClockDoesNotMove() {
        let (engine, _) = makeEngine()
        XCTAssertTrue(engine.water(plotID: 0).isSuccess == false)
        XCTAssertTrue(engine.plant(cropID: "wheat", inPlot: 0).isSuccess)
        XCTAssertTrue(engine.water(plotID: 0).isSuccess)
        engine.simulate()
        let growth = engine.state.plots[0].crop?.growth ?? 0
        engine.simulate()
        XCTAssertEqual(engine.state.plots[0].crop?.growth ?? -1, growth, accuracy: 0.0001)
    }

    // MARK: - Pixel art

    func testEverySpriteGridIsWellFormed() {
        XCTAssertGreaterThanOrEqual(SpriteLibrary.all.count, 30)
        for sprite in SpriteLibrary.all.values {
            XCTAssertEqual(sprite.rows.count, sprite.height, "\(sprite.key) height")
            for (index, row) in sprite.rows.enumerated() {
                XCTAssertEqual(row.count, sprite.width, "\(sprite.key) row \(index): \(row)")
                for character in row where character != "." {
                    XCTAssertNotNil(sprite.palette[character], "\(sprite.key) undefined \(character)")
                }
            }

            let visible = sprite.rows.reduce(0) { total, row in
                total + row.filter { $0 != "." }.count
            }
            XCTAssertEqual(sprite.cells.count, visible, "\(sprite.key) cells")
            XCTAssertGreaterThan(sprite.coloredCellCount, 20, "\(sprite.key) should be detailed")
        }
    }

    func testEveryCatalogSpriteExistsAndAnimalsUseManySquares() {
        let catalog = GameCatalog.standard
        for crop in catalog.crops {
            XCTAssertNotNil(SpriteLibrary.sprite(named: crop.spriteKey), crop.spriteKey)
        }
        for animal in catalog.animals {
            let sprite = SpriteLibrary.sprite(named: animal.spriteKey)
            XCTAssertNotNil(sprite, animal.spriteKey)
            XCTAssertGreaterThanOrEqual(sprite?.coloredCellCount ?? 0, 30, animal.spriteKey)
            XCTAssertGreaterThanOrEqual(sprite?.uniqueColorCount ?? 0, 4, animal.spriteKey)
        }
        for piece in catalog.furniture {
            XCTAssertNotNil(SpriteLibrary.sprite(named: piece.spriteKey), piece.spriteKey)
        }

        let pig = SpriteLibrary.sprite(named: "animal.pig")
        XCTAssertNotNil(pig)
        XCTAssertGreaterThanOrEqual(pig?.coloredCellCount ?? 0, 30)
        XCTAssertGreaterThanOrEqual(pig?.uniqueColorCount ?? 0, 4)
    }

    func testSpritesAreSquareGridsWithTransparentPadding() {
        let pig = SpriteLibrary.sprite(named: "animal.pig")
        XCTAssertEqual(pig?.width, 14)
        XCTAssertEqual(pig?.height, 12)
        XCTAssertTrue(pig?.rows.first?.allSatisfy { $0 == "." } == true)
    }
}
