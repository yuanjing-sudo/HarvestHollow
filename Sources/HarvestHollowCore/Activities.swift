import Foundation

// MARK: - Calendar & seasons

/// A short, readable season cycle. The valley changes its colours every seven
/// in-game days, which keeps the almanac lively without hiding crops behind a
/// long calendar grind.
public enum FarmSeason: String, Codable, CaseIterable, Sendable {
    case spring
    case summer
    case autumn
    case winter

    public var title: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }

    public var emoji: String {
        switch self {
        case .spring: return "🌱"
        case .summer: return "☀️"
        case .autumn: return "🍂"
        case .winter: return "❄️"
        }
    }

    public var tintHex: String {
        switch self {
        case .spring: return "7DBF5B"
        case .summer: return "E8BC55"
        case .autumn: return "C96A4B"
        case .winter: return "8FB4C9"
        }
    }

    public var blurb: String {
        switch self {
        case .spring: return "New shoots, soft rain, and a valley waking up."
        case .summer: return "Long golden afternoons and busy market stalls."
        case .autumn: return "Harvest baskets, woodsmoke, and amber leaves."
        case .winter: return "Quiet fields, warm kitchens, and early stars."
        }
    }

    public var greeting: String {
        switch self {
        case .spring: return "The orchard is in blossom."
        case .summer: return "The pond is warm and the bees are out."
        case .autumn: return "The market smells of cinnamon and pumpkins."
        case .winter: return "The kettle is always on in Hollowmere."
        }
    }
}

public struct FarmFestival: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let season: FarmSeason
    public let dayOfSeason: Int
    public let blurb: String
    public let emoji: String

    public init(
        id: String,
        name: String,
        season: FarmSeason,
        dayOfSeason: Int,
        blurb: String,
        emoji: String
    ) {
        self.id = id
        self.name = name
        self.season = season
        self.dayOfSeason = dayOfSeason
        self.blurb = blurb
        self.emoji = emoji
    }
}

public enum GameCalendar {
    public static let daysPerSeason = 7
    public static let daysPerYear = daysPerSeason * FarmSeason.allCases.count

    public static func season(forDay day: Int) -> FarmSeason {
        let safeDay = max(1, day)
        let index = ((safeDay - 1) / daysPerSeason) % FarmSeason.allCases.count
        return FarmSeason.allCases[index]
    }

    public static func dayOfSeason(forDay day: Int) -> Int {
        ((max(1, day) - 1) % daysPerSeason) + 1
    }

    public static func year(forDay day: Int) -> Int {
        ((max(1, day) - 1) / daysPerYear) + 1
    }

    public static func yearProgress(forDay day: Int) -> Double {
        let index = (max(1, day) - 1) % daysPerYear
        return Double(index) / Double(daysPerYear)
    }

    public static func festival(forDay day: Int) -> FarmFestival? {
        let season = season(forDay: day)
        guard dayOfSeason(forDay: day) == daysPerSeason else { return nil }
        switch season {
        case .spring:
            return FarmFestival(
                id: "festival.blossom",
                name: "Blossom Fair",
                season: .spring,
                dayOfSeason: daysPerSeason,
                blurb: "Lanterns in the orchard and the first honey of the year.",
                emoji: "🌸"
            )
        case .summer:
            return FarmFestival(
                id: "festival.sun",
                name: "Long Sun Supper",
                season: .summer,
                dayOfSeason: daysPerSeason,
                blurb: "Tables in the square, cold lemonade, and music until dusk.",
                emoji: "🌞"
            )
        case .autumn:
            return FarmFestival(
                id: "festival.harvest",
                name: "Hollow Harvest",
                season: .autumn,
                dayOfSeason: daysPerSeason,
                blurb: "Prize pumpkins, cider, and a very serious pie contest.",
                emoji: "🎃"
            )
        case .winter:
            return FarmFestival(
                id: "festival.lantern",
                name: "Lantern Night",
                season: .winter,
                dayOfSeason: daysPerSeason,
                blurb: "Warm windows, paper lanterns, and a walk through the snow.",
                emoji: "🏮"
            )
        }
    }

