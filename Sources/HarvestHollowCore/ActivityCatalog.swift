import Foundation

/// Content for the town expansion: pond life, kitchen recipes, long-term
/// achievements, and the little gift that waits on the doorstep each morning.
public enum ActivityCatalog {
    // MARK: - Fish

    public static let fish: [FishDefinition] = [
        FishDefinition(
            id: "minnow",
            name: "Pond Minnow",
            rarity: .common,
            sellPrice: 18,
            minWeight: 0.1,
            maxWeight: 0.4,
            difficulty: 1,
            unlockRodLevel: 1,
            timeWindow: .any,
            preferredWeather: [.sunny],
            emoji: "🐟",
            blurb: "A quick silver flicker, always first to the hook.",
            spriteKey: "fish.minnow"
        ),
        FishDefinition(
            id: "bluegill",
            name: "Bluegill",
            rarity: .common,
            sellPrice: 28,
            minWeight: 0.2,
            maxWeight: 0.8,
            difficulty: 1,
            unlockRodLevel: 1,
            timeWindow: .day,
            preferredWeather: [.sunny, .breezy],
            emoji: "🐠",
            blurb: "A cheerful little sunfish that loves warm shallows.",
            spriteKey: "fish.bluegill"
        ),
        FishDefinition(
            id: "perch",
            name: "Reed Perch",
            rarity: .common,
            sellPrice: 38,
            minWeight: 0.3,
            maxWeight: 1.2,
            difficulty: 2,
            unlockRodLevel: 1,
            timeWindow: .any,
            preferredWeather: [.breezy],
            emoji: "🐟",
            blurb: "Striped, stubborn, and a reliable supper.",
            spriteKey: "fish.perch"
        ),
        FishDefinition(
            id: "carp",
            name: "Mud Carp",
            rarity: .uncommon,
            sellPrice: 65,
            minWeight: 1.0,
            maxWeight: 3.6,
            difficulty: 2,
            unlockRodLevel: 2,
            timeWindow: .any,
            preferredWeather: [.rainy],
            emoji: "🐟",
            blurb: "Slow and heavy. The pond is full of them after rain.",
            spriteKey: "fish.carp"
        ),
        FishDefinition(
            id: "trout",
            name: "Speckled Trout",
            rarity: .uncommon,
            sellPrice: 82,
            minWeight: 0.8,
            maxWeight: 2.8,
            difficulty: 3,
            unlockRodLevel: 2,
            timeWindow: .dawn,
            preferredWeather: [.rainy, .breezy],
            emoji: "🐟",
            blurb: "A cool-water favourite with a speckled back.",
            spriteKey: "fish.trout"
        ),
        FishDefinition(
            id: "catfish",
            name: "Whiskered Catfish",
            rarity: .rare,
            sellPrice: 120,
            minWeight: 2.0,
            maxWeight: 6.5,
            difficulty: 3,
            unlockRodLevel: 2,
            timeWindow: .night,
            preferredWeather: [.rainy, .storm],
            emoji: "🐟",
            blurb: "The old pond keeper swears they can hear thunder coming.",
            spriteKey: "fish.catfish"
        ),
        FishDefinition(
            id: "bass",
            name: "Green Bass",
            rarity: .rare,
            sellPrice: 145,
            minWeight: 1.5,
            maxWeight: 5.0,
            difficulty: 3,
            unlockRodLevel: 3,
            timeWindow: .day,
            preferredWeather: [.sunny, .heatwave],
            emoji: "🐟",
            blurb: "A powerful jumper with a temper and a big mouth.",
            spriteKey: "fish.bass"
        ),
        FishDefinition(
            id: "koi",
            name: "Temple Koi",
            rarity: .rare,
            sellPrice: 190,
            minWeight: 1.0,
            maxWeight: 4.0,
            difficulty: 3,
            unlockRodLevel: 3,
            timeWindow: .dawn,
            preferredWeather: [.sunny],
            emoji: "🎏",
            blurb: "A lucky splash of orange beneath the lily pads.",
            spriteKey: "fish.koi"
        ),
        FishDefinition(
            id: "eel",
            name: "Storm Eel",
            rarity: .epic,
            sellPrice: 280,
            minWeight: 2.0,
            maxWeight: 5.5,
            difficulty: 4,
            unlockRodLevel: 4,
            timeWindow: .night,
            preferredWeather: [.storm],
            emoji: "🐍",
            blurb: "It appears only when the sky turns the colour of slate.",
            spriteKey: "fish.eel"
        ),
        FishDefinition(
            id: "rainbowTrout",
            name: "Rainbow Trout",
            rarity: .epic,
            sellPrice: 340,
            minWeight: 1.2,
            maxWeight: 4.2,
            difficulty: 4,
            unlockRodLevel: 4,
            timeWindow: .dusk,
            preferredWeather: [.rainy],
            emoji: "🌈",
            blurb: "A rare, shimmering trout that follows the rainbows.",
            spriteKey: "fish.rainbowTrout"
        ),
        FishDefinition(
            id: "moonfish",
            name: "Moonfish",
            rarity: .epic,
            sellPrice: 380,
            minWeight: 0.5,
            maxWeight: 2.0,
            difficulty: 4,
            unlockRodLevel: 4,
            timeWindow: .night,
            preferredWeather: [.breezy],
            emoji: "🌙",
            blurb: "Pale as a paper lantern, and twice as shy.",
            spriteKey: "fish.moonfish"
        ),
        FishDefinition(
            id: "goldenCarp",
            name: "Golden Carp",
            rarity: .legendary,
            sellPrice: 620,
            minWeight: 3.0,
            maxWeight: 8.0,
            difficulty: 5,
            unlockRodLevel: 5,
            timeWindow: .day,
            preferredWeather: [.sunny, .heatwave],
            emoji: "✨",
            blurb: "The pond's oldest rumour. It glows just under the surface.",
            spriteKey: "fish.goldenCarp"
        ),
        FishDefinition(
            id: "hollowSturgeon",
            name: "Hollow Sturgeon",
            rarity: .legendary,
            sellPrice: 980,
            minWeight: 8.0,
            maxWeight: 20.0,
            difficulty: 5,
            unlockRodLevel: 5,
            timeWindow: .any,
            preferredWeather: [.storm],
            emoji: "🐋",
            blurb: "An ancient river giant. Catch one and the whole valley hears.",
            spriteKey: "fish.hollowSturgeon"
        )
    ]

