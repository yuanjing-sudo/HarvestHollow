import Foundation

// MARK: - Constants

public enum GameConstants {
    /// One in-game day lasts four real-world minutes.
    public static let dayLength: Double = 240
    /// Progress is simulated for at most eight hours while the game is closed.
    public static let maxOfflineSeconds: Double = 8 * 60 * 60
    public static let saveVersion = 4

    public static let farmPlotCount = 24
    public static let startingPlots = 6
    public static let penCount = 8
    public static let startingPens = 2
    public static let houseWidth = 12
    public static let houseHeight = 8

    public static let startingCoins = 350
    public static let feedCyclesPerBag = 2
}

// MARK: - Weather

public enum Weather: String, Codable, CaseIterable, Sendable {
    case sunny
    case rainy
    case breezy
    case heatwave
    case storm

    public var title: String {
        switch self {
        case .sunny: return "Sunny"
        case .rainy: return "Rainy"
        case .breezy: return "Breezy"
        case .heatwave: return "Heatwave"
        case .storm: return "Storm"
        }
    }

    public var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .rainy: return "🌧️"
        case .breezy: return "🍃"
        case .heatwave: return "🔥"
        case .storm: return "⛈️"
        }
    }

    /// Multiplier applied to crop growth.
    public var growthMultiplier: Double {
        switch self {
        case .sunny: return 1.0
        case .rainy: return 1.12
        case .breezy: return 1.05
        case .heatwave: return 1.22
        case .storm: return 0.9
        }
    }

    public var blurb: String {
        switch self {
        case .sunny: return "A perfect day for the fields."
        case .rainy: return "The rain waters every crop for you."
        case .breezy: return "A gentle breeze helps things along."
        case .heatwave: return "Crops grow faster, but keep an eye on them."
        case .storm: return "A blustery day. Growth is a little slower."
        }
    }
}

// MARK: - GameState

public struct GameState: Codable, Sendable {
    public var version: Int
    public var createdAt: Date
    public var lastSavedAt: Date
    public var lastTick: Date

    public var coins: Int
    public var level: Int
    public var xp: Int
    public var day: Int
    public var clock: Double
    public var weather: Weather
    public var nextWeather: Weather

    public var plots: [Plot]
    public var pens: [Pen]
    public var house: HouseState
    public var inventory: [String: Int]
    public var stats: PlayerStats
    public var quests: QuestState
    public var dailyOrder: DailyOrder?
    public var themesOwned: [String]
    public var rngState: UInt64
    public var settings: GameSettings
    public var flags: GameFlags
    public var activities: ActivityState
    public var arcade: ArcadeState
    public var economy: ValleyEconomy

    public static func newGame(
        now: Date = Date(),
        seed: UInt64 = UInt64.random(in: 1...UInt64.max)
    ) -> GameState {
        var rng = GameRNG(state: seed)
        var state = GameState(
            version: GameConstants.saveVersion,
            createdAt: now,
            lastSavedAt: now,
            lastTick: now,
            coins: GameConstants.startingCoins,
            level: 1,
            xp: 0,
            day: 1,
            clock: GameConstants.dayLength * 0.28,
            weather: .sunny,
            nextWeather: .sunny,
            plots: (0..<GameConstants.farmPlotCount).map {
                Plot(id: $0, unlocked: $0 < GameConstants.startingPlots, crop: nil)
            },
            pens: (0..<GameConstants.penCount).map {
                Pen(id: $0, unlocked: $0 < GameConstants.startingPens, animal: nil)
            },
            house: HouseState(themeID: "cozy", placed: []),
            inventory: [
                "seed.wheat": 4,
                "seed.carrot": 3,
                "supply.feed": 2,
                "supply.fertilizer": 1,
                "supply.bait": 6,
                "furniture.chair": 1,
                "furniture.plant": 1
            ],
            stats: PlayerStats(),
            quests: QuestState(),
            dailyOrder: nil,
            themesOwned: ["cozy"],
            rngState: rng.state,
            settings: GameSettings(),
            flags: GameFlags(),
            activities: ActivityState(),
            arcade: ArcadeState(),
            economy: ValleyEconomy(level: 1)
        )

        state.weather = Weather.roll(using: &rng)
        state.nextWeather = Weather.roll(using: &rng)
        state.activities.weatherHistory = [state.weather]
        state.dailyOrder = DailyOrder.generate(
            day: state.day,
            playerLevel: state.level,
            catalog: .standard,
            rng: &rng
        )
        state.rngState = rng.state
        return state
    }