    public static func nextFestival(afterDay day: Int) -> FarmFestival? {
        for offset in 0..<daysPerYear {
            if let festival = festival(forDay: day + offset) {
                return festival
            }
        }
        return nil
    }

    public static func seasonProgress(forDay day: Int) -> Double {
        Double(dayOfSeason(forDay: day)) / Double(daysPerSeason)
    }
}

// MARK: - Fishing

public enum FishRarity: String, Codable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    public var title: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }

    public var stars: String {
        switch self {
        case .common: return "★"
        case .uncommon: return "★★"
        case .rare: return "★★★"
        case .epic: return "★★★★"
        case .legendary: return "★★★★★"
        }
    }

    public var tintHex: String {
        switch self {
        case .common: return "7A6A5F"
        case .uncommon: return "4F8A5A"
        case .rare: return "4F6D8A"
        case .epic: return "8E6BC4"
        case .legendary: return "B8892E"
        }
    }

    public var xp: Int {
        switch self {
        case .common: return 5
        case .uncommon: return 10
        case .rare: return 20
        case .epic: return 35
        case .legendary: return 60
        }
    }

    /// Relative chance at the end of a fishing line before rod and weather
    /// bonuses are applied.
    public var baseWeight: Double {
        switch self {
        case .common: return 48
        case .uncommon: return 27
        case .rare: return 15
        case .epic: return 7
        case .legendary: return 3
        }
    }
}

public enum FishTimeWindow: String, Codable, CaseIterable, Sendable {
    case any
    case dawn
    case day
    case dusk
    case night

    public var title: String {
        switch self {
        case .any: return "Any time"
        case .dawn: return "Dawn"
        case .day: return "Daytime"
        case .dusk: return "Dusk"
        case .night: return "Night"
        }
    }

    public var icon: String {
        switch self {
        case .any: return "clock"
        case .dawn: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .dusk: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    public func matches(timeOfDay: Double) -> Bool {
        switch self {
        case .any: return true
        case .dawn: return timeOfDay >= 0.18 && timeOfDay < 0.32
        case .day: return timeOfDay >= 0.32 && timeOfDay < 0.66
        case .dusk: return timeOfDay >= 0.66 && timeOfDay < 0.84
        case .night: return timeOfDay >= 0.84 || timeOfDay < 0.18
        }
    }
}

public struct FishDefinition: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let rarity: FishRarity
    public let sellPrice: Int
    public let minWeight: Double
    public let maxWeight: Double
    public let difficulty: Int
    public let unlockRodLevel: Int
    public let timeWindow: FishTimeWindow
    public let preferredWeather: [Weather]
    public let emoji: String
    public let blurb: String
    public let spriteKey: String

    public init(
        id: String,
        name: String,
        rarity: FishRarity,
        sellPrice: Int,
        minWeight: Double,
        maxWeight: Double,
        difficulty: Int,
        unlockRodLevel: Int,
        timeWindow: FishTimeWindow = .any,
        preferredWeather: [Weather] = [],
        emoji: String,
        blurb: String,
        spriteKey: String
    ) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.sellPrice = sellPrice
        self.minWeight = minWeight
        self.maxWeight = maxWeight
        self.difficulty = difficulty
        self.unlockRodLevel = unlockRodLevel
        self.timeWindow = timeWindow
        self.preferredWeather = preferredWeather
        self.emoji = emoji
        self.blurb = blurb
        self.spriteKey = spriteKey
    }

    public var itemID: String { "fish.\(id)" }

    public func weightRangeText(metric: Bool = false) -> String {
        let unit = metric ? "kg" : "lb"
        return String(format: "%.1f–%.1f %@", minWeight, maxWeight, unit)
    }
}

