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
        self.state = state
        self.catalog = catalog
        self.clock = clock
    }

    /// Swap in a state loaded from an imported save. Pending events belong to
    /// the old farm and are discarded.
    public func replaceState(_ newState: GameState) {
        state = newState
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

        // Crops grow in real seconds while watered. Weather and fertilizer
        // both speed things up.
        for index in state.plots.indices {
            guard var crop = state.plots[index].crop,
                  crop.watered,
                  !crop.isReady else { continue }
            let definition = catalog.crop(crop.cropID)
            let growSeconds = max(1, definition?.growSeconds ?? 60)
            let speed = state.weather.growthMultiplier * (crop.fertilized ? 1.5 : 1.0)
            crop.growth = min(1, crop.growth + elapsed / growSeconds * speed)
            state.plots[index].crop = crop
        }

        // Animals that were fed keep producing while the app is closed.
        let productiveStart = max(state.lastTick, now.addingTimeInterval(-elapsed))
        for index in state.pens.indices {
            guard var animal = state.pens[index].animal,
                  let species = catalog.animal(animal.speciesID) else { continue }

            animal.happiness = max(20, animal.happiness - elapsed / 600)

            var produced = 0
            if let fedUntil = animal.fedUntil {
                let productiveEnd = min(now, fedUntil)
                if productiveEnd > productiveStart, animal.stored < species.capacity {
                    let happiness = max(20, animal.happiness)
                    let interval = max(5, species.produceSeconds / (0.75 + happiness / 400))
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
        state.weather = withRNG { Weather.roll(using: &$0) }

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
        return Market.sellPrice(
            base: item.sellPrice,
            itemID: itemID,
            day: day ?? state.day,
            comfort: comfort
        )
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
        addItem(crop.produceItemID, yield)
        state.stats.cropsHarvested += yield
        state.stats.harvestedByCrop[crop.id, default: 0] += yield

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
        guard item.kind == .produce || item.kind == .animalProduct || item.kind == .supply else {
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

        let newRect = CGRect(x: x, y: y, width: piece.width, height: piece.height)
        for placed in state.house.placed {
            guard let other = catalog.furniture(placed.itemID) else { continue }
            let otherRect = CGRect(
                x: placed.x, y: placed.y,
                width: other.width, height: other.height
            )
            if newRect.intersects(otherRect) {
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

        let newRect = CGRect(x: newX, y: newY, width: piece.width, height: piece.height)
        for other in state.house.placed where other.id != id {
            guard let otherPiece = catalog.furniture(other.itemID) else { continue }
            let otherRect = CGRect(
                x: other.x, y: other.y,
                width: otherPiece.width, height: otherPiece.height
            )
            if newRect.intersects(otherRect) {
                return .failure("Something is already there.")
            }
        }

        state.house.placed[index].x = newX
        state.house.placed[index].y = newY
        return .success("Moved the \(piece.name).")
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
}