    public var unlockedPlots: Int { plots.filter(\.unlocked).count }
    public var unlockedPens: Int { pens.filter(\.unlocked).count }

    public var xpForNextLevel: Int { GameBalance.xpForNextLevel(level) }
    public var levelProgress: Double {
        let needed = max(1, xpForNextLevel)
        return min(1, Double(xp) / Double(needed))
    }

    /// Fraction of the current in-game day that has elapsed (0...1).
    public var timeOfDay: Double {
        min(1, max(0, clock / GameConstants.dayLength))
    }

    public var season: FarmSeason {
        GameCalendar.season(forDay: day)
    }

    public var seasonDay: Int {
        GameCalendar.dayOfSeason(forDay: day)
    }

    public var festival: FarmFestival? {
        GameCalendar.festival(forDay: day)
    }
}

extension GameState {
    private enum CodingKeys: String, CodingKey {
        case version
        case createdAt
        case lastSavedAt
        case lastTick
        case coins
        case level
        case xp
        case day
        case clock
        case weather
        case nextWeather
        case plots
        case pens
        case house
        case inventory
        case stats
        case quests
        case dailyOrder
        case themesOwned
        case rngState
        case settings
        case flags
        case activities
        case arcade
        case economy
    }

    /// Version-tolerant decoding lets farms saved before the town expansion keep
    /// loading. New fields are filled with gentle defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastSavedAt = try container.decode(Date.self, forKey: .lastSavedAt)
        lastTick = try container.decode(Date.self, forKey: .lastTick)
        coins = try container.decode(Int.self, forKey: .coins)
        level = try container.decode(Int.self, forKey: .level)
        xp = try container.decode(Int.self, forKey: .xp)
        day = try container.decode(Int.self, forKey: .day)
        clock = try container.decode(Double.self, forKey: .clock)
        weather = try container.decodeIfPresent(Weather.self, forKey: .weather) ?? .sunny
        nextWeather = try container.decodeIfPresent(Weather.self, forKey: .nextWeather) ?? weather
        plots = try container.decodeIfPresent([Plot].self, forKey: .plots) ?? []
        pens = try container.decodeIfPresent([Pen].self, forKey: .pens) ?? []
        house = try container.decodeIfPresent(HouseState.self, forKey: .house)
            ?? HouseState(themeID: "cozy", placed: [])
        inventory = try container.decodeIfPresent([String: Int].self, forKey: .inventory) ?? [:]
        stats = try container.decodeIfPresent(PlayerStats.self, forKey: .stats) ?? PlayerStats()
        quests = try container.decodeIfPresent(QuestState.self, forKey: .quests) ?? QuestState()
        dailyOrder = try container.decodeIfPresent(DailyOrder.self, forKey: .dailyOrder)
        themesOwned = try container.decodeIfPresent([String].self, forKey: .themesOwned) ?? ["cozy"]
        rngState = try container.decodeIfPresent(UInt64.self, forKey: .rngState)
            ?? UInt64(0x9E3779B97F4A7C15)
        settings = try container.decodeIfPresent(GameSettings.self, forKey: .settings) ?? GameSettings()
        flags = try container.decodeIfPresent(GameFlags.self, forKey: .flags) ?? GameFlags()
        activities = try container.decodeIfPresent(ActivityState.self, forKey: .activities)
            ?? ActivityState(weather: weather)
        arcade = try container.decodeIfPresent(ArcadeState.self, forKey: .arcade) ?? ArcadeState()
        economy = try container.decodeIfPresent(ValleyEconomy.self, forKey: .economy)
            ?? ValleyEconomy(level: level)
        version = GameConstants.saveVersion
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastSavedAt, forKey: .lastSavedAt)
        try container.encode(lastTick, forKey: .lastTick)
        try container.encode(coins, forKey: .coins)
        try container.encode(level, forKey: .level)
        try container.encode(xp, forKey: .xp)
        try container.encode(day, forKey: .day)
        try container.encode(clock, forKey: .clock)
        try container.encode(weather, forKey: .weather)
        try container.encode(nextWeather, forKey: .nextWeather)
        try container.encode(plots, forKey: .plots)
        try container.encode(pens, forKey: .pens)
        try container.encode(house, forKey: .house)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(stats, forKey: .stats)
        try container.encode(quests, forKey: .quests)
        try container.encodeIfPresent(dailyOrder, forKey: .dailyOrder)
        try container.encode(themesOwned, forKey: .themesOwned)
        try container.encode(rngState, forKey: .rngState)
        try container.encode(settings, forKey: .settings)
        try container.encode(flags, forKey: .flags)
        try container.encode(activities, forKey: .activities)
        try container.encode(arcade, forKey: .arcade)
        try container.encode(economy, forKey: .economy)
    }
}