    // MARK: - Recipes

    public static let recipes: [RecipeDefinition] = [
        RecipeDefinition(
            id: "omelette",
            dishItemID: "dish.omelette",
            name: "Garden Omelette",
            category: .breakfast,
            ingredients: ["product.egg": 1, "crop.tomato": 1],
            unlockLevel: 1,
            xp: 8,
            prepSeconds: 8,
            buff: RecipeBuff(kind: .growth, magnitude: 0.12, duration: 420),
            emoji: "🍳",
            blurb: "Soft eggs, sweet tomato, and a good start to the fields.",
            spriteKey: "dish.omelette"
        ),
        RecipeDefinition(
            id: "honeyToast",
            dishItemID: "dish.honeyToast",
            name: "Honey Toast",
            category: .breakfast,
            ingredients: ["crop.wheat": 1, "product.honey": 1],
            unlockLevel: 1,
            xp: 6,
            prepSeconds: 6,
            buff: RecipeBuff(kind: .market, magnitude: 0.08, duration: 420),
            emoji: "🍯",
            blurb: "Crunchy, golden, and exactly what the market crowd wants.",
            spriteKey: "dish.honeyToast"
        ),
        RecipeDefinition(
            id: "berryParfait",
            dishItemID: "dish.berryParfait",
            name: "Berry Parfait",
            category: .dessert,
            ingredients: ["crop.strawberry": 2, "product.milk": 1],
            unlockLevel: 2,
            xp: 10,
            prepSeconds: 10,
            buff: RecipeBuff(kind: .fishing, magnitude: 0.12, duration: 480),
            emoji: "🍓",
            blurb: "Layers of cream and berries. The fish seem to approve.",
            spriteKey: "dish.berryParfait"
        ),
        RecipeDefinition(
            id: "carrotCake",
            dishItemID: "dish.carrotCake",
            name: "Carrot Cake",
            category: .dessert,
            ingredients: ["crop.carrot": 2, "crop.wheat": 1, "product.egg": 1],
            unlockLevel: 2,
            xp: 10,
            prepSeconds: 12,
            buff: RecipeBuff(kind: .market, magnitude: 0.10, duration: 420),
            emoji: "🍰",
            blurb: "A market-day classic with a thick cream-cheese icing.",
            spriteKey: "dish.carrotCake"
        ),
        RecipeDefinition(
            id: "cornChowder",
            dishItemID: "dish.cornChowder",
            name: "Corn Chowder",
            category: .lunch,
            ingredients: ["crop.corn": 2, "product.milk": 1],
            unlockLevel: 3,
            xp: 12,
            prepSeconds: 14,
            buff: RecipeBuff(kind: .growth, magnitude: 0.12, duration: 480),
            emoji: "🥣",
            blurb: "Sweet corn and cream. A bowl of sunshine on a grey day.",
            spriteKey: "dish.cornChowder"
        ),
        RecipeDefinition(
            id: "pumpkinSoup",
            dishItemID: "dish.pumpkinSoup",
            name: "Pumpkin Soup",
            category: .dinner,
            ingredients: ["crop.pumpkin": 1, "product.milk": 1],
            unlockLevel: 3,
            xp: 14,
            prepSeconds: 16,
            buff: RecipeBuff(kind: .growth, magnitude: 0.18, duration: 540),
            emoji: "🎃",
            blurb: "Velvety, warming, and made for the first cold evening.",
            spriteKey: "dish.pumpkinSoup"
        ),
        RecipeDefinition(
            id: "lavenderTea",
            dishItemID: "dish.lavenderTea",
            name: "Lavender Tea",
            category: .drink,
            ingredients: ["crop.lavender": 2, "product.honey": 1],
            unlockLevel: 3,
            xp: 12,
            prepSeconds: 9,
            buff: RecipeBuff(kind: .fishing, magnitude: 0.16, duration: 540),
            emoji: "🫖",
            blurb: "A calm cup for a long afternoon at the water's edge.",
            spriteKey: "dish.lavenderTea"
        ),
        RecipeDefinition(
            id: "sunflowerSalad",
            dishItemID: "dish.sunflowerSalad",
            name: "Sunflower Salad",
            category: .lunch,
            ingredients: ["crop.sunflower": 1, "crop.tomato": 2, "crop.carrot": 1],
            unlockLevel: 3,
            xp: 14,
            prepSeconds: 12,
            buff: RecipeBuff(kind: .market, magnitude: 0.12, duration: 480),
            emoji: "🥗",
            blurb: "Seeds, petals, and a bright vinaigrette. Very marketable.",
            spriteKey: "dish.sunflowerSalad"
        ),
        RecipeDefinition(
            id: "goatCheesePlate",
            dishItemID: "dish.goatCheesePlate",
            name: "Goat Cheese Plate",
            category: .lunch,
            ingredients: ["product.goatMilk": 1, "product.honey": 1, "crop.wheat": 1],
            unlockLevel: 4,
            xp: 16,
            prepSeconds: 15,
            buff: RecipeBuff(kind: .growth, magnitude: 0.14, duration: 540),
            emoji: "🧀",
            blurb: "Tangy cheese, warm bread, and a drizzle of wild honey.",
            spriteKey: "dish.goatCheesePlate"
        ),
        RecipeDefinition(
            id: "duckCustard",
            dishItemID: "dish.duckCustard",
            name: "Duck Egg Custard",
            category: .dessert,
            ingredients: ["product.duckEgg": 1, "product.milk": 1, "product.honey": 1],
            unlockLevel: 4,
            xp: 16,
            prepSeconds: 15,
            buff: RecipeBuff(kind: .market, magnitude: 0.14, duration: 540),
            emoji: "🍮",
            blurb: "Silky, rich, and the first thing to sell out at the bakery.",
            spriteKey: "dish.duckCustard"
        ),
        RecipeDefinition(
            id: "trufflePasta",
            dishItemID: "dish.trufflePasta",
            name: "Truffle Pasta",
            category: .dinner,
            ingredients: ["product.truffle": 1, "crop.wheat": 2, "product.egg": 1],
            unlockLevel: 4,
            xp: 18,
            prepSeconds: 18,
            buff: RecipeBuff(kind: .market, magnitude: 0.20, duration: 600),
            emoji: "🍝",
            blurb: "Earthy, buttery, and worth every single coin.",
            spriteKey: "dish.trufflePasta"
        ),
        RecipeDefinition(
            id: "moonberryTart",
            dishItemID: "dish.moonberryTart",
            name: "Moonberry Tart",
            category: .dessert,
            ingredients: ["crop.moonberry": 2, "crop.wheat": 1, "product.egg": 1],
            unlockLevel: 5,
            xp: 22,
            prepSeconds: 20,
            buff: RecipeBuff(kind: .market, magnitude: 0.18, duration: 600),
            emoji: "🥧",
            blurb: "The berries glow faintly through the lattice. Quite the sight.",
            spriteKey: "dish.moonberryTart"
        ),
        RecipeDefinition(
            id: "moonlitCocoa",
            dishItemID: "dish.moonlitCocoa",
            name: "Moonlit Cocoa",
            category: .drink,
            ingredients: ["crop.moonberry": 1, "product.milk": 1, "product.honey": 1],
            unlockLevel: 5,
            xp: 20,
            prepSeconds: 10,
            buff: RecipeBuff(kind: .fishing, magnitude: 0.20, duration: 600),
            emoji: "☕",
            blurb: "A silvery nightcap for the patient angler.",
            spriteKey: "dish.moonlitCocoa"
        ),
        RecipeDefinition(
            id: "harvestStew",
            dishItemID: "dish.harvestStew",
            name: "Harvest Stew",
            category: .dinner,
            ingredients: [
                "crop.pumpkin": 1,
                "crop.carrot": 2,
                "crop.corn": 1,
                "product.truffle": 1
            ],
            unlockLevel: 5,
            xp: 26,
            prepSeconds: 24,
            buff: RecipeBuff(kind: .growth, magnitude: 0.24, duration: 720),
            emoji: "🍲",
            blurb: "A deep autumn stew that keeps the whole farm going.",
            spriteKey: "dish.harvestStew"
        ),
        RecipeDefinition(
            id: "goldenPancakes",
            dishItemID: "dish.goldenPancakes",
            name: "Golden Pancakes",
            category: .breakfast,
            ingredients: [
                "crop.wheat": 2,
                "product.egg": 2,
                "product.milk": 1,
                "product.honey": 1
            ],
            unlockLevel: 6,
            xp: 26,
            prepSeconds: 18,
            buff: RecipeBuff(kind: .market, magnitude: 0.24, duration: 720),
            emoji: "🥞",
            blurb: "A tall stack with honey running down the sides.",
            spriteKey: "dish.goldenPancakes"
        ),
        RecipeDefinition(
            id: "anglersPie",
            dishItemID: "dish.anglersPie",
            name: "Angler's Pie",
            category: .dinner,
            ingredients: [
                "fish.trout": 1,
                "crop.wheat": 1,
                "product.egg": 1,
                "product.milk": 1
            ],
            unlockLevel: 4,
            xp: 18,
            prepSeconds: 20,
            buff: RecipeBuff(kind: .fishing, magnitude: 0.18, duration: 600),
            emoji: "🥧",
            blurb: "A fisherman's favourite, with a flaky golden crust.",
            spriteKey: "dish.anglersPie"
        ),
        RecipeDefinition(
            id: "sturgeonFeast",
            dishItemID: "dish.sturgeonFeast",
            name: "Sturgeon Feast",
            category: .dinner,
            ingredients: [
                "fish.hollowSturgeon": 1,
                "product.truffle": 1,
                "crop.moonberry": 2,
                "crop.wheat": 2
            ],
            unlockLevel: 8,
            xp: 60,
            prepSeconds: 30,
            buff: RecipeBuff(kind: .feast, magnitude: 0.20, duration: 900),
            emoji: "🐋",
            blurb: "A legendary fish deserves a legendary table.",
            spriteKey: "dish.sturgeonFeast"
        ),
        RecipeDefinition(
            id: "hollowFeast",
            dishItemID: "dish.hollowFeast",
            name: "The Hollow Feast",
            category: .dinner,
            ingredients: [
                "crop.moonberry": 2,
                "product.truffle": 2,
                "crop.sunflower": 1,
                "crop.corn": 2,
                "product.egg": 2,
                "product.milk": 2
            ],
            unlockLevel: 7,
            xp: 50,
            prepSeconds: 28,
            buff: RecipeBuff(kind: .feast, magnitude: 0.25, duration: 900),
            emoji: "🍽️",
            blurb: "Every good thing the valley grows, all on one table.",
            spriteKey: "dish.hollowFeast"
        )
    ]

