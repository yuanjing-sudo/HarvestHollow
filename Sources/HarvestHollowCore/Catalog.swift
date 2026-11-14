import Foundation

// MARK: - Item definitions

public enum ItemKind: String, Codable, CaseIterable, Sendable {
    case seed
    case produce
    case animalProduct
    case fish
    case dish
    case supply
    case furniture

    public var title: String {
        switch self {
        case .seed: return "Seeds"
        case .produce: return "Crops"
        case .animalProduct: return "Barn Goods"
        case .fish: return "Pond Fish"
        case .dish: return "Kitchen Dishes"
        case .supply: return "Supplies"
        case .furniture: return "Furniture"
        }
    }

    public var symbol: String {
        switch self {
        case .seed: return "leaf"
        case .produce: return "carrot"
        case .animalProduct: return "shippingbox"
        case .fish: return "fish"
        case .dish: return "fork.knife"
        case .supply: return "bag"
        case .furniture: return "sofa"
        }
    }
}

public struct ItemDefinition: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: ItemKind
    public let sellPrice: Int
    public let emoji: String
    public let detail: String
    public let spriteKey: String?

    public var isSellable: Bool { sellPrice > 0 }
}

public struct SupplyDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let price: Int
    public let emoji: String
    public let detail: String
}

// MARK: - Crops

public struct CropDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let seedItemID: String
    public let produceItemID: String
    public let seedPrice: Int
    public let sellPrice: Int
    public let growSeconds: Double
    public let minYield: Int
    public let maxYield: Int
    public let xp: Int
    public let unlockLevel: Int
    public let emoji: String
    public let blurb: String
    public let spriteKey: String

    public var seedName: String { "\(name) Seeds" }
}

// MARK: - Animals

public struct AnimalSpecies: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let price: Int
    public let unlockLevel: Int
    public let productItemID: String
    public let produceSeconds: Double
    public let capacity: Int
    public let xpPerProduct: Int
    public let spriteKey: String
    public let blurb: String
}

// MARK: - House

public struct FurnitureDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let width: Int
    public let height: Int
    public let comfort: Int
    public let price: Int
    public let emoji: String
    public let blurb: String
    public let spriteKey: String
}

public struct HouseTheme: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let price: Int
    public let wallHex: String
    public let floorHex: String
    public let accentHex: String

    public var isFree: Bool { price == 0 }
}

// MARK: - Quests

public enum QuestMetric: String, Codable, Sendable {
    case cropsPlanted
    case cropsHarvested
    case itemsSold
    case coinsEarned
    case animalsBought
    case animalProducts
    case decorationsPlaced
    case level
    case comfort
    case questsCompleted

    public var title: String {
        switch self {
        case .cropsPlanted: return "Crops planted"
        case .cropsHarvested: return "Crops harvested"
        case .itemsSold: return "Items sold"
        case .coinsEarned: return "Coins earned"
        case .animalsBought: return "Animals adopted"
        case .animalProducts: return "Barn goods collected"
        case .decorationsPlaced: return "Decorations placed"
        case .level: return "Farm level"
        case .comfort: return "Home comfort"
        case .questsCompleted: return "Quests completed"
        }
    }
}

public struct QuestObjective: Sendable {
    public let metric: QuestMetric
    public let target: Int

    public init(_ metric: QuestMetric, _ target: Int) {
        self.metric = metric
        self.target = target
    }

    public var label: String {
        "\(metric.title) \(target)"
    }
}

public struct QuestReward: Sendable {
    public let coins: Int
    public let xp: Int
    public let items: [String: Int]

    public init(coins: Int, xp: Int, items: [String: Int] = [:]) {
        self.coins = coins
        self.xp = xp
        self.items = items
    }
}

public struct QuestDefinition: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let blurb: String
    public let objectives: [QuestObjective]
    public let reward: QuestReward
}

// MARK: - Catalog

public struct GameCatalog: Sendable {
    public let crops: [CropDefinition]
    public let animals: [AnimalSpecies]
    public let furniture: [FurnitureDefinition]
    public let themes: [HouseTheme]
    public let supplies: [SupplyDefinition]
    public let quests: [QuestDefinition]
    public let items: [String: ItemDefinition]
    public let fish: [FishDefinition]
    public let recipes: [RecipeDefinition]
    public let achievements: [AchievementDefinition]
    public let dailyGifts: [DailyGiftDefinition]

