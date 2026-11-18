import Foundation

/// The complete simulation for Harvest Hollow.
///
/// `GameEngine` owns a value-type `GameState`, advances time, validates every
/// action, and emits lightweight events for the presentation layer. It has no
/// dependency on SwiftUI, SpriteKit, or a database, which keeps the whole game
/// loop testable on every platform Swift supports.
public final class GameEngine {
    public private(set) var state: GameState
    public let catalog: GameCatalog
    private let clock: () -> Date

    private var pendingEvents: [GameEvent] = []

    public init(
        state: GameState,
        catalog: GameCatalog = .standard,
        clock: @escaping () -> Date = Date.init
    ) {
        var normalized = state
        _ = normalized.economy.synchronize(level: normalized.level)
        normalized.economy.ensureLedgers()
        self.state = normalized
        self.catalog = catalog
        self.clock = clock
    }

    /// Swap in a state loaded from an imported save. Pending events belong to
    /// the old farm and are discarded.
    public func replaceState(_ newState: GameState) {
        var normalized = newState
        _ = normalized.economy.synchronize(level: normalized.level)
        normalized.economy.ensureLedgers()
        state = normalized
        pendingEvents.removeAll()
    }

    // MARK: - Time

    /// Advances the world to `date`. Called on a timer by the app and once at
    /// launch to catch up on offline progress.
    public func simulate(at date: Date? = nil) {
        let now = date ?? clock()
        let rawElapsed = now.timeIntervalSince(state.lastTick)

        guard rawElapsed > 0.001 else {
            if rawElapsed < 0 { state.lastTick = now }
            return
        }

        let elapsed = min(rawElapsed, GameConstants.maxOfflineSeconds)
        let startDay = state.day
        let previousDay = state.day

        // Tick the day clock. A long absence rolls over several days, but the
        // number of simulated seconds is capped so a save can never explode.
        var remaining = elapsed
        while remaining > 0.0001 {
            let untilDayEnd = max(0, GameConstants.dayLength - state.clock)
            if remaining < untilDayEnd {
                state.clock += remaining
                remaining = 0
            } else {
                state.clock = 0
                remaining -= untilDayEnd
                advanceDay()
            }
        }

        // Crops grow in real seconds while watered. Weather, fertilizer, and a
        // good cooked meal all speed things up.
        let mealSpeed = activeGrowthMultiplier(at: now)
        for index in state.plots.indices {
            guard var crop = state.plots[index].crop,
                  crop.watered,
                  !crop.isReady else { continue }
            let definition = catalog.crop(crop.cropID)
            let growSeconds = max(1, definition?.growSeconds ?? 60)
            let speed = state.weather.growthMultiplier
                * (crop.fertilized ? 1.5 : 1.0)
                * mealSpeed
            crop.growth = min(1, crop.growth + elapsed / growSeconds * speed)
            state.plots[index].crop = crop
        }

        // Animals that were fed keep producing while the app is closed.
        let productiveStart = max(state.lastTick, now.addingTimeInterval(-elapsed))
        for index in state.pens.indices {
            guard var animal = state.pens[index].animal,
                  let species = catalog.animal(animal.speciesID) else { continue }

            let affectionComfort = animal.affection / 1_800
            animal.happiness = max(20, animal.happiness - elapsed / (600 + affectionComfort * 600))

            var produced = 0
            if let fedUntil = animal.fedUntil {
                let productiveEnd = min(now, fedUntil)
                if productiveEnd > productiveStart, animal.stored < species.capacity {
                    let happiness = max(20, animal.happiness)
                    let affectionBonus = min(0.2, animal.affection / 500)
                    let interval = max(5, species.produceSeconds / (0.75 + happiness / 400 + affectionBonus))
                    animal.progress += productiveEnd.timeIntervalSince(productiveStart)

                    while animal.progress >= interval, animal.stored < species.capacity {
                        animal.progress -= interval
                        animal.stored += 1
                        produced += 1
                    }
                    if animal.stored >= species.capacity {
                        animal.progress = min(animal.progress, interval)
                    }
                }
            }

            state.pens[index].animal = animal

            if produced > 0 {
                let itemName = catalog.item(species.productItemID)?.name ?? "goods"
                emit(.message("\(animal.name) left \(produced) \(itemName) waiting in the pen."))
            }
        }

        state.lastTick = now

        let daysPassed = state.day - startDay
        if daysPassed == 1 {
            emit(.dayAdvanced(day: state.day, weather: state.weather))
        } else if daysPassed > 1 {
            emit(.returnedAfterDays(days: daysPassed, day: state.day, weather: state.weather))
        }
        if elapsed >= 120 {
            emit(.offlineProgress(seconds: Int(elapsed), days: daysPassed))
        }

        if previousDay < state.day {
            state.flags.lastSeenDay = state.day
            state.flags.totalDaysPlayed += state.day - previousDay
        }
    }

    private func advanceDay() {
        state.day += 1
        state.weather = state.nextWeather
        state.nextWeather = withRNG { Weather.roll(using: &$0) }
        state.activities.weatherHistory.append(state.weather)
        if state.activities.weatherHistory.count > 10 {
            state.activities.weatherHistory.removeFirst(
                state.activities.weatherHistory.count - 10
            )
        }

        if state.weather == .rainy {
            for index in state.plots.indices where state.plots[index].crop != nil {
                state.plots[index].crop?.watered = true
            }
        }

        state.dailyOrder = withRNG {
            DailyOrder.generate(
                day: state.day,
                playerLevel: state.level,
                catalog: catalog,
                rng: &$0
            )
        }

        let inputs = EconomyInputs(state: state)
        let report = withRNG { rng in
            state.economy.advanceDay(inputs, rng: &rng)
        }
        if report.tierChanged || !report.unlockedFactors.isEmpty {
            let names = report.unlockedFactors.prefix(3)
                .map(\.shortTitle)
                .joined(separator: ", ")
            let detail = report.unlockedFactors.isEmpty
                ? report.tier.blurb
                : "Unlocked \(names)"
            emit(.economyEvent(
                day: report.day,
                title: "Valley ledger · \(report.tier.title)",
                detail: detail,
                positive: true
            ))
        }
        if let event = report.event {
            emit(.economyEvent(
                day: event.day,
                title: event.title,
                detail: event.detail,
                positive: event.impact >= 0
            ))
        }
        let investmentCash = state.economy.collectInvestmentCash()
        if investmentCash >= 0.5 {
            state.coins += Int(investmentCash.rounded())
            emit(.message("Hollow Exchange paid \(Int(investmentCash.rounded())) coins in dividends or liquidation proceeds."))
        }
        if let notice = report.marketNotice {
            emit(.economyEvent(
                day: report.day,
                title: "Margin call",
                detail: notice,
                positive: false
            ))
        }
        if let incident = report.crimeIncident {
            emit(.economyEvent(
                day: incident.day,
                title: incident.title,
                detail: incident.detail,
                positive: false
            ))
        }
    }

    // MARK: - Events