    // MARK: - Achievements

    public static let achievements: [AchievementDefinition] = [
        AchievementDefinition(
            id: "field.firstSprout",
            title: "First Sprout",
            blurb: "Plant your very first seed in the old Hollow soil.",
            category: .farming,
            metric: .cropsPlanted,
            target: 1,
            rewardCoins: 30,
            rewardXP: 10,
            icon: "leaf.fill"
        ),
        AchievementDefinition(
            id: "field.greenThumb",
            title: "Green Thumb",
            blurb: "Harvest ten crops from your own field.",
            category: .farming,
            metric: .cropsHarvested,
            target: 10,
            rewardCoins: 80,
            rewardXP: 25,
            icon: "camera.macro"
        ),
        AchievementDefinition(
            id: "field.basketFull",
            title: "Basket Full",
            blurb: "Bring in fifty harvests. The stall is never empty now.",
            category: .farming,
            metric: .cropsHarvested,
            target: 50,
            rewardCoins: 220,
            rewardXP: 60,
            rewardItems: ["supply.fertilizer": 2],
            icon: "basket.fill"
        ),
        AchievementDefinition(
            id: "field.harvestLegend",
            title: "Harvest Legend",
            blurb: "Two hundred harvests. The fields know your footsteps.",
            category: .farming,
            metric: .cropsHarvested,
            target: 200,
            rewardCoins: 800,
            rewardXP: 200,
            rewardItems: ["furniture.trophy": 1],
            icon: "trophy.fill"
        ),
        AchievementDefinition(
            id: "field.variety",
            title: "A Full Seed Box",
            blurb: "Harvest every one of the nine crop varieties.",
            category: .farming,
            metric: .uniqueCropsHarvested,
            target: 9,
            rewardCoins: 300,
            rewardXP: 80,
            icon: "square.grid.3x3.fill"
        ),
        AchievementDefinition(
            id: "field.moonberry",
            title: "Moonlit Harvest",
            blurb: "Harvest ten moonberries under the Hollow sky.",
            category: .farming,
            metric: .cropHarvestedByID,
            target: 10,
            targetID: "moonberry",
            rewardCoins: 250,
            rewardXP: 70,
            icon: "moon.stars.fill"
        ),
        AchievementDefinition(
            id: "barn.helloFriend",
            title: "Hello, Friend",
            blurb: "Welcome your first animal to the barn.",
            category: .barn,
            metric: .animalsAdopted,
            target: 1,
            rewardCoins: 50,
            rewardXP: 15,
            icon: "pawprint.fill"
        ),
        AchievementDefinition(
            id: "barn.fullHouse",
            title: "A Very Full Barn",
            blurb: "Adopt a resident for all eight pens.",
            category: .barn,
            metric: .animalsAdopted,
            target: 8,
            rewardCoins: 500,
            rewardXP: 120,
            rewardItems: ["supply.feed": 5],
            icon: "house.fill"
        ),
        AchievementDefinition(
            id: "barn.eggBasket",
            title: "Egg Basket",
            blurb: "Collect twenty-five barn goods.",
            category: .barn,
            metric: .animalProducts,
            target: 25,
            rewardCoins: 150,
            rewardXP: 40,
            icon: "shippingbox.fill"
        ),
        AchievementDefinition(
            id: "barn.bestFriends",
            title: "Best Friends",
            blurb: "Pet your animals fifty times. They remember every one.",
            category: .barn,
            metric: .animalsPetted,
            target: 50,
            rewardCoins: 250,
            rewardXP: 60,
            icon: "heart.fill"
        ),
        AchievementDefinition(
            id: "market.firstSale",
            title: "First Sale",
            blurb: "Sell your first item at the Saturday market.",
            category: .market,
            metric: .itemsSold,
            target: 1,
            rewardCoins: 25,
            rewardXP: 8,
            icon: "tag.fill"
        ),
        AchievementDefinition(
            id: "market.regular",
            title: "Market Regular",
            blurb: "Sell fifty goods to the folks of Hollowmere.",
            category: .market,
            metric: .itemsSold,
            target: 50,
            rewardCoins: 150,
            rewardXP: 40,
            icon: "cart.fill"
        ),
        AchievementDefinition(
            id: "market.dailyDelivery",
            title: "Daily Delivery",
            blurb: "Complete five daily market orders.",
            category: .market,
            metric: .dailyOrdersCompleted,
            target: 5,
            rewardCoins: 300,
            rewardXP: 80,
            icon: "shippingbox.and.arrow.backward.fill"
        ),
        AchievementDefinition(
            id: "market.tycoon",
            title: "Hollow Tycoon",
            blurb: "Earn ten thousand coins from the farm.",
            category: .market,
            metric: .coinsEarned,
            target: 10_000,
            rewardCoins: 600,
            rewardXP: 150,
            icon: "banknote.fill"
        ),
        AchievementDefinition(
            id: "market.gourmet",
            title: "Gourmet",
            blurb: "Cook ten meals in the cottage kitchen.",
            category: .market,
            metric: .dishesCooked,
            target: 10,
            rewardCoins: 200,
            rewardXP: 60,
            icon: "fork.knife"
        ),
        AchievementDefinition(
            id: "market.chefTable",
            title: "The Chef's Table",
            blurb: "Discover every recipe in the kitchen book.",
            category: .market,
            metric: .uniqueRecipesCooked,
            target: 18,
            rewardCoins: 800,
            rewardXP: 200,
            rewardItems: ["furniture.piano": 1],
            icon: "book.pages.fill"
        ),
        AchievementDefinition(
            id: "pond.firstCast",
            title: "First Cast",
            blurb: "Catch your first fish from the Hollow pond.",
            category: .fishing,
            metric: .fishCaught,
            target: 1,
            rewardCoins: 40,
            rewardXP: 10,
            rewardItems: ["supply.bait": 3],
            icon: "fish.fill"
        ),
        AchievementDefinition(
            id: "pond.reelPro",
            title: "Reel Pro",
            blurb: "Land twenty-five fish from the pond.",
            category: .fishing,
            metric: .fishCaught,
            target: 25,
            rewardCoins: 220,
            rewardXP: 60,
            icon: "figure.fishing"
        ),
        AchievementDefinition(
            id: "pond.collector",
            title: "Pond Collector",
            blurb: "Catch every one of the thirteen fish species.",
            category: .fishing,
            metric: .uniqueFishCaught,
            target: 13,
            rewardCoins: 400,
            rewardXP: 100,
            icon: "water.waves"
        ),
        AchievementDefinition(
            id: "pond.legend",
            title: "Legend of the Pond",
            blurb: "Land a legendary fish. The whole valley will hear about it.",
            category: .fishing,
            metric: .legendaryFishCaught,
            target: 1,
            rewardCoins: 500,
            rewardXP: 120,
            icon: "sparkles"
        ),
        AchievementDefinition(
            id: "pond.rodMaster",
            title: "Rod Master",
            blurb: "Upgrade your fishing rod to its final form.",
            category: .fishing,
            metric: .rodLevel,
            target: FishingBalance.maxRodLevel,
            rewardCoins: 700,
            rewardXP: 180,
            icon: "wrench.and.screwdriver.fill"
        ),
        AchievementDefinition(
            id: "home.homemaker",
            title: "Homemaker",
            blurb: "Raise the cottage comfort to twenty-five.",
            category: .home,
            metric: .comfort,
            target: 25,
            rewardCoins: 200,
            rewardXP: 50,
            icon: "sofa.fill"
        ),
        AchievementDefinition(
            id: "home.interiorDecorator",
            title: "Interior Decorator",
            blurb: "Place fifty pieces of furniture over the years.",
            category: .home,
            metric: .decorationsPlaced,
            target: 50,
            rewardCoins: 300,
            rewardXP: 70,
            icon: "paintpalette.fill"
        ),
        AchievementDefinition(
            id: "home.themeCollector",
            title: "Theme Collector",
            blurb: "Own all five cottage themes.",
            category: .home,
            metric: .themesOwned,
            target: 5,
            rewardCoins: 500,
            rewardXP: 120,
            icon: "house.lodge.fill"
        ),
        AchievementDefinition(
            id: "story.chapterOne",
            title: "Chapter One",
            blurb: "Finish the first chapter of the Hollow story.",
            category: .story,
            metric: .questsCompleted,
            target: 1,
            rewardCoins: 80,
            rewardXP: 20,
            icon: "book.closed.fill"
        ),
        AchievementDefinition(
            id: "story.hollowLegend",
            title: "Hollow Legend",
            blurb: "Complete all ten chapters of the story.",
            category: .story,
            metric: .questsCompleted,
            target: 10,
            rewardCoins: 1_200,
            rewardXP: 300,
            rewardItems: ["furniture.trophy": 1],
            icon: "crown.fill"
        ),
        AchievementDefinition(
            id: "story.levelTen",
            title: "A Name in the Valley",
            blurb: "Reach farmer level ten.",
            category: .story,
            metric: .level,
            target: 10,
            rewardCoins: 400,
            rewardXP: 100,
            icon: "arrow.up.circle.fill"
        ),
        AchievementDefinition(
            id: "story.weekOne",
            title: "Seven Good Mornings",
            blurb: "Spend seven days in the Hollow.",
            category: .story,
            metric: .daysPlayed,
            target: 7,
            rewardCoins: 100,
            rewardXP: 25,
            icon: "calendar"
        ),
        AchievementDefinition(
            id: "story.century",
            title: "A Hundred Seasons",
            blurb: "Spend one hundred days on the farm.",
            category: .story,
            metric: .daysPlayed,
            target: 100,
            rewardCoins: 1_000,
            rewardXP: 250,
            icon: "hourglass"
        ),
        AchievementDefinition(
            id: "story.thankYou",
            title: "A Little Thank You",
            blurb: "Claim thirty daily gifts from the doorstep.",
            category: .story,
            metric: .giftsClaimed,
            target: 30,
            rewardCoins: 500,
            rewardXP: 120,
            icon: "gift.fill"
        )
    ]