    public static let standard = GameCatalog()

    public init() {
        let crops: [CropDefinition] = [
            CropDefinition(
                id: "wheat", name: "Wheat",
                seedItemID: "seed.wheat", produceItemID: "crop.wheat",
                seedPrice: 15, sellPrice: 8, growSeconds: 30,
                minYield: 2, maxYield: 4, xp: 4, unlockLevel: 1,
                emoji: "🌾", blurb: "A dependable crop that loves a sunny field.",
                spriteKey: "crop.wheat"
            ),
            CropDefinition(
                id: "carrot", name: "Carrot",
                seedItemID: "seed.carrot", produceItemID: "crop.carrot",
                seedPrice: 25, sellPrice: 14, growSeconds: 40,
                minYield: 2, maxYield: 3, xp: 6, unlockLevel: 1,
                emoji: "🥕", blurb: "Crunchy, sweet, and always in demand.",
                spriteKey: "crop.carrot"
            ),
            CropDefinition(
                id: "tomato", name: "Tomato",
                seedItemID: "seed.tomato", produceItemID: "crop.tomato",
                seedPrice: 45, sellPrice: 26, growSeconds: 60,
                minYield: 2, maxYield: 3, xp: 10, unlockLevel: 1,
                emoji: "🍅", blurb: "Sun-ripened tomatoes make the market happy.",
                spriteKey: "crop.tomato"
            ),
            CropDefinition(
                id: "strawberry", name: "Strawberry",
                seedItemID: "seed.strawberry", produceItemID: "crop.strawberry",
                seedPrice: 70, sellPrice: 36, growSeconds: 75,
                minYield: 2, maxYield: 3, xp: 14, unlockLevel: 2,
                emoji: "🍓", blurb: "A little fussy, but worth every berry.",
                spriteKey: "crop.strawberry"
            ),
            CropDefinition(
                id: "sunflower", name: "Sunflower",
                seedItemID: "seed.sunflower", produceItemID: "crop.sunflower",
                seedPrice: 100, sellPrice: 68, growSeconds: 90,
                minYield: 2, maxYield: 2, xp: 18, unlockLevel: 3,
                emoji: "🌻", blurb: "Tall, cheerful, and a favourite at the market.",
                spriteKey: "crop.sunflower"
            ),
            CropDefinition(
                id: "corn", name: "Corn",
                seedItemID: "seed.corn", produceItemID: "crop.corn",
                seedPrice: 120, sellPrice: 82, growSeconds: 110,
                minYield: 2, maxYield: 2, xp: 22, unlockLevel: 3,
                emoji: "🌽", blurb: "Golden ears that rustle in the breeze.",
                spriteKey: "crop.corn"
            ),
            CropDefinition(
                id: "lavender", name: "Lavender",
                seedItemID: "seed.lavender", produceItemID: "crop.lavender",
                seedPrice: 160, sellPrice: 105, growSeconds: 130,
                minYield: 2, maxYield: 2, xp: 28, unlockLevel: 4,
                emoji: "🪻", blurb: "Fragrant stems for sleepy cottage evenings.",
                spriteKey: "crop.lavender"
            ),
            CropDefinition(
                id: "pumpkin", name: "Pumpkin",
                seedItemID: "seed.pumpkin", produceItemID: "crop.pumpkin",
                seedPrice: 180, sellPrice: 240, growSeconds: 150,
                minYield: 1, maxYield: 1, xp: 35, unlockLevel: 4,
                emoji: "🎃", blurb: "One big, prize-winning pumpkin per seed.",
                spriteKey: "crop.pumpkin"
            ),
            CropDefinition(
                id: "moonberry", name: "Moonberry",
                seedItemID: "seed.moonberry", produceItemID: "crop.moonberry",
                seedPrice: 400, sellPrice: 320, growSeconds: 200,
                minYield: 2, maxYield: 2, xp: 60, unlockLevel: 6,
                emoji: "🫐", blurb: "A rare night-loving berry with a silver shine.",
                spriteKey: "crop.moonberry"
            )
        ]

        let animalProducts: [ItemDefinition] = [
            ItemDefinition(id: "product.egg", name: "Egg", kind: .animalProduct,
                           sellPrice: 40, emoji: "🥚",
                           detail: "Fresh from the coop.", spriteKey: "item.egg"),
            ItemDefinition(id: "product.duckEgg", name: "Duck Egg", kind: .animalProduct,
                           sellPrice: 55, emoji: "🥚",
                           detail: "Bigger and richer than a hen's egg.", spriteKey: "item.duckEgg"),
            ItemDefinition(id: "product.milk", name: "Milk", kind: .animalProduct,
                           sellPrice: 95, emoji: "🥛",
                           detail: "Cold, creamy, and bottled at dawn.", spriteKey: "item.milk"),
            ItemDefinition(id: "product.wool", name: "Wool", kind: .animalProduct,
                           sellPrice: 110, emoji: "🧶",
                           detail: "Soft fleece for warm winter things.", spriteKey: "item.wool"),
            ItemDefinition(id: "product.truffle", name: "Truffle", kind: .animalProduct,
                           sellPrice: 210, emoji: "🍄",
                           detail: "A lucky find, sniffed out by a happy pig.", spriteKey: "item.truffle"),
            ItemDefinition(id: "product.goatMilk", name: "Goat Milk", kind: .animalProduct,
                           sellPrice: 120, emoji: "🥛",
                           detail: "Tangy and prized by the local cheesemaker.", spriteKey: "item.goatMilk"),
            ItemDefinition(id: "product.honey", name: "Honey", kind: .animalProduct,
                           sellPrice: 75, emoji: "🍯",
                           detail: "Golden, floral, and slow to pour.", spriteKey: "item.honey")
        ]

        let animals: [AnimalSpecies] = [
            AnimalSpecies(
                id: "chicken", name: "Chicken", price: 400, unlockLevel: 2,
                productItemID: "product.egg", produceSeconds: 50,
                capacity: 3, xpPerProduct: 6, spriteKey: "animal.chicken",
                blurb: "A cheerful hen who leaves an egg every little while."
            ),
            AnimalSpecies(
                id: "duck", name: "Duck", price: 650, unlockLevel: 2,
                productItemID: "product.duckEgg", produceSeconds: 55,
                capacity: 3, xpPerProduct: 8, spriteKey: "animal.duck",
                blurb: "Paddles about the yard and lays generous eggs."
            ),
            AnimalSpecies(
                id: "cow", name: "Cow", price: 1200, unlockLevel: 3,
                productItemID: "product.milk", produceSeconds: 70,
                capacity: 4, xpPerProduct: 10, spriteKey: "animal.cow",
                blurb: "A gentle soul with a talent for creamy milk."
            ),
            AnimalSpecies(
                id: "sheep", name: "Sheep", price: 900, unlockLevel: 3,
                productItemID: "product.wool", produceSeconds: 80,
                capacity: 3, xpPerProduct: 9, spriteKey: "animal.sheep",
                blurb: "Fluffy, friendly, and generous with fleece."
            ),
            AnimalSpecies(
                id: "pig", name: "Pig", price: 1600, unlockLevel: 4,
                productItemID: "product.truffle", produceSeconds: 100,
                capacity: 2, xpPerProduct: 14, spriteKey: "animal.pig",
                blurb: "A clever forager who turns up the finest truffles."
            ),
            AnimalSpecies(
                id: "goat", name: "Goat", price: 1100, unlockLevel: 4,
                productItemID: "product.goatMilk", produceSeconds: 65,
                capacity: 3, xpPerProduct: 10, spriteKey: "animal.goat",
                blurb: "Curious, bouncy, and surprisingly good company."
            ),
            AnimalSpecies(
                id: "bee", name: "Honey Bee", price: 700, unlockLevel: 5,
                productItemID: "product.honey", produceSeconds: 60,
                capacity: 4, xpPerProduct: 8, spriteKey: "animal.bee",
                blurb: "A little hive that hums the garden awake."
            )
        ]

        let furniture: [FurnitureDefinition] = [
            FurnitureDefinition(id: "furniture.chair", name: "Oak Chair", width: 1, height: 1,
                                comfort: 2, price: 60, emoji: "🪑",
                                blurb: "A sturdy little chair by the window.",
                                spriteKey: "furniture.chair"),
            FurnitureDefinition(id: "furniture.plant", name: "Potted Fern", width: 1, height: 1,
                                comfort: 3, price: 90, emoji: "🪴",
                                blurb: "Brings a little of the garden inside.",
                                spriteKey: "furniture.plant"),
            FurnitureDefinition(id: "furniture.lamp", name: "Warm Lamp", width: 1, height: 1,
                                comfort: 3, price: 120, emoji: "💡",
                                blurb: "A soft glow for late-night reading.",
                                spriteKey: "furniture.lamp"),
            FurnitureDefinition(id: "furniture.teddy", name: "Teddy Bear", width: 1, height: 1,
                                comfort: 3, price: 130, emoji: "🧸",
                                blurb: "Found at the market. Instantly loved.",
                                spriteKey: "furniture.teddy"),
            FurnitureDefinition(id: "furniture.rug", name: "Woven Rug", width: 3, height: 2,
                                comfort: 4, price: 150, emoji: "🧶",
                                blurb: "Hand-woven in warm autumn colours.",
                                spriteKey: "furniture.rug"),
            FurnitureDefinition(id: "furniture.table", name: "Tea Table", width: 2, height: 1,
                                comfort: 4, price: 180, emoji: "🫖",
                                blurb: "Perfect for a pot of tea and a slice of cake.",
                                spriteKey: "furniture.table"),
            FurnitureDefinition(id: "furniture.painting", name: "Hill Painting", width: 1, height: 1,
                                comfort: 5, price: 220, emoji: "🖼️",
                                blurb: "A tiny landscape of the valley at sunset.",
                                spriteKey: "furniture.painting"),
            FurnitureDefinition(id: "furniture.bookshelf", name: "Bookshelf", width: 2, height: 1,
                                comfort: 6, price: 260, emoji: "📚",
                                blurb: "Old favourites and a few mysteries.",
                                spriteKey: "furniture.bookshelf"),
            FurnitureDefinition(id: "furniture.fireplace", name: "Fireplace", width: 2, height: 1,
                                comfort: 8, price: 380, emoji: "🔥",
                                blurb: "The heart of a cozy cottage.",
                                spriteKey: "furniture.fireplace"),
            FurnitureDefinition(id: "furniture.aquarium", name: "Aquarium", width: 2, height: 1,
                                comfort: 7, price: 420, emoji: "🐠",
                                blurb: "Tiny fish drifting through a quiet blue world.",
                                spriteKey: "furniture.aquarium"),
            FurnitureDefinition(id: "furniture.bed", name: "Patchwork Bed", width: 2, height: 2,
                                comfort: 10, price: 700, emoji: "🛏️",
                                blurb: "A deep, dreamy sleep after a day in the fields.",
                                spriteKey: "furniture.bed"),
            FurnitureDefinition(id: "furniture.piano", name: "Parlour Piano", width: 2, height: 1,
                                comfort: 12, price: 950, emoji: "🎹",
                                blurb: "A little out of tune, but full of heart.",
                                spriteKey: "furniture.piano"),
            FurnitureDefinition(id: "furniture.vase", name: "Wildflower Vase", width: 1, height: 1,
                                comfort: 4, price: 0, emoji: "🏺",
                                blurb: "A quest keepsake. Smells like summer.",
                                spriteKey: "furniture.vase"),
            FurnitureDefinition(id: "furniture.trophy", name: "Hollow Trophy", width: 1, height: 1,
                                comfort: 8, price: 0, emoji: "🏆",
                                blurb: "Proof that the valley knows your name.",
                                spriteKey: "furniture.trophy")
        ]

        let supplies: [SupplyDefinition] = [
            SupplyDefinition(id: "supply.feed", name: "Animal Feed", price: 15,
                             emoji: "🌿", detail: "One bag keeps an animal producing for two cycles."),
            SupplyDefinition(id: "supply.fertilizer", name: "Fertilizer", price: 40,
                             emoji: "💩", detail: "Speeds a growing crop up by half and adds +1 yield."),
            SupplyDefinition(id: "supply.bait", name: "Pond Bait", price: FishingBalance.baitPrice,
                             emoji: "🪱", detail: "One cast at the Hollow pond. Fish seem to like it.")
        ]

        var items: [String: ItemDefinition] = [:]
        for crop in crops {
            items[crop.seedItemID] = ItemDefinition(
                id: crop.seedItemID, name: crop.seedName, kind: .seed,
                sellPrice: max(1, crop.seedPrice / 2), emoji: "🌱",
                detail: "Plant in a tilled plot. Grows in \(Int(crop.growSeconds))s when watered.",
                spriteKey: "item.seed"
            )
            items[crop.produceItemID] = ItemDefinition(
                id: crop.produceItemID, name: crop.name, kind: .produce,
                sellPrice: crop.sellPrice, emoji: crop.emoji,
                detail: crop.blurb, spriteKey: crop.spriteKey
            )
        }
        for product in animalProducts {
            items[product.id] = product
        }
        for supply in supplies {
            items[supply.id] = ItemDefinition(
                id: supply.id, name: supply.name, kind: .supply,
                sellPrice: max(1, supply.price / 2), emoji: supply.emoji,
                detail: supply.detail, spriteKey: nil
            )
        }
        for piece in furniture {
            items[piece.id] = ItemDefinition(
                id: piece.id, name: piece.name, kind: .furniture,
                sellPrice: piece.price / 2, emoji: piece.emoji,
                detail: piece.blurb, spriteKey: piece.spriteKey
            )
        }

        let fish = ActivityCatalog.fish
        for fishEntry in fish {
            items[fishEntry.itemID] = ItemDefinition(
                id: fishEntry.itemID,
                name: fishEntry.name,
                kind: .fish,
                sellPrice: fishEntry.sellPrice,
                emoji: fishEntry.emoji,
                detail: fishEntry.blurb,
                spriteKey: fishEntry.spriteKey
            )
        }

        let recipes = ActivityCatalog.recipes
        for recipe in recipes {
            items[recipe.dishItemID] = ItemDefinition(
                id: recipe.dishItemID,
                name: recipe.name,
                kind: .dish,
                sellPrice: ActivityCatalog.dishPrice(for: recipe),
                emoji: recipe.emoji,
                detail: recipe.blurb,
                spriteKey: recipe.spriteKey
            )
        }

        let themes: [HouseTheme] = [
            HouseTheme(id: "cozy", name: "Cozy Cream", price: 0,
                       wallHex: "F4E3C8", floorHex: "C98B5E", accentHex: "C96A4B"),
            HouseTheme(id: "meadow", name: "Meadow", price: 450,
                       wallHex: "DDEBC8", floorHex: "A7C97B", accentHex: "4F7D4A"),
            HouseTheme(id: "sunset", name: "Sunset", price: 650,
                       wallHex: "F6D2C0", floorHex: "C97B63", accentHex: "D97757"),
            HouseTheme(id: "midnight", name: "Midnight", price: 900,
                       wallHex: "2E3550", floorHex: "4A3A5A", accentHex: "8E7CC3"),
            HouseTheme(id: "royal", name: "Royal Lavender", price: 1400,
                       wallHex: "E8DCF5", floorHex: "8B6AAE", accentHex: "C9A227")
        ]

        let quests: [QuestDefinition] = [
            QuestDefinition(
                id: "story.01", title: "A New Beginning",
                blurb: "The old Hollow farm is yours now. Let's wake up the fields.",
                objectives: [QuestObjective(.cropsPlanted, 3), QuestObjective(.cropsHarvested, 2)],
                reward: QuestReward(coins: 60, xp: 25, items: ["seed.carrot": 5])
            ),
            QuestDefinition(
                id: "story.02", title: "Market Debut",
                blurb: "Pack a basket and meet the folks at the Saturday market.",
                objectives: [QuestObjective(.itemsSold, 8)],
                reward: QuestReward(coins: 120, xp: 30, items: ["supply.feed": 2])
            ),
            QuestDefinition(
                id: "story.03", title: "Barn Buddy",
                blurb: "The barn is too quiet. Bring home a friend.",
                objectives: [QuestObjective(.animalsBought, 1)],
                reward: QuestReward(coins: 150, xp: 40, items: ["supply.feed": 3])
            ),
            QuestDefinition(
                id: "story.04", title: "Cottage Charm",
                blurb: "A home should feel like one. Place a couple of decorations.",
                objectives: [QuestObjective(.decorationsPlaced, 2)],
                reward: QuestReward(coins: 180, xp: 40, items: ["furniture.chair": 1])
            ),
            QuestDefinition(
                id: "story.05", title: "Green Thumb",
                blurb: "Fifteen harvests in, the neighbours are starting to talk.",
                objectives: [QuestObjective(.cropsHarvested, 15)],
                reward: QuestReward(coins: 250, xp: 80, items: ["supply.fertilizer": 3])
            ),
            QuestDefinition(
                id: "story.06", title: "Dairy Days",
                blurb: "There is nothing like a full pail and a happy barn.",
                objectives: [QuestObjective(.animalProducts, 6)],
                reward: QuestReward(coins: 300, xp: 100, items: ["supply.feed": 5])
            ),
            QuestDefinition(
                id: "story.07", title: "Rising Star",
                blurb: "Word travels fast. Show the valley what you can grow.",
                objectives: [QuestObjective(.level, 5)],
                reward: QuestReward(coins: 400, xp: 120, items: ["furniture.vase": 1])
            ),
            QuestDefinition(
                id: "story.08", title: "Home Comfort",
                blurb: "A cozy home is the best reward after a long day.",
                objectives: [QuestObjective(.comfort, 25)],
                reward: QuestReward(coins: 450, xp: 140, items: ["furniture.painting": 1])
            ),
            QuestDefinition(
                id: "story.09", title: "Field Day",
                blurb: "Forty harvests. The Hollow has never looked greener.",
                objectives: [QuestObjective(.cropsHarvested, 40)],
                reward: QuestReward(coins: 600, xp: 160, items: ["supply.fertilizer": 5])
            ),
            QuestDefinition(
                id: "story.10", title: "Hollow Legend",
                blurb: "A thriving farm, a warm home, and a name the valley remembers.",
                objectives: [QuestObjective(.coinsEarned, 5000), QuestObjective(.level, 8)],
                reward: QuestReward(coins: 1500, xp: 300, items: ["furniture.trophy": 1])
            )
        ]

        self.crops = crops
        self.animals = animals
        self.furniture = furniture
        self.themes = themes
        self.supplies = supplies
        self.quests = quests
        self.items = items
        self.fish = fish
        self.recipes = recipes
        self.achievements = ActivityCatalog.achievements
        self.dailyGifts = ActivityCatalog.dailyGifts
    }