// MARK: - Farm

public struct Plot: Codable, Identifiable, Sendable {
    public var id: Int
    public var unlocked: Bool
    public var crop: CropInstance?

    public var isEmpty: Bool { crop == nil }
}

public struct CropInstance: Codable, Sendable {
    public var cropID: String
    public var growth: Double
    public var watered: Bool
    public var fertilized: Bool
    public var plantedAt: Date

    public var isReady: Bool { growth >= 0.999 }
    public var stage: GrowthStage {
        if isReady { return .ready }
        if growth >= 0.66 { return .almost }
        if growth >= 0.33 { return .growing }
        return .sprout
    }

    public init(
        cropID: String,
        growth: Double = 0,
        watered: Bool = false,
        fertilized: Bool = false,
        plantedAt: Date = Date()
    ) {
        self.cropID = cropID
        self.growth = growth
        self.watered = watered
        self.fertilized = fertilized
        self.plantedAt = plantedAt
    }
}

public enum GrowthStage: String, Sendable {
    case sprout
    case growing
    case almost
    case ready

    public var label: String {
        switch self {
        case .sprout: return "Sprouting"
        case .growing: return "Growing"
        case .almost: return "Almost ready"
        case .ready: return "Ready to harvest"
        }
    }
}

// MARK: - Barn

public struct Pen: Codable, Identifiable, Sendable {
    public var id: Int
    public var unlocked: Bool
    public var animal: AnimalInstance?

    public var isEmpty: Bool { animal == nil }
}

public struct AnimalInstance: Codable, Identifiable, Sendable {
    public var id: UUID
    public var speciesID: String
    public var name: String
    public var fedUntil: Date?
    public var progress: Double
    public var stored: Int
    public var happiness: Double
    public var acquiredAt: Date
    public var affection: Double
    public var lastPettedAt: Date?
    public var petCount: Int

    public init(
        id: UUID,
        speciesID: String,
        name: String,
        fedUntil: Date?,
        progress: Double,
        stored: Int,
        happiness: Double,
        acquiredAt: Date,
        affection: Double = 45,
        lastPettedAt: Date? = nil,
        petCount: Int = 0
    ) {
        self.id = id
        self.speciesID = speciesID
        self.name = name
        self.fedUntil = fedUntil
        self.progress = progress
        self.stored = stored
        self.happiness = happiness
        self.acquiredAt = acquiredAt
        self.affection = affection
        self.lastPettedAt = lastPettedAt
        self.petCount = petCount
    }