    // MARK: - Daily gifts

    public static let dailyGifts: [DailyGiftDefinition] = [
        DailyGiftDefinition(
            day: 1,
            title: "A Paper Parcel",
            blurb: "A little something from the neighbours at Rosewood Cottage.",
            coins: 40,
            xp: 10,
            items: ["seed.carrot": 2],
            emoji: "🌱",
            isMilestone: false
        ),
        DailyGiftDefinition(
            day: 2,
            title: "The Bait Tin",
            blurb: "Old Finn left a tin of pond bait by the gate.",
            coins: 60,
            xp: 12,
            items: ["supply.bait": 3],
            emoji: "🪱",
            isMilestone: false
        ),
        DailyGiftDefinition(
            day: 3,
            title: "Market Leftovers",
            blurb: "A crate of tomato seedlings that needed a good home.",
            coins: 80,
            xp: 15,
            items: ["seed.tomato": 2],
            emoji: "🍅",
            isMilestone: false
        ),
        DailyGiftDefinition(
            day: 4,
            title: "A Bag of Feed",
            blurb: "The barn committee sends their thanks and a sturdy feed sack.",
            coins: 120,
            xp: 18,
            items: ["supply.feed": 3],
            emoji: "🌿",
            isMilestone: false
        ),
        DailyGiftDefinition(
            day: 5,
            title: "Garden Supplies",
            blurb: "A sack of fertilizer with a hand-drawn label.",
            coins: 150,
            xp: 22,
            items: ["supply.fertilizer": 2],
            emoji: "🧪",
            isMilestone: false
        ),
        DailyGiftDefinition(
            day: 6,
            title: "Strawberry Starts",
            blurb: "A tray of strawberry runners from the village school.",
            coins: 200,
            xp: 28,
            items: ["seed.strawberry": 2],
            emoji: "🍓",
            isMilestone: false
        ),
        DailyGiftDefinition(
            day: 7,
            title: "The Week's Thank You",
            blurb: "Seven mornings in a row. The Hollow has noticed.",
            coins: 350,
            xp: 50,
            items: ["furniture.lamp": 1, "supply.bait": 5],
            emoji: "🎁",
            isMilestone: true
        )
    ]