public struct FishingCatchRecord: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var fishID: String
    public var weight: Double
    public var caughtAt: Date

    public init(id: UUID = UUID(), fishID: String, weight: Double, caughtAt: Date) {
        self.id = id
        self.fishID = fishID
        self.weight = weight
        self.caughtAt = caughtAt
    }
}

public struct FishingState: Codable, Sendable, Equatable {
    public var rodLevel: Int = 1
    public var totalCasts: Int = 0
    public var totalCatches: Int = 0
    public var catches: [String: Int] = [:]
    public var bestWeight: [String: Double] = [:]
    public var biggestFishID: String?
    public var biggestWeight: Double = 0
    public var perfectCasts: Int = 0
    public var recentCatches: [FishingCatchRecord] = []

    public init() {}

    public var uniqueCatches: Int {
        catches.values.filter { $0 > 0 }.count
    }

    public var averageWeight: Double {
        guard !bestWeight.isEmpty else { return 0 }
        return bestWeight.values.reduce(0, +) / Double(bestWeight.count)
    }

    private enum CodingKeys: String, CodingKey {
        case rodLevel, totalCasts, totalCatches, catches, bestWeight
        case biggestFishID, biggestWeight, perfectCasts, recentCatches
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rodLevel = try container.decodeIfPresent(Int.self, forKey: .rodLevel) ?? 1
        totalCasts = try container.decodeIfPresent(Int.self, forKey: .totalCasts) ?? 0
        totalCatches = try container.decodeIfPresent(Int.self, forKey: .totalCatches) ?? 0
        catches = try container.decodeIfPresent([String: Int].self, forKey: .catches) ?? [:]
        bestWeight = try container.decodeIfPresent([String: Double].self, forKey: .bestWeight) ?? [:]
        biggestFishID = try container.decodeIfPresent(String.self, forKey: .biggestFishID)
        biggestWeight = try container.decodeIfPresent(Double.self, forKey: .biggestWeight) ?? 0
        perfectCasts = try container.decodeIfPresent(Int.self, forKey: .perfectCasts) ?? 0
        recentCatches = try container.decodeIfPresent([FishingCatchRecord].self, forKey: .recentCatches) ?? []
    }
}

public enum FishingBalance {
    public static let baitItemID = "supply.bait"
    public static let maxRodLevel = 5
    public static let baitPrice = 8
    public static let perfectCastChance = 0.16

    public static let rodNames = [
        "Bent Willow Rod",
        "Oiled Bamboo Rod",
        "Copper Reel Rod",
        "Moonlit Carbon Rod",
        "Hollowmaster Rod"
    ]

    public static func upgradeCost(from level: Int) -> Int {
        switch level {
        case 1: return 220
        case 2: return 550
        case 3: return 1_100
        case 4: return 2_400
        default: return 0
        }
    }

    public static func upgradeLevelRequirement(from level: Int) -> Int {
        switch level {
        case 1: return 2
        case 2: return 4
        case 3: return 6
        case 4: return 8
        default: return 99
        }
    }

    public static func rodName(level: Int) -> String {
        let index = max(0, min(rodNames.count - 1, level - 1))
        return rodNames[index]
    }
}

// MARK: - Cooking

public enum RecipeCategory: String, Codable, CaseIterable, Sendable {
    case breakfast
    case lunch
    case dinner
    case dessert
    case drink

    public var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .dessert: return "Dessert"
        case .drink: return "Drinks"
        }
    }

    public var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "takeoutbag.and.cup.and.straw.fill"
        case .dinner: return "fork.knife"
        case .dessert: return "birthday.cake.fill"
        case .drink: return "cup.and.saucer.fill"
        }
    }

    public var tintHex: String {
        switch self {
        case .breakfast: return "E8BC55"
        case .lunch: return "7DBF5B"
        case .dinner: return "C96A4B"
        case .dessert: return "E8A7B7"
        case .drink: return "8E6BC4"
        }
    }
}