    public var affectionLevel: Int {
        min(5, max(1, Int(affection / 20) + 1))
    }

    public var affectionTitle: String {
        switch affectionLevel {
        case 1: return "Shy"
        case 2: return "Curious"
        case 3: return "Friendly"
        case 4: return "Affectionate"
        default: return "Best Friend"
        }
    }

    public func canPet(at date: Date) -> Bool {
        guard let lastPettedAt else { return true }
        return date.timeIntervalSince(lastPettedAt) >= 90
    }

    public func petCooldownRemaining(at date: Date) -> Double {
        guard let lastPettedAt else { return 0 }
        return max(0, 90 - date.timeIntervalSince(lastPettedAt))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case speciesID
        case name
        case fedUntil
        case progress
        case stored
        case happiness
        case acquiredAt
        case affection
        case lastPettedAt
        case petCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        speciesID = try container.decode(String.self, forKey: .speciesID)
        name = try container.decode(String.self, forKey: .name)
        fedUntil = try container.decodeIfPresent(Date.self, forKey: .fedUntil)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        stored = try container.decodeIfPresent(Int.self, forKey: .stored) ?? 0
        happiness = try container.decodeIfPresent(Double.self, forKey: .happiness) ?? 70
        acquiredAt = try container.decode(Date.self, forKey: .acquiredAt)
        affection = try container.decodeIfPresent(Double.self, forKey: .affection) ?? 45
        lastPettedAt = try container.decodeIfPresent(Date.self, forKey: .lastPettedAt)
        petCount = try container.decodeIfPresent(Int.self, forKey: .petCount) ?? 0
    }

    public func isFed(at date: Date) -> Bool {
        guard let fedUntil else { return false }
        return fedUntil > date
    }

    public func fedSecondsRemaining(at date: Date) -> Double {
        guard let fedUntil else { return 0 }
        return max(0, fedUntil.timeIntervalSince(date))
    }
}

// MARK: - House

public struct HouseState: Codable, Sendable {
    public var themeID: String
    public var placed: [PlacedFurniture]
}

public struct PlacedFurniture: Codable, Identifiable, Sendable {
    public var id: UUID
    public var itemID: String
    public var x: Int
    public var y: Int
}

// MARK: - Inventory & stats

public struct PlayerStats: Codable, Sendable {
    public var cropsPlanted: Int = 0
    public var cropsHarvested: Int = 0
    public var itemsSold: Int = 0
    public var coinsEarned: Int = 0
    public var animalsBought: Int = 0
    public var animalProducts: Int = 0
    public var decorationsPlaced: Int = 0
    public var questsCompleted: Int = 0
    public var feedUsed: Int = 0
    public var fertilizersUsed: Int = 0
    public var soldByItem: [String: Int] = [:]
    public var harvestedByCrop: [String: Int] = [:]

    public init() {}
}

public struct GameSettings: Codable, Sendable {
    public var soundEnabled: Bool = true
    public var hapticsEnabled: Bool = true
    public var hasSeenWelcome: Bool = false

    public init() {}
}

public struct GameFlags: Codable, Sendable {
    public var lastSeenDay: Int = 1
    public var totalDaysPlayed: Int = 1

    public init() {}
}

// MARK: - Quests

public struct QuestState: Codable, Sendable {
    public var storyIndex: Int = 0
    public var completedIDs: [String] = []

    public init() {}
}

public struct DailyOrder: Codable, Identifiable, Sendable {
    public var day: Int
    public var itemID: String
    public var target: Int
    public var progress: Int
    public var completed: Bool
    public var rewardCoins: Int
    public var rewardXP: Int

    public var id: String { "\(day)-\(itemID)" }