    // MARK: - Lookups

    public static func fishDefinition(_ id: String) -> FishDefinition? {
        fish.first { $0.id == id }
    }

    public static func recipe(_ id: String) -> RecipeDefinition? {
        recipes.first { $0.id == id }
    }

    public static func achievement(_ id: String) -> AchievementDefinition? {
        achievements.first { $0.id == id }
    }

    public static func gift(dayInCycle: Int) -> DailyGiftDefinition {
        let index = max(0, dayInCycle - 1) % dailyGifts.count
        return dailyGifts[index]
    }

    public static func fishItemID(forFish fishID: String) -> String {
        "fish.\(fishID)"
    }

    public static func fishDefinition(forItemID itemID: String) -> FishDefinition? {
        guard itemID.hasPrefix("fish.") else { return nil }
        return fishDefinition(String(itemID.dropFirst("fish.".count)))
    }

    public static func dishPrice(for recipe: RecipeDefinition) -> Int {
        // Keep this independent of the catalog singleton: this function is
        // called while the catalog itself is being built.
        max(24, recipe.xp * 7 + recipe.ingredientCount * 14)
    }

    public static func achievementProgress(
        definition: AchievementDefinition,
        state: GameState,
        comfort: Int
    ) -> Int {
        let stats = state.stats
        let activities = state.activities
        switch definition.metric {
        case .cropsPlanted:
            return stats.cropsPlanted
        case .cropsHarvested:
            return stats.cropsHarvested
        case .uniqueCropsHarvested:
            return stats.harvestedByCrop.values.filter { $0 > 0 }.count
        case .cropHarvestedByID:
            return stats.harvestedByCrop[definition.targetID ?? ""] ?? 0
        case .animalsAdopted:
            return stats.animalsBought
        case .animalProducts:
            return stats.animalProducts
        case .animalsPetted:
            return activities.animalsPetted
        case .itemsSold:
            return stats.itemsSold
        case .itemSoldByID:
            return stats.soldByItem[definition.targetID ?? ""] ?? 0
        case .coinsEarned:
            return stats.coinsEarned
        case .dailyOrdersCompleted:
            return activities.dailyOrdersCompleted
        case .level:
            return state.level
        case .questsCompleted:
            return stats.questsCompleted
        case .decorationsPlaced:
            return stats.decorationsPlaced
        case .comfort:
            return comfort
        case .themesOwned:
            return state.themesOwned.count
        case .fishCaught:
            return activities.fishing.totalCatches
        case .uniqueFishCaught:
            return activities.fishing.uniqueCatches
        case .fishCaughtByID:
            return activities.fishing.catches[definition.targetID ?? ""] ?? 0
        case .legendaryFishCaught:
            return activities.fishing.catches.keys.reduce(0) { total, fishID in
                guard let fish = fishDefinition(fishID), fish.rarity == .legendary else { return total }
                return total + (activities.fishing.catches[fishID] ?? 0)
            }
        case .rodLevel:
            return activities.fishing.rodLevel
        case .dishesCooked:
            return activities.dishesCooked
        case .uniqueRecipesCooked:
            return activities.uniqueRecipesCooked
        case .dishesEaten:
            return activities.dishesEaten
        case .giftsClaimed:
            return activities.giftsClaimed
        case .daysPlayed:
            return state.flags.totalDaysPlayed
        }
    }
}