public enum FoodBuffKind: String, Codable, CaseIterable, Sendable {
    case growth
    case market
    case fishing
    case feast

    public var title: String {
        switch self {
        case .growth: return "Green Thumb"
        case .market: return "Market Charm"
        case .fishing: return "Angler's Luck"
        case .feast: return "Hollow Feast"
        }
    }

    public var icon: String {
        switch self {
        case .growth: return "leaf.fill"
        case .market: return "tag.fill"
        case .fishing: return "fish.fill"
        case .feast: return "sparkles"
        }
    }

    public var tintHex: String {
        switch self {
        case .growth: return "4F8A5A"
        case .market: return "B8892E"
        case .fishing: return "4F6D8A"
        case .feast: return "8E6BC4"
        }
    }

    public var summary: String {
        switch self {
        case .growth: return "Crops grow faster while the meal settles."
        case .market: return "Market stalls pay a little more today."
        case .fishing: return "Rare fish are more willing to bite."
        case .feast: return "A full spread: faster crops and better prices."
        }
    }
}

public struct RecipeBuff: Codable, Sendable, Equatable {
    public let kind: FoodBuffKind
    public let magnitude: Double
    public let duration: Double

    public init(kind: FoodBuffKind, magnitude: Double, duration: Double) {
        self.kind = kind
        self.magnitude = magnitude
        self.duration = duration
    }

    public var percent: Int { Int((magnitude * 100).rounded()) }
    public var durationText: String {
        if duration >= 3_600 { return String(format: "%.1fh", duration / 3_600) }
        return "\(Int(duration / 60))m"
    }
}

public struct FoodBuff: Codable, Identifiable, Sendable, Equatable {
    public var kind: FoodBuffKind
    public var magnitude: Double
    public var expiresAt: Date
    public var name: String
    public var emoji: String

    public init(
        kind: FoodBuffKind,
        magnitude: Double,
        expiresAt: Date,
        name: String,
        emoji: String
    ) {
        self.kind = kind
        self.magnitude = magnitude
        self.expiresAt = expiresAt
        self.name = name
        self.emoji = emoji
    }

    public var id: String { "\(kind.rawValue)-\(name)" }

    public func isActive(at date: Date) -> Bool {
        expiresAt > date
    }

    public func secondsRemaining(at date: Date) -> Double {
        max(0, expiresAt.timeIntervalSince(date))
    }

    public var percent: Int { Int((magnitude * 100).rounded()) }
}

public struct RecipeDefinition: Identifiable, Sendable, Equatable {
    public let id: String
    public let dishItemID: String
    public let name: String
    public let category: RecipeCategory
    public let ingredients: [String: Int]
    public let unlockLevel: Int
    public let xp: Int
    public let prepSeconds: Double
    public let buff: RecipeBuff
    public let emoji: String
    public let blurb: String
    public let spriteKey: String

    public init(
        id: String,
        dishItemID: String,
        name: String,
        category: RecipeCategory,
        ingredients: [String: Int],
        unlockLevel: Int,
        xp: Int,
        prepSeconds: Double = 12,
        buff: RecipeBuff,
        emoji: String,
        blurb: String,
        spriteKey: String
    ) {
        self.id = id
        self.dishItemID = dishItemID
        self.name = name
        self.category = category
        self.ingredients = ingredients
        self.unlockLevel = unlockLevel
        self.xp = xp
        self.prepSeconds = prepSeconds
        self.buff = buff
        self.emoji = emoji
        self.blurb = blurb
        self.spriteKey = spriteKey
    }

    public var ingredientCount: Int {
        ingredients.values.reduce(0, +)
    }

    public var buffSummary: String {
        "+\(buff.percent)% · \(buff.kind.title) · \(buff.durationText)"
    }
}

// MARK: - Crop mastery

public struct CropMasteryTier: Identifiable, Sendable, Equatable {
    public let level: Int
    public let threshold: Int
    public let title: String
    public let emoji: String

    public var id: Int { level }
}