    public static func generate(
        day: Int,
        playerLevel: Int,
        catalog: GameCatalog,
        rng: inout GameRNG
    ) -> DailyOrder {
        let candidates = catalog.dailyOrderItems(playerLevel: playerLevel)
        let itemID = candidates[rng.int(in: 0...(max(0, candidates.count - 1)))]
        let item = catalog.item(itemID)
        let target = rng.int(in: 3...8)
        let base = item?.sellPrice ?? 10
        return DailyOrder(
            day: day,
            itemID: itemID,
            target: target,
            progress: 0,
            completed: false,
            rewardCoins: base * target + 80,
            rewardXP: 18 + target * 5
        )
    }
}

// MARK: - Feedback

public enum ActionResult: Equatable, Sendable {
    case success(String)
    case failure(String)

    public var message: String {
        switch self {
        case .success(let message), .failure(let message): return message
        }
    }

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

public enum GameEvent: Equatable, Sendable {
    case dayAdvanced(day: Int, weather: Weather)
    case returnedAfterDays(days: Int, day: Int, weather: Weather)
    case offlineProgress(seconds: Int, days: Int)
    case leveledUp(level: Int, coinBonus: Int)
    case questCompleted(questID: String, title: String, coins: Int, xp: Int)
    case dailyOrderCompleted(itemID: String, coins: Int, xp: Int)
    case fishCaught(fishID: String, weight: Double, rarity: FishRarity)
    case rodUpgraded(level: Int)
    case achievementClaimed(id: String, title: String, coins: Int, xp: Int)
    case giftClaimed(day: Int, streak: Int, coins: Int, xp: Int)
    case cooked(recipeID: String, dishName: String, buffKind: FoodBuffKind, percent: Int)
    case mealEnjoyed(dishID: String, buffName: String, percent: Int, seconds: Int)
    case petAnimal(name: String, affection: Double)
    case masteryUp(cropID: String, level: Int)
    case meadowRunCompleted(level: Int, score: Int, stars: Int, coins: Int, xp: Int)
    case economyEvent(day: Int, title: String, detail: String, positive: Bool)
    case message(String)
}

// MARK: - Balance

public enum GameBalance {
    public static func xpForNextLevel(_ level: Int) -> Int {
        90 + max(0, level - 1) * 70
    }

    public static func plotUnlockLevel(for index: Int) -> Int {
        if index < GameConstants.startingPlots { return 1 }
        return 2 + (index - GameConstants.startingPlots) / 6
    }

    public static func plotPrice(unlockedPlots: Int) -> Int {
        let extra = max(0, unlockedPlots - GameConstants.startingPlots)
        return 150 + extra * 75
    }

    public static func penUnlockLevel(for index: Int) -> Int {
        if index < GameConstants.startingPens { return 1 }
        return 2 + (index - GameConstants.startingPens) / 2
    }

    public static func penPrice(unlockedPens: Int) -> Int {
        let extra = max(0, unlockedPens - GameConstants.startingPens)
        return 500 + extra * 300
    }

    public static let petNames = [
        "Biscuit", "Clover", "Maple", "Poppy", "Willow", "Juniper",
        "Hazel", "Pepper", "Mochi", "Pudding", "Dumpling", "Sprout",
        "Buttercup", "Mabel", "Otto", "Nori", "Pebble", "Sage"
    ]
}

// MARK: - Deterministic RNG

public struct GameRNG: Sendable {
    public var state: UInt64

    public init(state: UInt64) {
        self.state = state == 0 ? 0x9E3779B97F4A7C15 : state
    }

    public mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        guard range.lowerBound < range.upperBound else { return range.lowerBound }
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    public mutating func double01() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    public mutating func chance(_ probability: Double) -> Bool {
        double01() < probability
    }
}

extension Weather {
    static func roll(using rng: inout GameRNG) -> Weather {
        let roll = rng.int(in: 0...99)
        switch roll {
        case 0..<44: return .sunny
        case 44..<64: return .rainy
        case 64..<79: return .breezy
        case 79..<91: return .heatwave
        default: return .storm
        }
    }
}
