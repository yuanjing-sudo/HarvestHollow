import Foundation

// MARK: - Constants

public enum GameConstants {
    /// One in-game day lasts four real-world minutes.
    public static let dayLength: Double = 240
    /// Progress is simulated for at most eight hours while the game is closed.
    public static let maxOfflineSeconds: Double = 8 * 60 * 60
    public static let saveVersion = 1

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
                "furniture.chair": 1,
                "furniture.plant": 1
            ],
            stats: PlayerStats(),
            quests: QuestState(),
            dailyOrder: nil,
            themesOwned: ["cozy"],
            rngState: rng.state,
            settings: GameSettings(),
            flags: GameFlags()
        )

        state.weather = Weather.roll(using: &rng)
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