public enum CropMastery {
    public static let tiers: [CropMasteryTier] = [
        CropMasteryTier(level: 0, threshold: 0, title: "Seedling", emoji: "🌱"),
        CropMasteryTier(level: 1, threshold: 6, title: "Field Hand", emoji: "🌿"),
        CropMasteryTier(level: 2, threshold: 15, title: "Green Thumb", emoji: "🌻"),
        CropMasteryTier(level: 3, threshold: 30, title: "Harvest Keeper", emoji: "🧺"),
        CropMasteryTier(level: 4, threshold: 50, title: "Hollow Legend", emoji: "🏆")
    ]

    public static func level(for harvests: Int) -> Int {
        tiers.last { harvests >= $0.threshold }?.level ?? 0
    }

    public static func tier(for harvests: Int) -> CropMasteryTier {
        let level = level(for: harvests)
        return tiers.first { $0.level == level } ?? tiers[0]
    }

    public static func nextTier(for harvests: Int) -> CropMasteryTier? {
        tiers.first { $0.threshold > harvests }
    }

    public static func progress(for harvests: Int) -> Double {
        guard let next = nextTier(for: harvests) else { return 1 }
        let currentThreshold = tier(for: harvests).threshold
        let span = max(1, next.threshold - currentThreshold)
        return min(1, Double(harvests - currentThreshold) / Double(span))
    }

    /// Each mastery rank adds one percent to the sale value of that crop.
    public static func saleBonus(for harvests: Int) -> Double {
        Double(level(for: harvests)) * 0.01
    }

    public static func stars(for harvests: Int) -> String {
        let level = level(for: harvests)
        return String(repeating: "★", count: level) + String(repeating: "☆", count: max(0, 4 - level))
    }
}

// MARK: - Achievements

public enum AchievementCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case farming
    case barn
    case market
    case fishing
    case home
    case story

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .farming: return "Fields"
        case .barn: return "Barn"
        case .market: return "Market"
        case .fishing: return "Pond"
        case .home: return "Home"
        case .story: return "Story"
        }
    }

    public var icon: String {
        switch self {
        case .farming: return "leaf.fill"
        case .barn: return "pawprint.fill"
        case .market: return "cart.fill"
        case .fishing: return "fish.fill"
        case .home: return "sofa.fill"
        case .story: return "book.closed.fill"
        }
    }

    public var tintHex: String {
        switch self {
        case .farming: return "4F8A5A"
        case .barn: return "C96A4B"
        case .market: return "B8892E"
        case .fishing: return "4F6D8A"
        case .home: return "8E6BC4"
        case .story: return "3E6B4F"
        }
    }
}

public enum AchievementMetric: String, Codable, CaseIterable, Sendable {
    case cropsPlanted
    case cropsHarvested
    case uniqueCropsHarvested
    case cropHarvestedByID
    case animalsAdopted
    case animalProducts
    case animalsPetted
    case itemsSold
    case itemSoldByID
    case coinsEarned
    case dailyOrdersCompleted
    case level
    case questsCompleted
    case decorationsPlaced
    case comfort
    case themesOwned
    case fishCaught
    case uniqueFishCaught
    case fishCaughtByID
    case legendaryFishCaught
    case rodLevel
    case dishesCooked
    case uniqueRecipesCooked
    case dishesEaten
    case giftsClaimed
    case daysPlayed