    public func drainEvents() -> [GameEvent] {
        let events = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)
        return events
    }

    private func emit(_ event: GameEvent) {
        pendingEvents.append(event)
    }

    private func withRNG<T>(_ body: (inout GameRNG) -> T) -> T {
        var rng = GameRNG(state: state.rngState)
        let result = body(&rng)
        state.rngState = rng.state
        return result
    }

    // MARK: - Derived values

    public var comfort: Int {
        state.house.placed.reduce(0) { total, piece in
            total + (catalog.furniture(piece.itemID)?.comfort ?? 0)
        }
    }

    public var comfortBonus: Double {
        min(0.25, Double(comfort) / 100.0)
    }

    public var currentTheme: HouseTheme {
        catalog.theme(state.house.themeID) ?? catalog.themes[0]
    }

    public var activeQuest: QuestDefinition? {
        guard state.quests.storyIndex >= 0,
              state.quests.storyIndex < catalog.quests.count else { return nil }
        return catalog.quests[state.quests.storyIndex]
    }

    public func metricValue(for metric: QuestMetric) -> Int {
        switch metric {
        case .cropsPlanted: return state.stats.cropsPlanted
        case .cropsHarvested: return state.stats.cropsHarvested
        case .itemsSold: return state.stats.itemsSold
        case .coinsEarned: return state.stats.coinsEarned
        case .animalsBought: return state.stats.animalsBought
        case .animalProducts: return state.stats.animalProducts
        case .decorationsPlaced: return state.stats.decorationsPlaced
        case .level: return state.level
        case .comfort: return comfort
        case .questsCompleted: return state.stats.questsCompleted
        }
    }

    public func progress(for objective: QuestObjective) -> Int {
        min(metricValue(for: objective.metric), objective.target)
    }

    public func sellPrice(for itemID: String, onDay day: Int? = nil) -> Int {
        guard let item = catalog.item(itemID), item.sellPrice > 0 else { return 0 }
        let base = Market.sellPrice(
            base: item.sellPrice,
            itemID: itemID,
            day: day ?? state.day,
            comfort: comfort
        )
        var multiplier = 1.0
        if item.kind == .produce,
           let crop = catalog.crops.first(where: { $0.produceItemID == itemID }) {
            let harvests = state.stats.harvestedByCrop[crop.id, default: 0]
            multiplier += CropMastery.saleBonus(for: harvests)
        }
        multiplier += activeMarketBonus(at: clock())
        return max(1, Int((Double(base) * multiplier).rounded()))
    }

    public func cropMasteryLevel(_ cropID: String) -> Int {
        CropMastery.level(for: state.stats.harvestedByCrop[cropID, default: 0])
    }

    public func cropMasteryTier(_ cropID: String) -> CropMasteryTier {
        CropMastery.tier(for: state.stats.harvestedByCrop[cropID, default: 0])
    }

    public func cropMasteryProgress(_ cropID: String) -> Double {
        CropMastery.progress(for: state.stats.harvestedByCrop[cropID, default: 0])
    }

    public func cropHarvestCount(_ cropID: String) -> Int {
        state.stats.harvestedByCrop[cropID, default: 0]
    }

    public func itemCount(_ itemID: String) -> Int {
        state.inventory[itemID, default: 0]
    }

    public func plotUnlockLevel(_ plotID: Int) -> Int {
        GameBalance.plotUnlockLevel(for: plotID)
    }

    public func plotPrice() -> Int {
        GameBalance.plotPrice(unlockedPlots: state.unlockedPlots)
    }

    public func penUnlockLevel(_ penID: Int) -> Int {
        GameBalance.penUnlockLevel(for: penID)
    }

    public func penPrice() -> Int {
        GameBalance.penPrice(unlockedPens: state.unlockedPens)
    }

    // MARK: - Farming

    @discardableResult
    public func plant(cropID: String, inPlot plotID: Int, at date: Date? = nil) -> ActionResult {
        guard let plotIndex = state.plots.firstIndex(where: { $0.id == plotID }) else {
            return .failure("That plot does not exist.")
        }
        guard state.plots[plotIndex].unlocked else {
            return .failure("This plot is still wild. Clear it before planting.")
        }
        guard state.plots[plotIndex].crop == nil else {
            return .failure("Something is already growing here.")
        }
        guard let crop = catalog.crop(cropID) else {
            return .failure("Unknown seed.")
        }
        guard state.level >= crop.unlockLevel else {
            return .failure("\(crop.name) seeds unlock at level \(crop.unlockLevel).")
        }
        guard itemCount(crop.seedItemID) > 0 else {
            return .failure("You are out of \(crop.seedName.lowercased()).")
        }

        removeItem(crop.seedItemID, 1)
        state.plots[plotIndex].crop = CropInstance(
            cropID: cropID,
            plantedAt: date ?? clock()
        )
        state.stats.cropsPlanted += 1
        awardXP(2)
        evaluateQuests()
        return .success("Planted \(crop.name). Give it a drink of water.")
    }

    @discardableResult
    public func plantAll(cropID: String) -> ActionResult {
        guard let crop = catalog.crop(cropID) else { return .failure("Unknown seed.") }
        guard state.level >= crop.unlockLevel else {
            return .failure("\(crop.name) seeds unlock at level \(crop.unlockLevel).")
        }
        guard itemCount(crop.seedItemID) > 0 else {
            return .failure("You are out of \(crop.seedName.lowercased()).")
        }

        var planted = 0
        for plot in state.plots.sorted(by: { $0.id < $1.id }) where plot.unlocked && plot.crop == nil {
            guard itemCount(crop.seedItemID) > 0 else { break }
            if plant(cropID: cropID, inPlot: plot.id).isSuccess {
                planted += 1
            }
        }
        guard planted > 0 else {
            return .failure("There is no empty plot to plant.")
        }
        return .success("Planted \(planted) \(planted == 1 ? "plot" : "plots") with \(crop.name).")
    }

    @discardableResult
    public func water(plotID: Int) -> ActionResult {
        guard let index = state.plots.firstIndex(where: { $0.id == plotID }) else {
            return .failure("That plot does not exist.")
        }
        guard var crop = state.plots[index].crop else {
            return .failure("Nothing is planted there yet.")
        }
        guard !crop.isReady else {
            return .failure("This crop is ready to harvest.")
        }
        guard !crop.watered else {
            return .failure("This crop is already watered.")
        }
        crop.watered = true
        state.plots[index].crop = crop
        return .success("Watered the \(cropName(crop.cropID)).")
    }

    @discardableResult
    public func waterAll() -> ActionResult {
        var watered = 0
        for index in state.plots.indices {
            guard var crop = state.plots[index].crop, !crop.watered, !crop.isReady else { continue }
            crop.watered = true
            state.plots[index].crop = crop
            watered += 1
        }
        guard watered > 0 else {
            return .failure("Every growing crop already has water.")
        }
        return .success("Watered \(watered) \(watered == 1 ? "crop" : "crops").")
    }

    @discardableResult
    public func fertilize(plotID: Int) -> ActionResult {
        guard let index = state.plots.firstIndex(where: { $0.id == plotID }) else {
            return .failure("That plot does not exist.")
        }
        guard var crop = state.plots[index].crop else {
            return .failure("Plant something before fertilizing.")
        }
        guard !crop.isReady else {
            return .failure("This crop is already fully grown.")
        }
        guard !crop.fertilized else {
            return .failure("This crop is already fertilized.")
        }
        guard itemCount("supply.fertilizer") > 0 else {
            return .failure("You are out of fertilizer.")
        }

        removeItem("supply.fertilizer", 1)
        crop.fertilized = true
        state.plots[index].crop = crop
        state.stats.fertilizersUsed += 1
        awardXP(1)
        evaluateQuests()
        return .success("Fertilized the \(cropName(crop.cropID)). It will grow faster and yield extra.")
    }

    @discardableResult
    public func harvest(plotID: Int) -> ActionResult {
        guard let index = state.plots.firstIndex(where: { $0.id == plotID }) else {
            return .failure("That plot does not exist.")
        }
        guard let cropInstance = state.plots[index].crop else {
            return .failure("Nothing is growing there.")
        }
        guard cropInstance.isReady else {
            return .failure("The \(cropName(cropInstance.cropID)) is not ready yet.")
        }
        guard let crop = catalog.crop(cropInstance.cropID) else {
            return .failure("Unknown crop.")
        }

        let baseYield = withRNG { $0.int(in: crop.minYield...crop.maxYield) }
        let yield = baseYield + (cropInstance.fertilized ? 1 : 0)
        let previousMastery = cropMasteryLevel(crop.id)
        addItem(crop.produceItemID, yield)
        state.stats.cropsHarvested += yield
        state.stats.harvestedByCrop[crop.id, default: 0] += yield
        let currentMastery = cropMasteryLevel(crop.id)
        if currentMastery > previousMastery {
            emit(.masteryUp(cropID: crop.id, level: currentMastery))
        }

        var bonusSeed = false
        if withRNG({ $0.chance(0.22) }) {
            addItem(crop.seedItemID, 1)
            bonusSeed = true
        }

        state.plots[index].crop = nil
        awardXP(crop.xp + max(0, yield - 1) * 2)
        evaluateQuests()

        var message = "Harvested \(yield) × \(crop.name)."
        if bonusSeed { message += " You also found a seed!" }
        return .success(message)
    }

    @discardableResult
    public func harvestAll() -> ActionResult {
        let ready = state.plots
            .filter { $0.unlocked && $0.crop?.isReady == true }
            .sorted { $0.id < $1.id }

        guard !ready.isEmpty else {
            return .failure("No crops are ready to harvest yet.")
        }

        var harvestedPlots = 0
        for plot in ready {
            if harvest(plotID: plot.id).isSuccess {
                harvestedPlots += 1
            }
        }
        return .success("Harvested \(harvestedPlots) \(harvestedPlots == 1 ? "plot" : "plots").")
    }

    // MARK: - Barn

    @discardableResult
    public func adoptAnimal(speciesID: String, penID: Int, at date: Date? = nil) -> ActionResult {
        guard let species = catalog.animal(speciesID) else {
            return .failure("Unknown animal.")
        }
        guard state.level >= species.unlockLevel else {
            return .failure("\(species.name)s unlock at level \(species.unlockLevel).")
        }
        guard let index = state.pens.firstIndex(where: { $0.id == penID }) else {
            return .failure("That pen does not exist.")
        }
        guard state.pens[index].unlocked else {
            return .failure("Clear this pen before bringing home an animal.")
        }
        guard state.pens[index].animal == nil else {
            return .failure("This pen already has a resident.")
        }
        guard state.coins >= species.price else {
            return .failure("You need \(species.price - state.coins) more coins.")
        }

        let now = date ?? clock()
        state.coins -= species.price
        let name = withRNG { rng -> String in
            let base = GameBalance.petNames[rng.int(in: 0...(GameBalance.petNames.count - 1))]
            let suffix = rng.int(in: 0...9)
            return suffix < 3 ? "\(base) Jr." : base
        }
        state.pens[index].animal = AnimalInstance(
            id: UUID(),
            speciesID: species.id,
            name: name,
            fedUntil: now.addingTimeInterval(species.produceSeconds * 2),
            progress: 0,
            stored: 0,
            happiness: 72,
            acquiredAt: now
        )
        state.stats.animalsBought += 1
        awardXP(20)
        evaluateQuests()
        return .success("\(name) the \(species.name) moved into the barn!")
    }

    @discardableResult
    public func renameAnimal(penID: Int, to newName: String) -> ActionResult {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 20 else {
            return .failure("Names must be between 1 and 20 characters.")
        }
        guard let index = state.pens.firstIndex(where: { $0.id == penID }),
              let animal = state.pens[index].animal else {
            return .failure("There is no animal in that pen.")
        }
        state.pens[index].animal?.name = trimmed
        return .success("\(animal.name) is now called \(trimmed).")
    }

    @discardableResult
    public func feed(penID: Int, at date: Date? = nil) -> ActionResult {
        guard let index = state.pens.firstIndex(where: { $0.id == penID }) else {
            return .failure("That pen does not exist.")
        }
        guard var animal = state.pens[index].animal,
              let species = catalog.animal(animal.speciesID) else {
            return .failure("There is no animal in that pen.")
        }
        guard itemCount("supply.feed") > 0 else {
            return .failure("You are out of feed. Pick some up at the market.")
        }

        let now = date ?? clock()
        removeItem("supply.feed", 1)
        let base = max(now, animal.fedUntil ?? now)
        animal.fedUntil = base.addingTimeInterval(
            species.produceSeconds * Double(GameConstants.feedCyclesPerBag)
        )
        animal.happiness = min(100, animal.happiness + 10)
        state.pens[index].animal = animal
        state.stats.feedUsed += 1
        awardXP(1)
        evaluateQuests()
        return .success("Fed \(animal.name). They look very pleased.")
    }

    @discardableResult
    public func feedAll(at date: Date? = nil) -> ActionResult {
        let now = date ?? clock()
        let hungryPens = state.pens
            .filter { pen in
                guard let animal = pen.animal,
                      let species = catalog.animal(animal.speciesID) else { return false }
                if !animal.isFed(at: now) { return true }
                return animal.fedSecondsRemaining(at: now) < species.produceSeconds * 0.75
            }
            .sorted { $0.id < $1.id }

        guard !hungryPens.isEmpty else {
            return .failure("Every animal is already well fed.")
        }

        var fed = 0
        for pen in hungryPens {
            guard itemCount("supply.feed") > 0 else { break }
            if feed(penID: pen.id, at: now).isSuccess {
                fed += 1
            }
        }

        guard fed > 0 else {
            return .failure("You are out of feed.")
        }
        return .success("Fed \(fed) \(fed == 1 ? "animal" : "animals").")
    }

    @discardableResult
    public func collect(penID: Int) -> ActionResult {
        guard let index = state.pens.firstIndex(where: { $0.id == penID }) else {
            return .failure("That pen does not exist.")
        }
        guard var animal = state.pens[index].animal,
              let species = catalog.animal(animal.speciesID) else {
            return .failure("There is no animal in that pen.")
        }
        guard animal.stored > 0 else {
            return .failure("Nothing to collect yet. Make sure \(animal.name) is fed.")
        }

        let amount = animal.stored
        let product = catalog.item(species.productItemID)
        addItem(species.productItemID, amount)
        animal.stored = 0
        animal.happiness = min(100, animal.happiness + 2)
        state.pens[index].animal = animal
        state.stats.animalProducts += amount
        awardXP(species.xpPerProduct * amount)
        evaluateQuests()
        return .success("Collected \(amount) × \(product?.name ?? "goods") from \(animal.name).")
    }

    @discardableResult
    public func collectAll() -> ActionResult {
        let readyPens = state.pens
            .filter { $0.animal?.stored ?? 0 > 0 }
            .sorted { $0.id < $1.id }
        guard !readyPens.isEmpty else {
            return .failure("Nothing is waiting to be collected.")
        }

        var collected = 0
        for pen in readyPens {
            if collect(penID: pen.id).isSuccess {
                collected += 1
            }
        }
        return .success("Collected from \(collected) \(collected == 1 ? "pen" : "pens").")
    }

    // MARK: - Land

    @discardableResult
    public func buyPlot(_ plotID: Int) -> ActionResult {
        guard let index = state.plots.firstIndex(where: { $0.id == plotID }) else {
            return .failure("That plot does not exist.")
        }
        guard !state.plots[index].unlocked else {
            return .failure("This plot is already cleared.")
        }
        let requiredLevel = plotUnlockLevel(plotID)
        guard state.level >= requiredLevel else {
            return .failure("Reach level \(requiredLevel) to clear this plot.")
        }
        let price = plotPrice()
        guard state.coins >= price else {
            return .failure("You need \(price - state.coins) more coins to clear this plot.")
        }

        state.coins -= price
        state.plots[index].unlocked = true
        awardXP(10)
        evaluateQuests()
        return .success("Cleared a new plot for \(price) coins.")
    }

    @discardableResult
    public func buyPen(_ penID: Int) -> ActionResult {
        guard let index = state.pens.firstIndex(where: { $0.id == penID }) else {
            return .failure("That pen does not exist.")
        }
        guard !state.pens[index].unlocked else {
            return .failure("This pen is already open.")
        }
        let requiredLevel = penUnlockLevel(penID)
        guard state.level >= requiredLevel else {
            return .failure("Reach level \(requiredLevel) to open this pen.")
        }
        let price = penPrice()
        guard state.coins >= price else {
            return .failure("You need \(price - state.coins) more coins to open this pen.")
        }

        state.coins -= price
        state.pens[index].unlocked = true
        awardXP(20)
        evaluateQuests()
        return .success("Opened a new pen for \(price) coins.")
    }

    // MARK: - Market

    @discardableResult
    public func buySeed(cropID: String, quantity: Int = 1) -> ActionResult {
        guard quantity > 0 else { return .failure("Choose at least one seed.") }
        guard let crop = catalog.crop(cropID) else { return .failure("Unknown seed.") }
        guard state.level >= crop.unlockLevel else {
            return .failure("\(crop.name) seeds unlock at level \(crop.unlockLevel).")
        }
        let cost = crop.seedPrice * quantity
        guard state.coins >= cost else {
            return .failure("You need \(cost - state.coins) more coins.")
        }

        state.coins -= cost
        addItem(crop.seedItemID, quantity)
        return .success("Bought \(quantity) × \(crop.seedName) for \(cost) coins.")
    }

    @discardableResult
    public func buySupply(_ itemID: String, quantity: Int = 1) -> ActionResult {
        guard quantity > 0 else { return .failure("Choose at least one item.") }
        guard let supply = catalog.supplies.first(where: { $0.id == itemID }) else {
            return .failure("That item is not for sale.")
        }
        let cost = supply.price * quantity
        guard state.coins >= cost else {
            return .failure("You need \(cost - state.coins) more coins.")
        }

        state.coins -= cost
        addItem(itemID, quantity)
        return .success("Bought \(quantity) × \(supply.name) for \(cost) coins.")
    }

    @discardableResult
    public func buyFurniture(_ itemID: String) -> ActionResult {
        guard let piece = catalog.furniture(itemID), piece.price > 0 else {
            return .failure("That piece is not for sale.")
        }
        guard state.coins >= piece.price else {
            return .failure("You need \(piece.price - state.coins) more coins.")
        }

        state.coins -= piece.price
        addItem(itemID, 1)
        return .success("Bought \(piece.name). Place it from the House tab.")
    }

    @discardableResult
    public func buyTheme(_ themeID: String) -> ActionResult {
        guard let theme = catalog.theme(themeID) else {
            return .failure("Unknown theme.")
        }
        guard !state.themesOwned.contains(themeID) else {
            return .failure("You already own this theme.")
        }
        guard state.coins >= theme.price else {
            return .failure("You need \(theme.price - state.coins) more coins.")
        }

        state.coins -= theme.price
        state.themesOwned.append(themeID)
        state.house.themeID = themeID
        return .success("Bought the \(theme.name) theme and applied it.")
    }

    @discardableResult
    public func applyTheme(_ themeID: String) -> ActionResult {
        guard let theme = catalog.theme(themeID) else {
            return .failure("Unknown theme.")
        }
        guard state.themesOwned.contains(themeID) else {
            return .failure("Buy this theme before applying it.")
        }
        state.house.themeID = themeID
        return .success("The house now wears the \(theme.name) theme.")
    }

    @discardableResult
    public func sell(itemID: String, quantity: Int = 1) -> ActionResult {
        guard quantity > 0 else { return .failure("Choose at least one item.") }
        guard let item = catalog.item(itemID), item.isSellable else {
            return .failure("That item cannot be sold.")
        }
        switch item.kind {
        case .produce, .animalProduct, .fish, .dish, .supply:
            break
        case .seed, .furniture:
            return .failure("Seeds and furniture are keepers, not market stock.")
        }
        guard itemCount(itemID) >= quantity else {
            return .failure("You do not have that many \(item.name).")
        }

        let unitPrice = sellPrice(for: itemID)
        let total = unitPrice * quantity
        removeItem(itemID, quantity)
        state.coins += total
        state.stats.itemsSold += quantity
        state.stats.coinsEarned += total
        state.stats.soldByItem[itemID, default: 0] += quantity

        updateDailyOrder(itemID: itemID, quantity: quantity)
        awardXP(max(1, quantity / 2))
        evaluateQuests()
        return .success("Sold \(quantity) × \(item.name) for \(total) coins.")
    }

    @discardableResult
    public func sellAll(itemID: String) -> ActionResult {
        sell(itemID: itemID, quantity: itemCount(itemID))
    }

    private func updateDailyOrder(itemID: String, quantity: Int) {
        guard var order = state.dailyOrder,
              !order.completed,
              order.itemID == itemID else { return }

        order.progress += quantity
        if order.progress >= order.target {
            order.completed = true
            state.coins += order.rewardCoins
            state.activities.dailyOrdersCompleted += 1
            awardXP(order.rewardXP)
            emit(.dailyOrderCompleted(
                itemID: itemID,
                coins: order.rewardCoins,
                xp: order.rewardXP
            ))
        }
        state.dailyOrder = order
    }

    // MARK: - House

    @discardableResult
    public func placeFurniture(itemID: String, x: Int, y: Int) -> ActionResult {
        guard let piece = catalog.furniture(itemID) else {
            return .failure("Unknown furniture.")
        }
        guard itemCount(itemID) > 0 else {
            return .failure("You do not own that piece yet.")
        }
        guard x >= 0, y >= 0,
              x + piece.width <= GameConstants.houseWidth,
              y + piece.height <= GameConstants.houseHeight else {
            return .failure("That piece does not fit there.")
        }

        for placed in state.house.placed {
            guard let other = catalog.furniture(placed.itemID) else { continue }
            if overlaps(
                x: x, y: y, width: piece.width, height: piece.height,
                otherX: placed.x, otherY: placed.y,
                otherWidth: other.width, otherHeight: other.height
            ) {
                return .failure("Something is already occupying that spot.")
            }
        }

        removeItem(itemID, 1)
        state.house.placed.append(
            PlacedFurniture(id: UUID(), itemID: itemID, x: x, y: y)
        )
        state.stats.decorationsPlaced += 1
        awardXP(5)
        evaluateQuests()
        return .success("Placed the \(piece.name).")
    }

    @discardableResult
    public func removeFurniture(id: UUID) -> ActionResult {
        guard let index = state.house.placed.firstIndex(where: { $0.id == id }) else {
            return .failure("That piece is not in the room.")
        }
        let placed = state.house.placed.remove(at: index)
        addItem(placed.itemID, 1)
        let name = catalog.furniture(placed.itemID)?.name ?? "Furniture"
        return .success("Picked up the \(name).")
    }

    @discardableResult
    public func nudgeFurniture(id: UUID, dx: Int, dy: Int) -> ActionResult {
        guard let index = state.house.placed.firstIndex(where: { $0.id == id }),
              let piece = catalog.furniture(state.house.placed[index].itemID) else {
            return .failure("That piece is not in the room.")
        }
        let placed = state.house.placed[index]
        let newX = placed.x + dx
        let newY = placed.y + dy
        guard newX >= 0, newY >= 0,
              newX + piece.width <= GameConstants.houseWidth,
              newY + piece.height <= GameConstants.houseHeight else {
            return .failure("The room ends there.")
        }

        for other in state.house.placed where other.id != id {
            guard let otherPiece = catalog.furniture(other.itemID) else { continue }
            if overlaps(
                x: newX, y: newY, width: piece.width, height: piece.height,
                otherX: other.x, otherY: other.y,
                otherWidth: otherPiece.width, otherHeight: otherPiece.height
            ) {
                return .failure("Something is already there.")
            }
        }

        state.house.placed[index].x = newX
        state.house.placed[index].y = newY
        return .success("Moved the \(piece.name).")
    }

    /// Integer grid overlap test, kept free of CoreGraphics so the core module
    /// builds identically on Linux and Apple platforms.
    private func overlaps(
        x: Int, y: Int, width: Int, height: Int,
        otherX: Int, otherY: Int, otherWidth: Int, otherHeight: Int
    ) -> Bool {
        x < otherX + otherWidth
            && otherX < x + width
            && y < otherY + otherHeight
            && otherY < y + height
    }

    // MARK: - Meadow Dash

    /// Records one completed arcade run and folds a modest, bounded reward
    /// back into the farm. The arcade is a real part of the save, not a
    /// detached demo, but it can never replace the farming loop's economy.
    @discardableResult
    public func recordMeadowRun(_ result: MeadowRunResult) -> (coins: Int, xp: Int) {
        state.arcade.register(result, day: state.day)
        let baseCoins = result.success ? 18 + result.stars * 14 : 4
        let coinReward = min(120, max(2, baseCoins + result.apples))
        let xpReward = min(80, max(1, result.apples + result.stars * 6 + (result.success ? 8 : 0)))
        state.coins += coinReward
        awardXP(xpReward)
        emit(
            .meadowRunCompleted(
                level: result.levelIndex,
                score: result.score,
                stars: result.stars,
                coins: coinReward,
                xp: xpReward
            )
        )
        return (coinReward, xpReward)
    }

    // MARK: - Quests & progression

    private func awardXP(_ amount: Int) {
        guard amount > 0 else { return }
        state.xp += amount
        while state.xp >= GameBalance.xpForNextLevel(state.level) {
            let needed = GameBalance.xpForNextLevel(state.level)
            state.xp -= needed
            state.level += 1
            let bonus = 40 * state.level
            state.coins += bonus
            emit(.leveledUp(level: state.level, coinBonus: bonus))
            let unlocked = state.economy.synchronize(level: state.level)
            if !unlocked.isEmpty {
                let names = unlocked.prefix(4)
                    .map(\.shortTitle)
                    .joined(separator: ", ")
                emit(.economyEvent(
                    day: state.day,
                    title: "The valley ledger deepens",
                    detail: "New factors at level \(state.level): \(names)",
                    positive: true
                ))
            }
        }
    }

    private func evaluateQuests() {
        var safety = 0
        while safety < catalog.quests.count {
            guard state.quests.storyIndex < catalog.quests.count else { return }
            let quest = catalog.quests[state.quests.storyIndex]
            let complete = quest.objectives.allSatisfy {
                metricValue(for: $0.metric) >= $0.target
            }
            guard complete else { return }

            state.quests.completedIDs.append(quest.id)
            state.quests.storyIndex += 1
            state.stats.questsCompleted += 1
            state.coins += quest.reward.coins
            for (itemID, quantity) in quest.reward.items {
                addItem(itemID, quantity)
            }
            emit(.questCompleted(
                questID: quest.id,
                title: quest.title,
                coins: quest.reward.coins,
                xp: quest.reward.xp
            ))
            awardXP(quest.reward.xp)
            safety += 1
        }
    }

    // MARK: - Valley economy

    @discardableResult
    public func setEconomyTaxRate(_ value: Double) -> Bool {
        guard state.economy.setTaxRate(value) else { return false }
        emit(.message("Valley tax rate set to \(Int((state.economy.taxRate * 100).rounded()))%."))
        return true
    }

    @discardableResult
    public func setEconomySubsidyRate(_ value: Double) -> Bool {
        guard state.economy.setSubsidyRate(value) else { return false }
        emit(.message("Farm subsidy rate set to \(Int((state.economy.subsidyRate * 100).rounded()))%."))
        return true
    }

    @discardableResult
    public func setEconomyPublicSpending(_ value: Double) -> Bool {
        guard state.economy.setPublicSpending(value) else { return false }
        emit(.message("Public spending set to \(Int((state.economy.publicSpending * 100).rounded()))% of output."))
        return true
    }

    @discardableResult
    public func setEconomyTariffRate(_ value: Double) -> Bool {
        guard state.economy.setTariffRate(value) else { return false }
        emit(.message("Tariff rate set to \(Int((state.economy.tariffRate * 100).rounded()))%."))
        return true
    }

    @discardableResult
    public func setEconomyInterestRate(_ value: Double) -> Bool {
        guard state.economy.setInterestRate(value) else { return false }
        emit(.message("Valley policy rate set to \(Int((state.economy.interestRate * 100).rounded()))%."))
        return true
    }

    @discardableResult
    public func investInEconomy(_ investment: EconomyInvestment) -> Bool {
        guard state.coins >= investment.cost else { return false }
        guard state.economy.invest(investment) else { return false }
        state.coins -= investment.cost
        emit(.message("Invested \(investment.cost) coins in \(investment.title)."))
        return true
    }

    @discardableResult
    public func takeEconomyLoan(amount: Double, purpose: String = "Farm investment") -> Bool {
        guard state.coins >= 0,
              let loan = state.economy.takeLoan(
                amount: amount,
                purpose: purpose,
                day: state.day
              ) else { return false }
        state.coins += Int(amount.rounded())
        emit(.message("Borrowed \(Int(loan.principal)) coins at \(Int((loan.annualRate * 100).rounded()))% annual interest."))
        return true
    }

    @discardableResult
    public func repayEconomyLoan(id: UUID, amount: Double) -> Bool {
        let payment = min(amount, Double(state.coins))
        guard payment > 0 else { return false }
        let paid = state.economy.repayLoan(id: id, amount: payment)
        guard paid > 0 else { return false }
        state.coins -= Int(paid.rounded())
        emit(.message("Repaid \(Int(paid.rounded())) coins of valley debt."))
        return true
    }

    // MARK: - Hollow Exchange

    /// Buys shares in a valley business. `leverage` above 1 borrows the rest
    /// from the exchange, so a fall in the share price can trigger a margin
    /// call and a real loss of the player's coins.
    @discardableResult
    public func buyBusinessShares(
        businessID: UUID,
        shares: Double,
        leverage: Double
    ) -> InvestmentExecution {
        let execution = state.economy.buyShares(
            businessID: businessID,
            shares: shares,
            leverage: leverage,
            availableCoins: state.coins
        )
        if execution.success {
            state.coins = max(0, state.coins + Int(execution.cashDelta.rounded()))
        }
        emit(.message(execution.message))
        return execution
    }

    @discardableResult
    public func sellBusinessShares(
        businessID: UUID,
        shares: Double
    ) -> InvestmentExecution {
        let execution = state.economy.sellShares(
            businessID: businessID,
            shares: shares
        )
        if execution.success {
            state.coins = max(0, state.coins + Int(execution.cashDelta.rounded()))
        }
        emit(.message(execution.message))
        return execution
    }

    /// Funds a forensic audit. Audits unlock at level 8. A clean audit lowers
    /// perceived fraud risk; a dirty one recovers a bounty and creates a case.
    @discardableResult
    public func auditBusiness(id: UUID, cost: Double = 40) -> BusinessAuditResult {
        guard state.economy.investmentAuditUnlocked else {
            let result = BusinessAuditResult(
                success: false,
                cost: 0,
                discoveredFraud: false,
                recovered: 0,
                message: "Forensic audits unlock at level 8."
            )
            emit(.message(result.message))
            return result
        }
        guard state.coins >= Int(cost) else {
            let result = BusinessAuditResult(
                success: false,
                cost: 0,
                discoveredFraud: false,
                recovered: 0,
                message: "You need \(Int(cost)) coins to fund a forensic audit."
            )
            emit(.message(result.message))
            return result
        }
        let result = withRNG { rng in
            state.economy.auditBusiness(id: id, cost: cost, rng: &rng)
        }
        if result.success {
            state.coins -= Int(cost)
            if result.recovered > 0 {
                state.coins += Int(result.recovered.rounded())
            }
        }
        emit(.message(result.message))
        return result
    }

    // MARK: - Settings & reset

    public func markWelcomeSeen() {
        state.settings.hasSeenWelcome = true
    }

    public func setSoundEnabled(_ enabled: Bool) {
        state.settings.soundEnabled = enabled
    }

    public func setHapticsEnabled(_ enabled: Bool) {
        state.settings.hapticsEnabled = enabled
    }

    @discardableResult
    public func resetProgress(at date: Date? = nil) -> GameState {
        let now = date ?? clock()
        state = GameState.newGame(now: now, seed: UInt64.random(in: 1...UInt64.max))
        pendingEvents.removeAll()
        return state
    }

    // MARK: - Inventory

    private func addItem(_ itemID: String, _ quantity: Int) {
        guard quantity > 0 else { return }
        state.inventory[itemID, default: 0] += quantity
    }

    @discardableResult
    private func removeItem(_ itemID: String, _ quantity: Int) -> Bool {
        guard quantity > 0, itemCount(itemID) >= quantity else { return false }
        let left = itemCount(itemID) - quantity
        if left > 0 {
            state.inventory[itemID] = left
        } else {
            state.inventory.removeValue(forKey: itemID)
        }
        return true
    }

    private func cropName(_ cropID: String) -> String {
        catalog.crop(cropID)?.name ?? "crop"
    }

    // MARK: - Food buffs

    public var currentFoodBuff: FoodBuff? {
        guard let buff = state.activities.activeBuff else { return nil }
        return buff.isActive(at: clock()) ? buff : nil
    }

    public var foodBuffSecondsRemaining: Int {
        Int(currentFoodBuff?.secondsRemaining(at: clock()) ?? 0)
    }

    public func foodBuffRemaining(at date: Date? = nil) -> Double {
        guard let buff = state.activities.activeBuff else { return 0 }
        return buff.secondsRemaining(at: date ?? clock())
    }

    private func activeGrowthMultiplier(at date: Date) -> Double {
        guard let buff = state.activities.activeBuff, buff.isActive(at: date) else { return 1 }
        switch buff.kind {
        case .growth, .feast:
            return 1 + buff.magnitude
        case .market, .fishing:
            return 1
        }
    }

    private func activeMarketBonus(at date: Date) -> Double {
        guard let buff = state.activities.activeBuff, buff.isActive(at: date) else { return 0 }
        switch buff.kind {
        case .market, .feast:
            return buff.magnitude
        case .growth, .fishing:
            return 0
        }
    }

    private func activeFishingBonus(at date: Date) -> Double {
        guard let buff = state.activities.activeBuff, buff.isActive(at: date) else { return 0 }
        switch buff.kind {
        case .fishing, .feast:
            return buff.magnitude
        case .growth, .market:
            return 0
        }
    }

    public func clearExpiredBuff() {
        guard let buff = state.activities.activeBuff, !buff.isActive(at: clock()) else { return }
        state.activities.activeBuff = nil
    }

    // MARK: - Pond & fishing

    public var fishingRodName: String {
        FishingBalance.rodName(level: state.activities.fishing.rodLevel)
    }

    public var fishingRodLevel: Int {
        state.activities.fishing.rodLevel
    }

    public var fishingRodUpgradeCost: Int {
        FishingBalance.upgradeCost(from: state.activities.fishing.rodLevel)
    }

    public var fishingRodUpgradeLevel: Int {
        FishingBalance.upgradeLevelRequirement(from: state.activities.fishing.rodLevel)
    }

    public var canUpgradeFishingRod: Bool {
        guard state.activities.fishing.rodLevel < FishingBalance.maxRodLevel else { return false }
        return state.level >= fishingRodUpgradeLevel
            && state.coins >= fishingRodUpgradeCost
    }

    public var baitCount: Int {
        itemCount(FishingBalance.baitItemID)
    }

    public var fishCaughtCount: Int {
        state.activities.fishing.totalCatches
    }

    public var uniqueFishCaught: Int {
        state.activities.fishing.uniqueCatches
    }

    public func fishCatchCount(_ fishID: String) -> Int {
        state.activities.fishing.catches[fishID, default: 0]
    }

    public func bestWeight(forFish fishID: String) -> Double {
        state.activities.fishing.bestWeight[fishID, default: 0]
    }

    public func isFishCaught(_ fishID: String) -> Bool {
        fishCatchCount(fishID) > 0
    }

    public var rarestFishCaught: FishDefinition? {
        let caught = state.activities.fishing.catches.filter { $0.value > 0 }.map(\.key)
        let order: [FishRarity: Int] = [
            .common: 0, .uncommon: 1, .rare: 2, .epic: 3, .legendary: 4
        ]
        return caught.compactMap { catalog.fishDefinition($0) }
            .max { (order[$0.rarity] ?? 0) < (order[$1.rarity] ?? 0) }
    }

    @discardableResult
    public func upgradeFishingRod() -> ActionResult {
        let current = state.activities.fishing.rodLevel
        guard current < FishingBalance.maxRodLevel else {
            return .failure("Your rod is already a Hollowmaster. Finn would be jealous.")
        }
        let requiredLevel = FishingBalance.upgradeLevelRequirement(from: current)
        guard state.level >= requiredLevel else {
            return .failure("Reach farmer level \(requiredLevel) to upgrade your rod.")
        }
        let cost = FishingBalance.upgradeCost(from: current)
        guard state.coins >= cost else {
            return .failure("You need \(cost - state.coins) more coins for the upgrade.")
        }

        state.coins -= cost
        state.activities.fishing.rodLevel = current + 1
        state.activities.lastRodUpgradeDay = state.day
        awardXP(25)
        emit(.rodUpgraded(level: current + 1))
        return .success("Upgraded to the \(FishingBalance.rodName(level: current + 1)). Rare fish are within reach.")
    }

    private func chooseFish(for rng: inout GameRNG, at date: Date) -> FishDefinition {
        let time = state.timeOfDay
        let buff = activeFishingBonus(at: date)
        let rod = max(1, state.activities.fishing.rodLevel)
        let eligible = catalog.fish.filter { $0.unlockRodLevel <= rod }
        guard !eligible.isEmpty else { return catalog.fish[0] }

        let weighted: [(FishDefinition, Double)] = eligible.map { fish in
            var weight = fish.rarity.baseWeight
            let rodHeadroom = max(0, rod - fish.unlockRodLevel)
            weight *= 1 + Double(rodHeadroom) * 0.16
            if fish.rarity == .common {
                weight *= max(0.32, 1 - Double(rod - 1) * 0.14)
            }
            if fish.rarity == .legendary {
                weight *= 1 + Double(rod - 1) * 0.08
            }
            if fish.preferredWeather.contains(state.weather) {
                weight *= 1.75
            }
            if fish.timeWindow.matches(timeOfDay: time) {
                weight *= 1.55
            }
            if buff > 0 {
                switch fish.rarity {
                case .common:
                    weight *= max(0.4, 1 - buff * 1.2)
                case .uncommon:
                    weight *= 1 + buff * 0.4
                case .rare, .epic, .legendary:
                    weight *= 1 + buff * 2.8
                }
            }
            weight += state.weather.fishingBonus * 12 * (fish.rarity == .common ? 0.3 : 1)
            return (fish, max(0.1, weight))
        }

        let total = weighted.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return eligible[0] }
        var roll = rng.double01() * total
        for (fish, weight) in weighted {
            roll -= weight
            if roll <= 0 { return fish }
        }
        return weighted.last?.0 ?? eligible[0]
    }

    @discardableResult
    public func castLine(at date: Date? = nil) -> ActionResult {
        let now = date ?? clock()
        guard itemCount(FishingBalance.baitItemID) > 0 else {
            return .failure("Your bait tin is empty. Buy pond bait at the market.")
        }

        removeItem(FishingBalance.baitItemID, 1)
        state.activities.fishing.totalCasts += 1

        var rng = GameRNG(state: state.rngState)
        let fish = chooseFish(for: &rng, at: now)
        let perfect = rng.chance(
            FishingBalance.perfectCastChance + activeFishingBonus(at: now) * 0.35
        )
        var weight = fish.minWeight
            + rng.double01() * max(0.01, fish.maxWeight - fish.minWeight)
        if perfect {
            weight *= 1.18
            state.activities.fishing.perfectCasts += 1
        }
        weight = (weight * 10).rounded() / 10
        state.rngState = rng.state

        addItem(fish.itemID, 1)
        state.activities.fishing.totalCatches += 1
        state.activities.fishing.catches[fish.id, default: 0] += 1
        if weight > (state.activities.fishing.bestWeight[fish.id] ?? 0) {
            state.activities.fishing.bestWeight[fish.id] = weight
        }
        if weight > state.activities.fishing.biggestWeight {
            state.activities.fishing.biggestWeight = weight
            state.activities.fishing.biggestFishID = fish.id
        }
        let record = FishingCatchRecord(fishID: fish.id, weight: weight, caughtAt: now)
        state.activities.fishing.recentCatches.insert(record, at: 0)
        if state.activities.fishing.recentCatches.count > 12 {
            state.activities.fishing.recentCatches.removeLast(
                state.activities.fishing.recentCatches.count - 12
            )
        }

        awardXP(fish.rarity.xp + (perfect ? 4 : 0))
        emit(.fishCaught(fishID: fish.id, weight: weight, rarity: fish.rarity))

        var text = "Caught a \(fish.name) · \(String(format: "%.1f", weight)) lb."
        if perfect {
            text += " A perfect cast!"
        }
        return .success(text)
    }

    // MARK: - Kitchen

    public func canCook(_ recipe: RecipeDefinition, at date: Date? = nil) -> Bool {
        guard state.level >= recipe.unlockLevel else { return false }
        return recipe.ingredients.allSatisfy { itemID, quantity in
            itemCount(itemID) >= quantity
        }
    }

    public func missingIngredients(for recipe: RecipeDefinition) -> [(itemID: String, quantity: Int)] {
        recipe.ingredients.compactMap { itemID, needed in
            let missing = max(0, needed - itemCount(itemID))
            return missing > 0 ? (itemID, missing) : nil
        }
        .sorted { $0.itemID < $1.itemID }
    }

    public func cookedCount(recipeID: String) -> Int {
        state.activities.cookedRecipeIDs[recipeID, default: 0]
    }

    public func hasCooked(recipeID: String) -> Bool {
        cookedCount(recipeID: recipeID) > 0
    }

    public var dishesCookedCount: Int {
        state.activities.dishesCooked
    }

    public var uniqueRecipesCooked: Int {
        state.activities.uniqueRecipesCooked
    }

    public var cookedRecipeIDs: [String] {
        state.activities.cookedRecipeIDs
            .filter { $0.value > 0 }
            .map(\.key)
            .sorted()
    }

    @discardableResult
    public func cook(recipeID: String, at date: Date? = nil) -> ActionResult {
        guard let recipe = catalog.recipe(recipeID) else {
            return .failure("That recipe is not in the book.")
        }
        guard state.level >= recipe.unlockLevel else {
            return .failure("\(recipe.name) unlocks at level \(recipe.unlockLevel).")
        }
        let missing = missingIngredients(for: recipe)
        guard missing.isEmpty else {
            let names = missing.compactMap { entry -> String? in
                guard let item = catalog.item(entry.itemID) else { return nil }
                return "\(entry.quantity) × \(item.name)"
            }
            return .failure("Missing ingredients: \(names.joined(separator: ", ")).")
        }

        for (itemID, quantity) in recipe.ingredients {
            removeItem(itemID, quantity)
        }
        addItem(recipe.dishItemID, 1)
        state.activities.cookedRecipeIDs[recipe.id, default: 0] += 1
        if state.activities.favoriteRecipeID == nil {
            state.activities.favoriteRecipeID = recipe.id
        }
        awardXP(recipe.xp)
        emit(.cooked(
            recipeID: recipe.id,
            dishName: recipe.name,
            buffKind: recipe.buff.kind,
            percent: recipe.buff.percent
        ))
        return .success("Cooked \(recipe.name). It is waiting in your pantry.")
    }

    @discardableResult
    public func cookAllPossible() -> ActionResult {
        var cooked = 0
        for recipe in catalog.recipes.sorted(by: { $0.unlockLevel < $1.unlockLevel })
        where canCook(recipe) {
            if cook(recipeID: recipe.id).isSuccess {
                cooked += 1
            }
        }
        guard cooked > 0 else {
            return .failure("No recipe has all its ingredients yet.")
        }
        return .success("Cooked \(cooked) \(cooked == 1 ? "dish" : "dishes").")
    }

    @discardableResult
    public func eatDish(itemID: String, at date: Date? = nil) -> ActionResult {
        guard let recipe = catalog.recipeForDish(itemID) else {
            return .failure("That dish is not part of a recipe.")
        }
        guard itemCount(itemID) > 0 else {
            return .failure("There is no \(recipe.name) in the pantry.")
        }
        let now = date ?? clock()
        removeItem(itemID, 1)
        let buff = FoodBuff(
            kind: recipe.buff.kind,
            magnitude: recipe.buff.magnitude,
            expiresAt: now.addingTimeInterval(recipe.buff.duration),
            name: recipe.name,
            emoji: recipe.emoji
        )
        state.activities.activeBuff = buff
        state.activities.dishesEaten += 1
        awardXP(2)
        emit(.mealEnjoyed(
            dishID: itemID,
            buffName: recipe.name,
            percent: recipe.buff.percent,
            seconds: Int(recipe.buff.duration)
        ))
        return .success("Enjoyed \(recipe.name). \(recipe.buff.kind.summary)")
    }

    // MARK: - Daily gift

    public var canClaimDailyGift: Bool {
        !state.activities.hasClaimedGift(onDay: state.day)
    }

    /// The one-based position in the seven-day gift cycle that will be claimed
    /// next (or that was claimed today, once the gift has been opened).
    public var dailyGiftCycleDay: Int {
        if state.activities.lastGiftDay == state.day {
            return ((max(1, state.activities.giftStreak) - 1) % 7) + 1
        }
        if state.activities.lastGiftDay == state.day - 1 {
            return (state.activities.giftStreak % 7) + 1
        }
        return 1
    }

    public var dailyGiftStreak: Int {
        state.activities.giftStreak
    }

    public var nextDailyGift: DailyGiftDefinition {
        ActivityCatalog.gift(dayInCycle: dailyGiftCycleDay)
    }

    @discardableResult
    public func claimDailyGift() -> ActionResult {
        guard canClaimDailyGift else {
            return .failure("Today's parcel is already open. Come back tomorrow morning.")
        }

        if state.activities.lastGiftDay == state.day - 1 {
            state.activities.giftStreak += 1
        } else {
            state.activities.giftStreak = 1
        }
        state.activities.lastGiftDay = state.day
        state.activities.giftsClaimed += 1

        let cycleDay = ((state.activities.giftStreak - 1) % 7) + 1
        let gift = ActivityCatalog.gift(dayInCycle: cycleDay)
        state.coins += gift.coins
        for (itemID, quantity) in gift.items {
            addItem(itemID, quantity)
        }
        awardXP(gift.xp)
        emit(.giftClaimed(
            day: gift.day,
            streak: state.activities.giftStreak,
            coins: gift.coins,
            xp: gift.xp
        ))
        return .success("Opened \(gift.title): +\(gift.coins) coins and a few useful things.")
    }

    // MARK: - Achievements

    public func progress(forAchievement definition: AchievementDefinition) -> AchievementProgress {
        let current = ActivityCatalog.achievementProgress(
            definition: definition,
            state: state,
            comfort: comfort
        )
        return AchievementProgress(
            definition: definition,
            current: current,
            isClaimed: state.activities.isAchievementClaimed(definition.id)
        )
    }

    public var achievementProgressList: [AchievementProgress] {
        catalog.achievements.map { progress(forAchievement: $0) }
    }

    public var claimableAchievementCount: Int {
        achievementProgressList.filter(\.canClaim).count
    }

    public var claimedAchievementCount: Int {
        state.activities.claimedAchievements.count
    }

    public func isAchievementClaimed(_ id: String) -> Bool {
        state.activities.isAchievementClaimed(id)
    }

    @discardableResult
    public func claimAchievement(id: String) -> ActionResult {
        guard let definition = catalog.achievement(id) else {
            return .failure("That achievement is not in the journal.")
        }
        guard !state.activities.isAchievementClaimed(id) else {
            return .failure("You have already claimed \(definition.title).")
        }
        let progress = progress(forAchievement: definition)
        guard progress.isComplete else {
            return .failure("\(definition.title) needs \(progress.remaining) more.")
        }

        state.activities.claimedAchievements.append(id)
        state.activities.achievementClaimDates[id] = clock()
        state.coins += definition.rewardCoins
        for (itemID, quantity) in definition.rewardItems {
            addItem(itemID, quantity)
        }
        awardXP(definition.rewardXP)
        emit(.achievementClaimed(
            id: definition.id,
            title: definition.title,
            coins: definition.rewardCoins,
            xp: definition.rewardXP
        ))
        return .success("Claimed \(definition.title): +\(definition.rewardCoins) coins.")
    }

    @discardableResult
    public func claimAllAchievements() -> ActionResult {
        let claimable = achievementProgressList.filter(\.canClaim)
        guard !claimable.isEmpty else {
            return .failure("No achievements are ready to claim.")
        }
        var claimed = 0
        for entry in claimable {
            if claimAchievement(id: entry.id).isSuccess {
                claimed += 1
            }
        }
        return .success("Claimed \(claimed) \(claimed == 1 ? "achievement" : "achievements").")
    }

    // MARK: - Barn affection

    @discardableResult
    public func pet(penID: Int, at date: Date? = nil) -> ActionResult {
        guard let index = state.pens.firstIndex(where: { $0.id == penID }),
              var animal = state.pens[index].animal else {
            return .failure("There is no animal in that pen.")
        }
        let now = date ?? clock()
        guard animal.canPet(at: now) else {
            let seconds = Int(animal.petCooldownRemaining(at: now).rounded(.up))
            return .failure("\(animal.name) is still basking in the last scratch. \(seconds)s to go.")
        }

        animal.affection = min(100, animal.affection + 8)
        animal.happiness = min(100, animal.happiness + 4)
        animal.lastPettedAt = now
        animal.petCount += 1
        state.pens[index].animal = animal
        state.activities.animalsPetted += 1
        awardXP(2)
        emit(.petAnimal(name: animal.name, affection: animal.affection))
        return .success("You gave \(animal.name) a scratch behind the ears.")
    }

    @discardableResult
    public func petAll(at date: Date? = nil) -> ActionResult {
        let now = date ?? clock()
        let ready = state.pens.compactMap(\.animal).filter { $0.canPet(at: now) }
        guard !ready.isEmpty else {
            return .failure("Everyone has had plenty of attention for the moment.")
        }
        var petted = 0
        for pen in state.pens where pen.animal?.canPet(at: now) == true {
            if pet(penID: pen.id, at: now).isSuccess {
                petted += 1
            }
        }
        return .success("Made \(petted) \(petted == 1 ? "friend" : "friends") very happy.")
    }

    // MARK: - Collection helpers

    public func harvestedCount(cropID: String) -> Int {
        state.stats.harvestedByCrop[cropID, default: 0]
    }

    public func isCropDiscovered(_ cropID: String) -> Bool {
        harvestedCount(cropID: cropID) > 0
    }

    public func soldCount(itemID: String) -> Int {
        state.stats.soldByItem[itemID, default: 0]
    }

    public func isItemDiscovered(_ itemID: String) -> Bool {
        itemCount(itemID) > 0
            || soldCount(itemID: itemID) > 0
            || catalog.recipeForDish(itemID).map { hasCooked(recipeID: $0.id) } == true
    }

    public var discoveredCropCount: Int {
        catalog.crops.filter { isCropDiscovered($0.id) }.count
    }

    public var discoveredDishCount: Int {
        catalog.recipes.filter {
            itemCount($0.dishItemID) > 0
                || hasCooked(recipeID: $0.id)
                || soldCount(itemID: $0.dishItemID) > 0
        }.count
    }

    public var discoveredBarnGoodCount: Int {
        catalog.animals.filter {
            isItemDiscovered($0.productItemID)
        }.count
    }

    public var collectionProgress: Double {
        let total = catalog.crops.count
            + catalog.fish.count
            + catalog.animals.count
            + catalog.recipes.count
            + catalog.recipes.count
        guard total > 0 else { return 0 }
        let found = discoveredCropCount
            + uniqueFishCaught
            + discoveredBarnGoodCount
            + discoveredDishCount
            + uniqueRecipesCooked
        return min(1, Double(found) / Double(total))
    }

    public var season: FarmSeason {
        state.season
    }

    public var festival: FarmFestival? {
        state.festival
    }

    public var nextWeather: Weather {
        state.nextWeather
    }

    public var weatherHistory: [Weather] {
        state.activities.weatherHistory
    }
}
