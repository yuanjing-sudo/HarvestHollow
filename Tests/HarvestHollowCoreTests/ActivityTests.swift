import XCTest
@testable import HarvestHollowCore

final class ActivityTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    final class Clock {
        var now: Date
        init(_ date: Date) { now = date }
        func advance(_ seconds: Double) { now = now.addingTimeInterval(seconds) }
    }

    func makeEngine(
        seed: UInt64 = 11,
        configure: (inout GameState) -> Void = { _ in }
    ) -> (GameEngine, Clock) {
        let clock = Clock(fixedDate)
        var state = GameState.newGame(now: fixedDate, seed: seed)
        configure(&state)
        state.lastTick = fixedDate
        return (GameEngine(state: state, clock: { clock.now }), clock)
    }

    func animal(named name: String = "Pip") -> AnimalInstance {
        AnimalInstance(
            id: UUID(),
            speciesID: "chicken",
            name: name,
            fedUntil: nil,
            progress: 0,
            stored: 0,
            happiness: 70,
            acquiredAt: fixedDate
        )
    }

    // MARK: - New systems boot cleanly

    func testNewGameHasBaitForecastAndActivityState() {
        let state = GameState.newGame(now: fixedDate, seed: 2)
        XCTAssertEqual(state.inventory["supply.bait"], 6)
        XCTAssertEqual(state.activities.weatherHistory, [state.weather])
        XCTAssertEqual(state.activities.fishing.rodLevel, 1)
        XCTAssertEqual(state.activities.claimedAchievements.count, 0)
        XCTAssertEqual(GameConstants.saveVersion, 2)
        XCTAssertFalse(state.season.title.isEmpty)
    }

    func testActivityCatalogHasTheExpectedContent() {
        let catalog = GameCatalog.standard
        XCTAssertEqual(catalog.fish.count, 13)
        XCTAssertEqual(catalog.recipes.count, 18)
        XCTAssertEqual(catalog.achievements.count, 30)
        XCTAssertEqual(catalog.dailyGifts.count, 7)
        XCTAssertEqual(Set(catalog.fish.map(\.id)).count, 13)
        XCTAssertEqual(Set(catalog.recipes.map(\.id)).count, 18)
        XCTAssertEqual(Set(catalog.achievements.map(\.id)).count, 30)
        for fish in catalog.fish {
            XCTAssertNotNil(catalog.item(fish.itemID))
        }
        for recipe in catalog.recipes {
            XCTAssertNotNil(catalog.item(recipe.dishItemID))
            XCTAssertNotNil(SpriteLibrary.dish(recipe.dishItemID))
        }
    }

    // MARK: - Fishing

    func testFishingConsumesBaitAndRecordsTheCatch() {
        let (engine, _) = makeEngine()
        let before = engine.baitCount
        let result = engine.castLine(at: fixedDate)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.baitCount, before - 1)
        XCTAssertEqual(engine.state.activities.fishing.totalCasts, 1)
        XCTAssertEqual(engine.state.activities.fishing.totalCatches, 1)
        XCTAssertEqual(engine.state.activities.fishing.uniqueCatches, 1)
        XCTAssertEqual(engine.state.activities.fishing.recentCatches.count, 1)
        let record = engine.state.activities.fishing.recentCatches[0]
        XCTAssertGreaterThan(record.weight, 0)
        XCTAssertNotNil(engine.catalog.fishDefinition(record.fishID))
        XCTAssertGreaterThan(engine.state.inventory["fish.\(record.fishID)"] ?? 0, 0)
        XCTAssertGreaterThan(engine.state.xp, 0)
    }

    func testFishingWithoutBaitFailsWithoutChangingStats() {
        let (engine, _) = makeEngine { state in
            state.inventory["supply.bait"] = 0
        }
        let result = engine.castLine(at: fixedDate)
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(engine.state.activities.fishing.totalCasts, 0)
        XCTAssertEqual(engine.state.activities.fishing.totalCatches, 0)
    }

    func testRodUpgradeChecksLevelAndCoins() {
        let (engine, _) = makeEngine { state in
            state.level = 2
            state.coins = 1_000
        }
        let result = engine.upgradeFishingRod()
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.state.activities.fishing.rodLevel, 2)
        XCTAssertEqual(engine.state.coins, 780)
        XCTAssertEqual(engine.state.activities.lastRodUpgradeDay, 1)
    }

    func testFishingCollectsSupportingActivityData() {
        let (engine, clock) = makeEngine()
        var caught = 0
        for index in 0..<8 {
            clock.advance(2)
            if engine.castLine(at: clock.now).isSuccess {
                caught += 1
            }
            if engine.baitCount == 0 {
                XCTAssertTrue(engine.buySupply("supply.bait", quantity: 3).isSuccess)
            }
        }
        XCTAssertEqual(caught, 8)
        XCTAssertEqual(engine.state.activities.fishing.totalCatches, 8)
        XCTAssertFalse(engine.state.activities.fishing.catches.isEmpty)
        XCTAssertTrue(engine.state.activities.fishing.bestWeight.values.allSatisfy { $0 > 0 })
        XCTAssertNotNil(engine.rarestFishCaught)
    }

    // MARK: - Cooking

    func testCookingConsumesIngredientsAndAddsDish() {
        let (engine, _) = makeEngine { state in
            state.level = 5
            state.inventory["product.egg"] = 2
            state.inventory["crop.tomato"] = 2
        }
        let result = engine.cook(recipeID: "omelette", at: fixedDate)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.state.inventory["product.egg"], 1)
        XCTAssertEqual(engine.state.inventory["crop.tomato"], 1)
        XCTAssertEqual(engine.state.inventory["dish.omelette"], 1)
        XCTAssertEqual(engine.state.activities.cookedRecipeIDs["omelette"], 1)
        XCTAssertEqual(engine.state.activities.favoriteRecipeID, "omelette")
        XCTAssertEqual(engine.state.activities.dishesCooked, 1)
        XCTAssertEqual(engine.state.activities.uniqueRecipesCooked, 1)
    }

    func testCookingFailsWhenIngredientsAreMissing() {
        let (engine, _) = makeEngine { state in
            state.level = 5
        }
        let result = engine.cook(recipeID: "omelette")
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(engine.state.activities.dishesCooked, 0)
        XCTAssertEqual(engine.state.inventory["dish.omelette"] ?? 0, 0)
    }

    func testEatingDishAppliesBuffAndImprovesMarketPrice() {
        let (engine, _) = makeEngine { state in
            state.inventory["dish.honeyToast"] = 1
        }
        let before = engine.sellPrice(for: "crop.wheat")
        let result = engine.eatDish(itemID: "dish.honeyToast", at: fixedDate)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.state.activities.dishesEaten, 1)
        XCTAssertNotNil(engine.state.activities.activeBuff)
        XCTAssertEqual(engine.state.activities.activeBuff?.kind, .market)
        XCTAssertEqual(engine.state.inventory["dish.honeyToast"] ?? 0, 0)
        let after = engine.sellPrice(for: "crop.wheat")
        XCTAssertGreaterThanOrEqual(after, before)
        XCTAssertEqual(engine.foodBuffSecondsRemaining, 420)
    }

    func testEatingTheSameDishTwiceFailsWhenThePantryIsEmpty() {
        let (engine, _) = makeEngine { state in
            state.inventory["dish.omelette"] = 1
        }
        XCTAssertTrue(engine.eatDish(itemID: "dish.omelette", at: fixedDate).isSuccess)
        let second = engine.eatDish(itemID: "dish.omelette", at: fixedDate)
        XCTAssertFalse(second.isSuccess)
        XCTAssertEqual(engine.state.activities.dishesEaten, 1)
    }

    func testCookingAllPossibleDoesNotThrowWhenNothingIsCookable() {
        let (engine, _) = makeEngine()
        let result = engine.cookAllPossible()
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(engine.state.activities.dishesCooked, 0)
    }

    // MARK: - Daily gifts

    func testDailyGiftCanBeClaimedOnceAndBuildsAStreak() {
        let (engine, clock) = makeEngine()
        let coins = engine.state.coins
        XCTAssertTrue(engine.canClaimDailyGift)
        let first = engine.claimDailyGift()
        XCTAssertTrue(first.isSuccess, first.message)
        XCTAssertEqual(engine.state.coins, coins + 40)
        XCTAssertEqual(engine.state.activities.giftStreak, 1)
        XCTAssertEqual(engine.state.activities.giftsClaimed, 1)
        XCTAssertFalse(engine.claimDailyGift().isSuccess)

        clock.advance(GameConstants.dayLength + 1)
        engine.simulate()
        XCTAssertEqual(engine.state.day, 2)
        XCTAssertTrue(engine.canClaimDailyGift)
        XCTAssertEqual(engine.dailyGiftCycleDay, 2)
        XCTAssertTrue(engine.claimDailyGift().isSuccess)
        XCTAssertEqual(engine.state.activities.giftStreak, 2)
        XCTAssertEqual(engine.state.activities.giftsClaimed, 2)
    }

    func testMissingAGiftDayResetsTheStreak() {
        let (engine, clock) = makeEngine()
        XCTAssertTrue(engine.claimDailyGift().isSuccess)
        clock.advance(GameConstants.dayLength * 2 + 2)
        engine.simulate()
        XCTAssertGreaterThanOrEqual(engine.state.day, 3)
        XCTAssertTrue(engine.claimDailyGift().isSuccess)
        XCTAssertEqual(engine.state.activities.giftStreak, 1)
    }

    // MARK: - Achievements

    func testAchievementCanBeClaimedOnlyWhenCompleteAndOnlyOnce() {
        let (engine, _) = makeEngine { state in
            state.stats.cropsPlanted = 1
        }
        let before = engine.state.coins
        let first = engine.claimAchievement(id: "field.firstSprout")
        XCTAssertTrue(first.isSuccess, first.message)
        XCTAssertEqual(engine.state.coins, before + 30)
        XCTAssertTrue(engine.isAchievementClaimed("field.firstSprout"))
        XCTAssertEqual(engine.claimedAchievementCount, 1)
        XCTAssertFalse(engine.claimAchievement(id: "field.firstSprout").isSuccess)
    }

    func testIncompleteAchievementCannotBeClaimed() {
        let (engine, _) = makeEngine()
        let result = engine.claimAchievement(id: "field.greenThumb")
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(engine.claimedAchievementCount, 0)
    }

    func testClaimAllAchievementsClaimsOnlyReadyOnes() {
        let (engine, _) = makeEngine { state in
            state.stats.cropsPlanted = 1
            state.stats.cropsHarvested = 10
            state.stats.itemsSold = 1
        }
        let result = engine.claimAllAchievements()
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.claimedAchievementCount, 3)
        XCTAssertEqual(engine.claimableAchievementCount, 0)
    }

    func testAchievementProgressReadsFromFishingCookingAndGifts() {
        let (engine, _) = makeEngine { state in
            state.activities.fishing.totalCatches = 25
            state.activities.fishing.catches = ["minnow": 20, "koi": 5]
            state.activities.cookedRecipeIDs = ["omelette": 4, "honeyToast": 3]
            state.activities.giftsClaimed = 6
        }
        let progress = engine.achievementProgressList
        let reel = progress.first { $0.id == "pond.reelPro" }
        XCTAssertEqual(reel?.current, 25)
        XCTAssertEqual(reel?.isComplete, true)
        let gourmet = progress.first { $0.id == "market.gourmet" }
        XCTAssertEqual(gourmet?.current, 7)
        let gifts = progress.first { $0.id == "story.thankYou" }
        XCTAssertEqual(gifts?.current, 6)
    }

    // MARK: - Barn affection

    func testPettingRaisesAffectionAndRespectsCooldown() {
        let (engine, clock) = makeEngine { state in
            state.pens[0].unlocked = true
            state.pens[0].animal = self.animal()
        }
        let before = engine.state.pens[0].animal?.affection ?? 0
        let result = engine.pet(penID: 0, at: clock.now)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.state.pens[0].animal?.affection ?? 0, min(100, before + 8))
        XCTAssertEqual(engine.state.pens[0].animal?.petCount, 1)
        XCTAssertEqual(engine.state.activities.animalsPetted, 1)
        XCTAssertFalse(engine.pet(penID: 0, at: clock.now).isSuccess)

        clock.advance(91)
        XCTAssertTrue(engine.pet(penID: 0, at: clock.now).isSuccess)
        XCTAssertEqual(engine.state.pens[0].animal?.petCount, 2)
    }

    func testPetAllOnlyAffectsReadyAnimals() {
        let (engine, _) = makeEngine { state in
            for index in 0..<2 {
                state.pens[index].unlocked = true
                state.pens[index].animal = self.animal(named: "Friend \(index)")
            }
        }
        let result = engine.petAll(at: fixedDate)
        XCTAssertTrue(result.isSuccess, result.message)
        XCTAssertEqual(engine.state.activities.animalsPetted, 2)
        XCTAssertFalse(engine.petAll(at: fixedDate).isSuccess)
    }

    // MARK: - Weather & mastery

    func testTomorrowForecastBecomesTodaysWeather() {
        let (engine, clock) = makeEngine { state in
            state.nextWeather = .storm
        }
        XCTAssertEqual(engine.nextWeather, .storm)
        clock.advance(GameConstants.dayLength + 1)
        engine.simulate()
        XCTAssertEqual(engine.state.weather, .storm)
        XCTAssertTrue(engine.weatherHistory.contains(.storm))
        XCTAssertFalse(engine.state.activities.weatherHistory.isEmpty)
    }

    func testCropMasteryAddsSaleValue() {
        let (baseEngine, _) = makeEngine()
        let (masterEngine, _) = makeEngine { state in
            state.stats.harvestedByCrop["moonberry"] = 50
        }
        XCTAssertEqual(masterEngine.cropMasteryLevel("moonberry"), 4)
        XCTAssertGreaterThan(
            masterEngine.sellPrice(for: "crop.moonberry"),
            baseEngine.sellPrice(for: "crop.moonberry")
        )
        XCTAssertEqual(masterEngine.cropMasteryTier("moonberry").title, "Hollow Legend")
    }

    func testMasteryProgressReachesTheNextTier() {
        XCTAssertEqual(CropMastery.level(for: 0), 0)
        XCTAssertEqual(CropMastery.level(for: 6), 1)
        XCTAssertEqual(CropMastery.level(for: 15), 2)
        XCTAssertEqual(CropMastery.level(for: 30), 3)
        XCTAssertEqual(CropMastery.level(for: 50), 4)
        XCTAssertNil(CropMastery.nextTier(for: 50))
        XCTAssertEqual(CropMastery.progress(for: 3), 0.5, accuracy: 0.01)
    }

    // MARK: - Collections

    func testCollectionProgressMatchesTheFiveBookPages() {
        let (engine, _) = makeEngine { state in
            state.stats.harvestedByCrop["wheat"] = 1
            state.activities.fishing.catches = ["minnow": 1]
            state.activities.cookedRecipeIDs = ["omelette": 1]
            state.inventory["product.egg"] = 1
            state.stats.soldByItem["dish.honeyToast"] = 1
        }
        let catalog = engine.catalog
        let total = catalog.crops.count
            + catalog.fish.count
            + catalog.animals.count
            + catalog.recipes.count * 2
        let found = engine.discoveredCropCount
            + engine.uniqueFishCaught
            + engine.discoveredBarnGoodCount
            + engine.discoveredDishCount
            + engine.uniqueRecipesCooked
        XCTAssertEqual(engine.collectionProgress, Double(found) / Double(total), accuracy: 0.0001)
    }

    func testCollectionCountsComeFromActualActivity() {
        let (engine, _) = makeEngine { state in
            state.stats.harvestedByCrop["wheat"] = 2
            state.stats.harvestedByCrop["carrot"] = 1
            state.activities.fishing.catches = ["minnow": 1]
            state.activities.cookedRecipeIDs = ["omelette": 1]
            state.inventory["product.egg"] = 1
        }
        XCTAssertEqual(engine.discoveredCropCount, 2)
        XCTAssertGreaterThan(engine.uniqueFishCaught, 0)
        XCTAssertEqual(engine.uniqueRecipesCooked, 1)
        XCTAssertGreaterThan(engine.collectionProgress, 0)
        XCTAssertTrue(engine.isItemDiscovered("product.egg"))
        XCTAssertTrue(engine.isCropDiscovered("wheat"))
        XCTAssertFalse(engine.isCropDiscovered("moonberry"))
    }

    // MARK: - Persistence

    func testActivityStateSurvivesASaveRoundTrip() throws {
        let (engine, _) = makeEngine { state in
            state.activities.fishing.totalCatches = 3
            state.activities.fishing.catches = ["minnow": 2, "koi": 1]
            state.activities.cookedRecipeIDs = ["omelette": 2]
            state.activities.giftsClaimed = 4
            state.activities.giftStreak = 2
            state.activities.claimedAchievements = ["field.firstSprout"]
            state.nextWeather = .breezy
        }
        let data = try SaveCodec.encode(engine.state, savedAt: fixedDate)
        let decoded = try SaveCodec.decode(data)
        XCTAssertEqual(decoded.activities.fishing.totalCatches, 3)
        XCTAssertEqual(decoded.activities.fishing.catches["koi"], 1)
        XCTAssertEqual(decoded.activities.cookedRecipeIDs["omelette"], 2)
        XCTAssertEqual(decoded.activities.giftsClaimed, 4)
        XCTAssertEqual(decoded.activities.claimedAchievements, ["field.firstSprout"])
        XCTAssertEqual(decoded.nextWeather, .breezy)
        XCTAssertEqual(decoded.version, GameConstants.saveVersion)
    }

    func testOldSaveWithoutActivityFieldsStillLoads() throws {
        var state = GameState.newGame(now: fixedDate, seed: 9)
        state.weather = .rainy
        let data = try SaveCodec.encode(state, savedAt: fixedDate)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        var stateObject = try XCTUnwrap(object["state"] as? [String: Any])
        stateObject.removeValue(forKey: "activities")
        stateObject.removeValue(forKey: "nextWeather")
        object["state"] = stateObject
        let stripped = try JSONSerialization.data(withJSONObject: object)
        let decoded = try SaveCodec.decode(stripped)
        XCTAssertEqual(decoded.activities.weatherHistory, [decoded.weather])
        XCTAssertEqual(decoded.nextWeather, decoded.weather)
        XCTAssertEqual(decoded.activities.fishing.rodLevel, 1)
        XCTAssertEqual(decoded.version, GameConstants.saveVersion)
    }

    // MARK: - Sprites and content integrity

    func testEveryFishAndDishHasAValidDetailedSprite() {
        for fish in GameCatalog.standard.fish {
            let sprite = SpriteLibrary.fish(fish.id)
            XCTAssertNotNil(sprite, "Missing sprite for \(fish.id)")
            if let sprite {
                XCTAssertGreaterThanOrEqual(sprite.cells.count, 20, "\(fish.id) sprite is too sparse")
                XCTAssertTrue(sprite.rows.allSatisfy { $0.count == sprite.width }, "\(fish.id) has a malformed row")
            }
        }
        for recipe in GameCatalog.standard.recipes {
            let sprite = SpriteLibrary.dish(recipe.dishItemID)
            XCTAssertNotNil(sprite, "Missing sprite for \(recipe.dishItemID)")
            if let sprite {
                XCTAssertGreaterThanOrEqual(sprite.cells.count, 20, "\(recipe.dishItemID) sprite is too sparse")
                XCTAssertTrue(sprite.rows.allSatisfy { $0.count == sprite.width }, "\(recipe.dishItemID) has a malformed row")
            }
        }
    }

    func testEveryRecipeUsesKnownItemsAndEveryFishHasAUniqueItem() {
        let catalog = GameCatalog.standard
        for recipe in catalog.recipes {
            for itemID in recipe.ingredients.keys {
                XCTAssertNotNil(catalog.item(itemID), "\(recipe.id) uses unknown item \(itemID)")
            }
            XCTAssertEqual(catalog.recipeForDish(recipe.dishItemID)?.id, recipe.id)
        }
        let fishItems = catalog.fish.map(\.itemID)
        XCTAssertEqual(Set(fishItems).count, fishItems.count)
    }

    func testCalendarSeasonsAndFestivals() {
        XCTAssertEqual(GameCalendar.season(forDay: 1), .spring)
        XCTAssertEqual(GameCalendar.season(forDay: 8), .summer)
        XCTAssertEqual(GameCalendar.season(forDay: 15), .autumn)
        XCTAssertEqual(GameCalendar.season(forDay: 22), .winter)
        XCTAssertEqual(GameCalendar.season(forDay: 29), .spring)
        XCTAssertEqual(GameCalendar.dayOfSeason(forDay: 9), 2)
        XCTAssertNotNil(GameCalendar.festival(forDay: 7))
        XCTAssertNil(GameCalendar.festival(forDay: 3))
        XCTAssertEqual(GameCalendar.year(forDay: 29), 2)
    }
}