    public var title: String {
        switch self {
        case .cropsPlanted: return "Crops planted"
        case .cropsHarvested: return "Crops harvested"
        case .uniqueCropsHarvested: return "Crop varieties harvested"
        case .cropHarvestedByID: return "A special crop harvested"
        case .animalsAdopted: return "Animals adopted"
        case .animalProducts: return "Barn goods collected"
        case .animalsPetted: return "Animals petted"
        case .itemsSold: return "Goods sold"
        case .itemSoldByID: return "A special item sold"
        case .coinsEarned: return "Coins earned"
        case .dailyOrdersCompleted: return "Daily orders completed"
        case .level: return "Farmer level"
        case .questsCompleted: return "Story chapters completed"
        case .decorationsPlaced: return "Decorations placed"
        case .comfort: return "Home comfort"
        case .themesOwned: return "House themes owned"
        case .fishCaught: return "Fish caught"
        case .uniqueFishCaught: return "Fish species caught"
        case .fishCaughtByID: return "A special fish caught"
        case .legendaryFishCaught: return "Legendary fish caught"
        case .rodLevel: return "Fishing rod level"
        case .dishesCooked: return "Dishes cooked"
        case .uniqueRecipesCooked: return "Recipes discovered"
        case .dishesEaten: return "Meals enjoyed"
        case .giftsClaimed: return "Daily gifts claimed"
        case .daysPlayed: return "Days in the Hollow"
        }
    }
}

public struct AchievementDefinition: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let blurb: String
    public let category: AchievementCategory
    public let metric: AchievementMetric
    public let target: Int
    public let targetID: String?
    public let rewardCoins: Int
    public let rewardXP: Int
    public let rewardItems: [String: Int]
    public let icon: String
    public let isSecret: Bool

    public init(
        id: String,
        title: String,
        blurb: String,
        category: AchievementCategory,
        metric: AchievementMetric,
        target: Int,
        targetID: String? = nil,
        rewardCoins: Int,
        rewardXP: Int,
        rewardItems: [String: Int] = [:],
        icon: String,
        isSecret: Bool = false
    ) {
        self.id = id
        self.title = title
        self.blurb = blurb
        self.category = category
        self.metric = metric
        self.target = target
        self.targetID = targetID
        self.rewardCoins = rewardCoins
        self.rewardXP = rewardXP
        self.rewardItems = rewardItems
        self.icon = icon
        self.isSecret = isSecret
    }
}

public struct AchievementProgress: Identifiable, Sendable, Equatable {
    public let definition: AchievementDefinition
    public let current: Int
    public let isClaimed: Bool

    public var id: String { definition.id }
    public var target: Int { max(1, definition.target) }
    public var isComplete: Bool { current >= target }
    public var fraction: Double { min(1, Double(current) / Double(target)) }
    public var canClaim: Bool { isComplete && !isClaimed }
    public var remaining: Int { max(0, target - current) }
}

// MARK: - Daily gifts

public struct DailyGiftDefinition: Identifiable, Sendable, Equatable {
    public let day: Int
    public let title: String
    public let blurb: String
    public let coins: Int
    public let xp: Int
    public let items: [String: Int]
    public let emoji: String
    public let isMilestone: Bool

    public var id: Int { day }
}

// MARK: - Collections

public enum CollectionCategory: String, CaseIterable, Identifiable, Sendable {
    case crops
    case fish
    case barnGoods
    case dishes
    case recipes

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .crops: return "Crops"
        case .fish: return "Fish"
        case .barnGoods: return "Barn Goods"
        case .dishes: return "Dishes"
        case .recipes: return "Recipes"
        }
    }

    public var icon: String {
        switch self {
        case .crops: return "carrot.fill"
        case .fish: return "fish.fill"
        case .barnGoods: return "shippingbox.fill"
        case .dishes: return "fork.knife"
        case .recipes: return "book.pages.fill"
        }
    }
}

// MARK: - Activity state

/// Everything the newer town systems need, kept in one version-tolerant value.
/// Old saves decode with sensible defaults instead of being rejected.
public struct ActivityState: Codable, Sendable, Equatable {
    public var fishing: FishingState = FishingState()
    public var cookedRecipeIDs: [String: Int] = [:]
    public var dishesEaten: Int = 0
    public var favoriteRecipeID: String?
    public var claimedAchievements: [String] = []
    public var achievementClaimDates: [String: Date] = [:]
    public var lastGiftDay: Int = 0
    public var giftStreak: Int = 0
    public var giftsClaimed: Int = 0
    public var activeBuff: FoodBuff?
    public var animalsPetted: Int = 0
    public var dailyOrdersCompleted: Int = 0
    public var weatherHistory: [Weather] = []
    public var lastRodUpgradeDay: Int = 0