    // MARK: Lookups

    public func item(_ id: String) -> ItemDefinition? { items[id] }

    public func crop(_ id: String) -> CropDefinition? {
        crops.first { $0.id == id }
    }

    public func animal(_ id: String) -> AnimalSpecies? {
        animals.first { $0.id == id }
    }

    public func furniture(_ id: String) -> FurnitureDefinition? {
        furniture.first { $0.id == id }
    }

    public func theme(_ id: String) -> HouseTheme? {
        themes.first { $0.id == id }
    }

    public func quest(_ id: String) -> QuestDefinition? {
        quests.first { $0.id == id }
    }

    public func fishDefinition(_ id: String) -> FishDefinition? {
        fish.first { $0.id == id }
    }

    public func fishForItem(_ itemID: String) -> FishDefinition? {
        ActivityCatalog.fishDefinition(forItemID: itemID)
    }

    public func recipe(_ id: String) -> RecipeDefinition? {
        recipes.first { $0.id == id }
    }

    public func recipeForDish(_ itemID: String) -> RecipeDefinition? {
        recipes.first { $0.dishItemID == itemID }
    }

    public func achievement(_ id: String) -> AchievementDefinition? {
        achievements.first { $0.id == id }
    }

    public var sellableItems: [ItemDefinition] {
        items.values
            .filter { $0.kind != .seed && $0.kind != .furniture && $0.isSellable }
            .sorted { $0.name < $1.name }
    }

    public func dailyOrderItems(playerLevel: Int) -> [String] {
        var ids: [String] = []
        for crop in crops where crop.unlockLevel <= max(1, playerLevel) {
            ids.append(crop.produceItemID)
        }
        for animal in animals where animal.unlockLevel <= max(1, playerLevel) {
            ids.append(animal.productItemID)
        }
        if ids.isEmpty {
            ids = ["crop.wheat"]
        }
        return ids
    }

    public func seedItem(for cropID: String) -> ItemDefinition? {
        guard let crop = crop(cropID) else { return nil }
        return item(crop.seedItemID)
    }

    public func productItem(for speciesID: String) -> ItemDefinition? {
        guard let species = animal(speciesID) else { return nil }
        return item(species.productItemID)
    }
}