    public init(weather: Weather = .sunny) {
        weatherHistory = [weather]
    }

    public var dishesCooked: Int {
        cookedRecipeIDs.values.reduce(0, +)
    }

    public var uniqueRecipesCooked: Int {
        cookedRecipeIDs.values.filter { $0 > 0 }.count
    }

    public var uniqueFishCaught: Int {
        fishing.uniqueCatches
    }

    public var hasClaimedGiftToday: Bool {
        lastGiftDay > 0
    }

    public func hasClaimedGift(onDay day: Int) -> Bool {
        lastGiftDay == day
    }

    public func buffActive(at date: Date) -> Bool {
        guard let activeBuff else { return false }
        return activeBuff.isActive(at: date)
    }

    public func isAchievementClaimed(_ id: String) -> Bool {
        claimedAchievements.contains(id)
    }

    private enum CodingKeys: String, CodingKey {
        case fishing
        case cookedRecipeIDs
        case dishesEaten
        case favoriteRecipeID
        case claimedAchievements
        case achievementClaimDates
        case lastGiftDay
        case giftStreak
        case giftsClaimed
        case activeBuff
        case animalsPetted
        case dailyOrdersCompleted
        case weatherHistory
        case lastRodUpgradeDay
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fishing = try container.decodeIfPresent(FishingState.self, forKey: .fishing) ?? FishingState()
        cookedRecipeIDs = try container.decodeIfPresent([String: Int].self, forKey: .cookedRecipeIDs) ?? [:]
        dishesEaten = try container.decodeIfPresent(Int.self, forKey: .dishesEaten) ?? 0
        favoriteRecipeID = try container.decodeIfPresent(String.self, forKey: .favoriteRecipeID)
        claimedAchievements = try container.decodeIfPresent([String].self, forKey: .claimedAchievements) ?? []
        achievementClaimDates = try container.decodeIfPresent([String: Date].self, forKey: .achievementClaimDates) ?? [:]
        lastGiftDay = try container.decodeIfPresent(Int.self, forKey: .lastGiftDay) ?? 0
        giftStreak = try container.decodeIfPresent(Int.self, forKey: .giftStreak) ?? 0
        giftsClaimed = try container.decodeIfPresent(Int.self, forKey: .giftsClaimed) ?? 0
        activeBuff = try container.decodeIfPresent(FoodBuff.self, forKey: .activeBuff)
        animalsPetted = try container.decodeIfPresent(Int.self, forKey: .animalsPetted) ?? 0
        dailyOrdersCompleted = try container.decodeIfPresent(Int.self, forKey: .dailyOrdersCompleted) ?? 0
        weatherHistory = try container.decodeIfPresent([Weather].self, forKey: .weatherHistory) ?? [.sunny]
        lastRodUpgradeDay = try container.decodeIfPresent(Int.self, forKey: .lastRodUpgradeDay) ?? 0
    }
}

// MARK: - Weather helpers

public extension Weather {
    var fishingBonus: Double {
        switch self {
        case .sunny: return 0.00
        case .rainy: return 0.06
        case .breezy: return 0.02
        case .heatwave: return -0.02
        case .storm: return 0.10
        }
    }

    var symbolName: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.rain.fill"
        case .breezy: return "wind"
        case .heatwave: return "thermometer.sun.fill"
        case .storm: return "cloud.bolt.rain.fill"
        }
    }

    var marketHint: String {
        switch self {
        case .sunny: return "A steady market day."
        case .rainy: return "Fewer shoppers, but the stalls are calm."
        case .breezy: return "Good drying weather for herbs."
        case .heatwave: return "Bring water and sell early."
        case .storm: return "The square is quiet. Perfect for a pantry day."
        }
    }
}
