import Foundation

// MARK: - Arcade progress

/// Long-lived progress for Meadow Dash, stored beside the farm save so a run
/// survives relaunches and old saves gain the new tab without a migration step.
public struct ArcadeState: Codable, Sendable, Equatable {
    public var bestScore: Int
    public var totalRuns: Int
    public var totalApples: Int
    public var totalDistance: Int
    public var unlockedLevel: Int
    public var starsByLevel: [Int: Int]
    public var perfectRuns: Int
    public var lastPlayedDay: Int
    public var dailyRuns: Int
    public var dailyBest: Int
    public var discoveredPowers: [String]
    public var hasSeenArcadeHelp: Bool

    public init(
        bestScore: Int = 0,
        totalRuns: Int = 0,
        totalApples: Int = 0,
        totalDistance: Int = 0,
        unlockedLevel: Int = 1,
        starsByLevel: [Int: Int] = [:],
        perfectRuns: Int = 0,
        lastPlayedDay: Int = 0,
        dailyRuns: Int = 0,
        dailyBest: Int = 0,
        discoveredPowers: [String] = [],
        hasSeenArcadeHelp: Bool = false
    ) {
        self.bestScore = bestScore
        self.totalRuns = totalRuns
        self.totalApples = totalApples
        self.totalDistance = totalDistance
        self.unlockedLevel = unlockedLevel
        self.starsByLevel = starsByLevel
        self.perfectRuns = perfectRuns
        self.lastPlayedDay = lastPlayedDay
        self.dailyRuns = dailyRuns
        self.dailyBest = dailyBest
        self.discoveredPowers = discoveredPowers
        self.hasSeenArcadeHelp = hasSeenArcadeHelp
    }

    private enum CodingKeys: String, CodingKey {
        case bestScore
        case totalRuns
        case totalApples
        case totalDistance
        case unlockedLevel
        case starsByLevel
        case perfectRuns
        case lastPlayedDay
        case dailyRuns
        case dailyBest
        case discoveredPowers
        case hasSeenArcadeHelp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bestScore = try container.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        totalRuns = try container.decodeIfPresent(Int.self, forKey: .totalRuns) ?? 0
        totalApples = try container.decodeIfPresent(Int.self, forKey: .totalApples) ?? 0
        totalDistance = try container.decodeIfPresent(Int.self, forKey: .totalDistance) ?? 0
        unlockedLevel = try container.decodeIfPresent(Int.self, forKey: .unlockedLevel) ?? 1
        starsByLevel = try container.decodeIfPresent([Int: Int].self, forKey: .starsByLevel) ?? [:]
        perfectRuns = try container.decodeIfPresent(Int.self, forKey: .perfectRuns) ?? 0
        lastPlayedDay = try container.decodeIfPresent(Int.self, forKey: .lastPlayedDay) ?? 0
        dailyRuns = try container.decodeIfPresent(Int.self, forKey: .dailyRuns) ?? 0
        dailyBest = try container.decodeIfPresent(Int.self, forKey: .dailyBest) ?? 0
        discoveredPowers = try container.decodeIfPresent([String].self, forKey: .discoveredPowers) ?? []
        hasSeenArcadeHelp = try container.decodeIfPresent(Bool.self, forKey: .hasSeenArcadeHelp) ?? false
    }

    public func totalStars() -> Int {
        starsByLevel.values.reduce(0, +)
    }

    public func stars(for level: Int) -> Int {
        starsByLevel[level, default: 0]
    }

    public func isUnlocked(_ level: Int) -> Bool {
        level <= max(1, unlockedLevel)
    }

    public mutating func register(_ result: MeadowRunResult, day: Int) {
        totalRuns += 1
        totalApples += result.apples
        totalDistance += Int(result.distance)
        if result.score > bestScore {
            bestScore = result.score
        }
        if day != lastPlayedDay {
            lastPlayedDay = day
            dailyRuns = 0
            dailyBest = 0
        }
        dailyRuns += 1
        dailyBest = max(dailyBest, result.score)
        if result.stars > stars(for: result.levelIndex) {
            starsByLevel[result.levelIndex] = result.stars
        }
        if result.success, result.hearts == result.maxHearts, result.apples >= result.goalApples {
            perfectRuns += 1
        }
        let previousUnlock = unlockedLevel
        unlockedLevel = max(unlockedLevel, min(MeadowLevelCatalog.levelCount, result.levelIndex + 1))
        if unlockedLevel > previousUnlock {
            discoveredPowers.append("unlock.\(unlockedLevel)")
        }
        for power in result.powers where !discoveredPowers.contains(power) {
            discoveredPowers.append(power)
        }
        if !hasSeenArcadeHelp {
            hasSeenArcadeHelp = true
        }
    }
}

// MARK: - Meadow level content

public enum MeadowBiome: String, Codable, CaseIterable, Sendable, Identifiable {
    case meadow
    case orchard
    case creek
    case golden
    case moonlit
    case storm

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .meadow: return "Clover Meadow"
        case .orchard: return "Apple Orchard"
        case .creek: return "Willow Creek"
        case .golden: return "Golden Fields"
        case .moonlit: return "Moonlit Hollow"
        case .storm: return "Stormy Ridge"
        }
    }

    public var icon: String {
        switch self {
        case .meadow: return "leaf.fill"
        case .orchard: return "apple.logo"
        case .creek: return "drop.fill"
        case .golden: return "sun.max.fill"
        case .moonlit: return "moon.stars.fill"
        case .storm: return "cloud.bolt.rain.fill"
        }
    }

    public var skyTopHex: String {
        switch self {
        case .meadow: return "BFE3EE"
        case .orchard: return "F7D9A2"
        case .creek: return "A9D9EE"
        case .golden: return "F0B47D"
        case .moonlit: return "24334E"
        case .storm: return "6C7D8D"
        }
    }

    public var skyBottomHex: String {
        switch self {
        case .meadow: return "F4E5C5"
        case .orchard: return "F3C07C"
        case .creek: return "D8EDF5"
        case .golden: return "F7E1B0"
        case .moonlit: return "40516B"
        case .storm: return "AEB7B5"
        }
    }

    public var grassHex: String {
        switch self {
        case .meadow: return "6FA84F"
        case .orchard: return "7CA64E"
        case .creek: return "65A469"
        case .golden: return "B8A54F"
        case .moonlit: return "3E6652"
        case .storm: return "5A7D4F"
        }
    }

    public var soilHex: String {
        switch self {
        case .meadow: return "8A5A3A"
        case .orchard: return "9B6B47"
        case .creek: return "6B5A48"
        case .golden: return "A46B49"
        case .moonlit: return "4B3A32"
        case .storm: return "5C4A3D"
        }
    }

    public var blurb: String {
        switch self {
        case .meadow: return "A soft green run through the clover."
        case .orchard: return "Dodge fallen apples and leap over crates."
        case .creek: return "Mind the puddles and the reeds."
        case .golden: return "A golden-hour dash through ripe wheat."
        case .moonlit: return "The fireflies are out. So are the crows."
        case .storm: return "A blustery sprint with slippery ground."
        }
    }
}

public enum MeadowObstacleKind: String, Codable, CaseIterable, Sendable {
    case fence
    case rock
    case stump
    case hayBale
    case puddle
    case crow
    case bee
    case thistle
    case crate
    case pumpkin

    public var title: String {
        switch self {
        case .fence: return "Fence"
        case .rock: return "Rock"
        case .stump: return "Stump"
        case .hayBale: return "Hay bale"
        case .puddle: return "Puddle"
        case .crow: return "Crow"
        case .bee: return "Bee"
        case .thistle: return "Thistle"
        case .crate: return "Crate"
        case .pumpkin: return "Pumpkin"
        }
    }

    public var icon: String {
        switch self {
        case .fence: return "rectangle.split.3x1.fill"
        case .rock: return "circle.hexagongrid.fill"
        case .stump: return "tree.fill"
        case .hayBale: return "square.stack.3d.up.fill"
        case .puddle: return "drop.fill"
        case .crow: return "bird.fill"
        case .bee: return "ant.fill"
        case .thistle: return "leaf.fill"
        case .crate: return "shippingbox.fill"
        case .pumpkin: return "circle.fill"
        }
    }

    public var width: Double {
        switch self {
        case .fence: return 34
        case .rock: return 30
        case .stump: return 26
        case .hayBale: return 38
        case .puddle: return 48
        case .crow: return 28
        case .bee: return 18
        case .thistle: return 24
        case .crate: return 28
        case .pumpkin: return 26
        }
    }

    public var height: Double {
        switch self {
        case .fence: return 34
        case .rock: return 26
        case .stump: return 24
        case .hayBale: return 28
        case .puddle: return 10
        case .crow: return 30
        case .bee: return 18
        case .thistle: return 28
        case .crate: return 26
        case .pumpkin: return 22
        }
    }

    public var damage: Int {
        switch self {
        case .puddle, .bee, .thistle: return 1
        case .crow: return 2
        default: return 1
        }
    }

    public var isBreakable: Bool {
        switch self {
        case .fence, .crate, .hayBale, .pumpkin, .thistle: return true
        default: return false
        }
    }

    public var colorHex: String {
        switch self {
        case .fence: return "D8C6A4"
        case .rock: return "8F8C82"
        case .stump: return "74482E"
        case .hayBale: return "D8B65C"
        case .puddle: return "6D9BC2"
        case .crow: return "3B3A46"
        case .bee: return "E7B93F"
        case .thistle: return "8E6BC4"
        case .crate: return "A46B49"
        case .pumpkin: return "E08A32"
        }
    }
}

public enum MeadowPickupKind: String, Codable, CaseIterable, Sendable {
    case apple
    case goldenApple
    case clover
    case carrot
    case heart
    case star

    public var title: String {
        switch self {
        case .apple: return "Apple"
        case .goldenApple: return "Golden apple"
        case .clover: return "Lucky clover"
        case .carrot: return "Dash carrot"
        case .heart: return "Heart"
        case .star: return "Star"
        }
    }

    public var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .goldenApple: return "sparkles"
        case .clover: return "leaf.fill"
        case .carrot: return "carrot.fill"
        case .heart: return "heart.fill"
        case .star: return "star.fill"
        }
    }

    public var value: Int {
        switch self {
        case .apple: return 1
        case .goldenApple: return 5
        case .clover, .carrot, .heart, .star: return 0
        }
    }

    public var score: Int {
        switch self {
        case .apple: return 12
        case .goldenApple: return 80
        case .clover: return 20
        case .carrot: return 20
        case .heart: return 30
        case .star: return 55
        }
    }

    public var colorHex: String {
        switch self {
        case .apple: return "C94F45"
        case .goldenApple: return "F0C95C"
        case .clover: return "4F8A5A"
        case .carrot: return "E08A32"
        case .heart: return "D95D4F"
        case .star: return "F0C95C"
        }
    }
}

public struct MeadowSpawn: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: MeadowSpawnKind
    public let x: Double
    public let y: Double
    public let scale: Double

    public init(id: String, kind: MeadowSpawnKind, x: Double, y: Double, scale: Double = 1) {
        self.id = id
        self.kind = kind
        self.x = x
        self.y = y
        self.scale = scale
    }
}

public enum MeadowSpawnKind: Hashable, Sendable {
    case obstacle(MeadowObstacleKind)
    case pickup(MeadowPickupKind)

    public var isObstacle: Bool {
        if case .obstacle = self { return true }
        return false
    }

    public var obstacle: MeadowObstacleKind? {
        if case let .obstacle(kind) = self { return kind }
        return nil
    }

    public var pickup: MeadowPickupKind? {
        if case let .pickup(kind) = self { return kind }
        return nil
    }
}

public struct MeadowLevelDefinition: Identifiable, Equatable, Sendable {
    public let id: String
    public let index: Int
    public let name: String
    public let subtitle: String
    public let biome: MeadowBiome
    public let length: Double
    public let baseSpeed: Double
    public let gravity: Double
    public let goalApples: Int
    public let timeLimit: Double
    public let difficulty: Int
    public let spawns: [MeadowSpawn]

    public init(
        id: String,
        index: Int,
        name: String,
        subtitle: String,
        biome: MeadowBiome,
        length: Double,
        baseSpeed: Double,
        gravity: Double,
        goalApples: Int,
        timeLimit: Double,
        difficulty: Int,
        spawns: [MeadowSpawn]
    ) {
        self.id = id
        self.index = index
        self.name = name
        self.subtitle = subtitle
        self.biome = biome
        self.length = length
        self.baseSpeed = baseSpeed
        self.gravity = gravity
        self.goalApples = goalApples
        self.timeLimit = timeLimit
        self.difficulty = difficulty
        self.spawns = spawns
    }

    public var starsHint: String {
        "\(goalApples) apples · \(Int(timeLimit))s"
    }
}

public enum MeadowLevelCatalog {
    public static let levelCount = 16

    public static let levels: [MeadowLevelDefinition] = (1...levelCount).map(makeLevel)

    public static func level(_ index: Int) -> MeadowLevelDefinition? {
        guard index >= 1, index <= levels.count else { return nil }
        return levels[index - 1]
    }

    private static func makeLevel(_ index: Int) -> MeadowLevelDefinition {
        var rng = MeadowRNG(state: UInt64(index) &* 0x9E3779B97F4A7C15)
        let biome: MeadowBiome
        switch index {
        case 1...3: biome = .meadow
        case 4...6: biome = .orchard
        case 7...9: biome = .creek
        case 10...12: biome = .golden
        case 13...14: biome = .moonlit
        default: biome = .storm
        }
        let names = [
            "Clover Sprint", "Apple Alley", "Hay Day", "Orchard Rush",
            "Crate Expectations", "Pumpkin Parade", "Creek Leap", "Reed Runner",
            "Willow Whirl", "Golden Gallop", "Wheat Dash", "Harvest Hustle",
            "Firefly Run", "Moonlit Mile", "Storm Chaser", "Hollow Legend"
        ]
        let subtitles = [
            "Find your feet and gather the first apples.",
            "A gentle run through rows of apple trees.",
            "Bales, fences and a very determined bee.",
            "The orchard is ripe. So are the obstacles.",
            "Crates are made for dashing through.",
            "A parade of pumpkins blocks the path.",
            "Puddles reflect the sky and hide a stumble.",
            "Reeds whisper warnings. Listen with your feet.",
            "The creek bends. So does the trail.",
            "A golden-hour run through ripe wheat.",
            "Wheat heads nod as you race the sun.",
            "The whole valley is bringing in the harvest.",
            "Fireflies light a trickier path.",
            "The Hollow after dark, full of stars.",
            "Wind, rain and a ridge to conquer.",
            "Every meadow lesson in one legendary run."
        ]
        let length = 1_350 + Double(index) * 110
        let speed = 145 + Double(index) * 7
        let gravity = 1_720 + Double(index) * 15
        let goal = 6 + index * 2
        let timeLimit = length / speed + 8
        var spawns: [MeadowSpawn] = []
        var x = 260.0
        var spawnIndex = 0
        while x < length - 120 {
            let pattern = spawnIndex % 7
            let obstacleKind: MeadowObstacleKind
            switch (index + pattern) % 10 {
            case 0: obstacleKind = .fence
            case 1: obstacleKind = .rock
            case 2: obstacleKind = .stump
            case 3: obstacleKind = .hayBale
            case 4: obstacleKind = .puddle
            case 5: obstacleKind = .crow
            case 6: obstacleKind = .bee
            case 7: obstacleKind = .thistle
            case 8: obstacleKind = .crate
            default: obstacleKind = .pumpkin
            }
            let obstacleY: Double
            switch obstacleKind {
            case .crow, .bee: obstacleY = 58 + Double(spawnIndex % 3) * 18
            default: obstacleY = 0
            }
            if rng.nextUnit() < 0.72 {
                spawns.append(
                    MeadowSpawn(
                        id: "\(index)-o-\(spawnIndex)",
                        kind: .obstacle(obstacleKind),
                        x: x,
                        y: obstacleY,
                        scale: 0.9 + rng.nextUnit() * 0.25
                    )
                )
            }
            let pickupKind: MeadowPickupKind
            switch (index + spawnIndex) % 9 {
            case 0: pickupKind = .goldenApple
            case 1, 4, 7: pickupKind = .clover
            case 2: pickupKind = .carrot
            case 3: pickupKind = .heart
            case 5: pickupKind = .star
            default: pickupKind = .apple
            }
            if rng.nextUnit() < 0.8 {
                let pickupY = rng.nextUnit() < 0.42 ? 66.0 : 18.0
                spawns.append(
                    MeadowSpawn(
                        id: "\(index)-p-\(spawnIndex)",
                        kind: .pickup(pickupKind),
                        x: x + 54,
                        y: pickupY,
                        scale: 0.85 + rng.nextUnit() * 0.2
                    )
                )
            }
            x += 115 + rng.nextUnit() * 72
            spawnIndex += 1
        }
        return MeadowLevelDefinition(
            id: "meadow.level.\(index)",
            index: index,
            name: names[index - 1],
            subtitle: subtitles[index - 1],
            biome: biome,
            length: length,
            baseSpeed: speed,
            gravity: gravity,
            goalApples: goal,
            timeLimit: timeLimit,
            difficulty: min(5, (index + 2) / 3),
            spawns: spawns
        )
    }
}

// MARK: - Deterministic random source

public struct MeadowRNG: Sendable {
    public private(set) var state: UInt64

    public init(state: UInt64 = 0x9E3779B97F4A7C15) {
        self.state = state == 0 ? 0x9E3779B97F4A7C15 : state
    }

    public mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    public mutating func nextUnit() -> Double {
        Double(next() % 10_000) / 10_000
    }

    public mutating func nextInt(_ range: ClosedRange<Int>) -> Int {
        let width = range.upperBound - range.lowerBound + 1
        return range.lowerBound + Int(next() % UInt64(max(1, width)))
    }
}

// MARK: - Live run

public enum MeadowRunPhase: String, Codable, Sendable {
    case ready
    case running
    case paused
    case finished
    case failed
}

public struct MeadowLiveSpawn: Identifiable, Hashable, Sendable {
    public let id: String
    public let spawn: MeadowSpawn
    public var collected: Bool
    public var struck: Bool

    public init(spawn: MeadowSpawn) {
        self.id = spawn.id
        self.spawn = spawn
        collected = false
        struck = false
    }

    public var isResolved: Bool { collected || struck }
}

public struct MeadowRunResult: Codable, Sendable, Equatable {
    public let levelIndex: Int
    public let score: Int
    public let apples: Int
    public let stars: Int
    public let distance: Double
    public let elapsed: Double
    public let hearts: Int
    public let maxHearts: Int
    public let goalApples: Int
    public let maxCombo: Int
    public let powers: [String]
    public let success: Bool

    public init(
        levelIndex: Int,
        score: Int,
        apples: Int,
        stars: Int,
        distance: Double,
        elapsed: Double,
        hearts: Int,
        maxHearts: Int,
        goalApples: Int,
        maxCombo: Int,
        powers: [String],
        success: Bool
    ) {
        self.levelIndex = levelIndex
        self.score = score
        self.apples = apples
        self.stars = stars
        self.distance = distance
        self.elapsed = elapsed
        self.hearts = hearts
        self.maxHearts = maxHearts
        self.goalApples = goalApples
        self.maxCombo = maxCombo
        self.powers = powers
        self.success = success
    }
}

public struct MeadowPlayerState: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var verticalVelocity: Double
    public var isGrounded: Bool
    public var jumpsUsed: Int
    public var dashTimer: Double
    public var dashCooldown: Double
    public var invulnerableTimer: Double
    public var slideTimer: Double
    public var shieldTimer: Double

    public init() {
        x = 80
        y = 0
        verticalVelocity = 0
        isGrounded = true
        jumpsUsed = 0
        dashTimer = 0
        dashCooldown = 0
        invulnerableTimer = 0
        slideTimer = 0
        shieldTimer = 0
    }

    public var isDashing: Bool { dashTimer > 0 }
    public var isSliding: Bool { slideTimer > 0 }
    public var width: Double { isSliding ? 28 : 22 }
    public var height: Double { isSliding ? 16 : 28 }

    public var rect: MeadowRect {
        MeadowRect(x: x - width * 0.5, y: y, width: width, height: height)
    }
}

public struct MeadowRect: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public func intersects(_ other: MeadowRect) -> Bool {
        x < other.x + other.width
            && other.x < x + width
            && y < other.y + other.height
            && other.y < y + height
    }
}

public struct MeadowRunState: Sendable {
    public var level: MeadowLevelDefinition
    public var phase: MeadowRunPhase
    public var player: MeadowPlayerState
    public var distance: Double
    public var score: Int
    public var apples: Int
    public var hearts: Int
    public var maxHearts: Int
    public var combo: Int
    public var maxCombo: Int
    public var comboTimer: Double
    public var elapsed: Double
    public var speed: Double
    public var spawns: [MeadowLiveSpawn]
    public var stars: Int
    public var activePowers: [String]
    public var lastEvent: String?
    public var result: MeadowRunResult?

    public init(level: MeadowLevelDefinition) {
        self.level = level
        phase = .ready
        player = MeadowPlayerState()
        distance = 0
        score = 0
        apples = 0
        hearts = 3
        maxHearts = 3
        combo = 0
        maxCombo = 0
        comboTimer = 0
        elapsed = 0
        speed = level.baseSpeed
        spawns = level.spawns.map(MeadowLiveSpawn.init)
        stars = 0
        activePowers = []
        lastEvent = nil
        result = nil
    }

    public var progress: Double {
        guard level.length > 0 else { return 0 }
        return min(1, distance / level.length)
    }

    public var applesProgress: Double {
        guard level.goalApples > 0 else { return 0 }
        return min(1, Double(apples) / Double(level.goalApples))
    }

    public var isActive: Bool { phase == .running }

    public var playerRect: MeadowRect { player.rect }

    public mutating func start() {
        self = MeadowRunState(level: level)
        phase = .running
        lastEvent = "Go!"
    }

    public mutating func pause() {
        guard phase == .running else { return }
        phase = .paused
        lastEvent = "Paused"
    }

    public mutating func resume() {
        guard phase == .paused else { return }
        phase = .running
        lastEvent = nil
    }

    public mutating func jump() {
        guard phase == .running else { return }
        let limit = player.isGrounded ? 2 : 2
        guard player.jumpsUsed < limit else { return }
        let force = player.isGrounded ? 620.0 : 520.0
        player.verticalVelocity = force
        player.isGrounded = false
        player.jumpsUsed += 1
        lastEvent = player.jumpsUsed == 1 ? "Hop!" : "Double hop!"
    }

    public mutating func dash() {
        guard phase == .running, player.dashCooldown <= 0 else { return }
        player.dashTimer = 0.42
        player.dashCooldown = 2.4
        player.invulnerableTimer = max(player.invulnerableTimer, 0.42)
        activePowers.append("dash")
        lastEvent = "Carrot dash!"
    }

    public mutating func slide() {
        guard phase == .running else { return }
        if player.isDashing { return }
        player.slideTimer = 0.58
        lastEvent = "Slide!"
    }

    public mutating func update(delta: Double) {
        guard phase == .running else { return }
        let dt = max(0, min(0.08, delta))
        guard dt > 0 else { return }
        elapsed += dt
        player.dashTimer = max(0, player.dashTimer - dt)
        player.dashCooldown = max(0, player.dashCooldown - dt)
        player.invulnerableTimer = max(0, player.invulnerableTimer - dt)
        player.slideTimer = max(0, player.slideTimer - dt)
        player.shieldTimer = max(0, player.shieldTimer - dt)
        let targetSpeed = level.baseSpeed + Double(level.index) * 2.2
            + (player.isDashing ? 110 : 0)
        speed += (targetSpeed - speed) * min(1, dt * 2.2)
        distance += speed * dt
        player.x = distance
        player.verticalVelocity -= level.gravity * dt
        player.y += player.verticalVelocity * dt
        if player.y <= 0 {
            player.y = 0
            if player.verticalVelocity < -90 {
                lastEvent = "Landing"
            }
            player.verticalVelocity = 0
            player.isGrounded = true
            player.jumpsUsed = 0
        } else {
            player.isGrounded = false
        }
        if comboTimer > 0 {
            comboTimer = max(0, comboTimer - dt)
            if comboTimer == 0 {
                combo = 0
            }
        }
        updateSpawns()
        score = max(score, Int(distance * 0.22) + apples * 12 + maxCombo * 8 + hearts * 30)
        if player.y < -30 {
            hurt(amount: 99)
        }
        if elapsed >= level.timeLimit {
            finish(success: hearts > 0)
        } else if distance >= level.length {
            finish(success: true)
        }
    }

    private mutating func updateSpawns() {
        let playerRect = player.rect
        for index in spawns.indices {
            guard !spawns[index].isResolved else { continue }
            let live = spawns[index]
            let spawn = live.spawn
            let dx = abs(spawn.x - player.x)
            guard dx < 260 else { continue }
            let width = spawn.kind.obstacle?.width ?? 20
            let height = spawn.kind.obstacle?.height ?? 18
            let rect = MeadowRect(
                x: spawn.x - width * 0.5 * spawn.scale,
                y: spawn.y,
                width: width * spawn.scale,
                height: height * spawn.scale
            )
            guard playerRect.intersects(rect) else { continue }
            if let pickup = spawn.kind.pickup {
                spawns[index].collected = true
                collect(pickup)
            } else if let obstacle = spawn.kind.obstacle {
                if player.isDashing || obstacle.isBreakable && player.isDashing {
                    spawns[index].struck = true
                    score += 15
                    lastEvent = "Smashed \(obstacle.title)!"
                } else if player.shieldTimer > 0 {
                    spawns[index].struck = true
                    player.shieldTimer = 0
                    score += 10
                    lastEvent = "Clover shield saved you!"
                } else if player.invulnerableTimer <= 0 {
                    spawns[index].struck = true
                    hurt(amount: obstacle.damage)
                    if !obstacle.isBreakable {
                        player.verticalVelocity = 250
                    }
                }
            }
        }
    }

    private mutating func collect(_ pickup: MeadowPickupKind) {
        lastEvent = pickup.title
        switch pickup {
        case .apple:
            apples += 1
            combo += 1
            maxCombo = max(maxCombo, combo)
            comboTimer = 2.8
            score += pickup.score + combo * 2
        case .goldenApple:
            apples += 5
            combo += 2
            maxCombo = max(maxCombo, combo)
            comboTimer = 3.4
            score += pickup.score
        case .clover:
            player.shieldTimer = 7
            activePowers.append("clover")
            lastEvent = "Lucky clover!"
        case .carrot:
            player.dashCooldown = 0
            player.dashTimer = max(player.dashTimer, 0.3)
            activePowers.append("carrot")
            lastEvent = "Dash carrot!"
        case .heart:
            hearts = min(maxHearts, hearts + 1)
            lastEvent = "A little heart!"
        case .star:
            score += pickup.score
            activePowers.append("star")
            lastEvent = "Star apple!"
        }
    }

    private mutating func hurt(amount: Int) {
        guard player.invulnerableTimer <= 0 else { return }
        hearts = max(0, hearts - amount)
        combo = 0
        comboTimer = 0
        player.invulnerableTimer = 1.25
        player.verticalVelocity = 280
        lastEvent = amount > 1 ? "Ouch! Big tumble" : "Ouch!"
        if hearts <= 0 {
            finish(success: false)
        }
    }

    public mutating func finish(success: Bool) {
        guard phase == .running else { return }
        phase = success ? .finished : .failed
        let stars = success ? starRating() : 0
        self.stars = stars
        let result = MeadowRunResult(
            levelIndex: level.index,
            score: score,
            apples: apples,
            stars: stars,
            distance: distance,
            elapsed: elapsed,
            hearts: hearts,
            maxHearts: maxHearts,
            goalApples: level.goalApples,
            maxCombo: maxCombo,
            powers: Array(Set(activePowers)).sorted(),
            success: success
        )
        self.result = result
        lastEvent = success ? "Meadow cleared!" : "The meadow wins this round."
    }

    private func starRating() -> Int {
        guard hearts > 0 else { return 1 }
        if apples >= level.goalApples, hearts >= 2 { return 3 }
        if apples >= level.goalApples || hearts >= 2 { return 2 }
        return 1
    }
}

// MARK: - Arcade scene helpers

public struct MeadowSceneryLayer: Sendable {
    public let parallax: Double
    public let hillHex: String
    public let treeHex: String
    public let cloudHex: String

    public init(parallax: Double, hillHex: String, treeHex: String, cloudHex: String) {
        self.parallax = parallax
        self.hillHex = hillHex
        self.treeHex = treeHex
        self.cloudHex = cloudHex
    }
}

public enum MeadowArtDirection {
    public static func layers(for biome: MeadowBiome) -> [MeadowSceneryLayer] {
        switch biome {
        case .meadow:
            return [
                MeadowSceneryLayer(parallax: 0.12, hillHex: "B9D6B0", treeHex: "5E9C68", cloudHex: "FFF9EC"),
                MeadowSceneryLayer(parallax: 0.26, hillHex: "8FBF8A", treeHex: "4F8A5A", cloudHex: "FFF9EC"),
                MeadowSceneryLayer(parallax: 0.48, hillHex: "6FA84F", treeHex: "3F7350", cloudHex: "F4E5C5")
            ]
        case .orchard:
            return [
                MeadowSceneryLayer(parallax: 0.12, hillHex: "E7C69A", treeHex: "8C6B4A", cloudHex: "FFF4DE"),
                MeadowSceneryLayer(parallax: 0.28, hillHex: "D8B477", treeHex: "C94F45", cloudHex: "FFF4DE"),
                MeadowSceneryLayer(parallax: 0.5, hillHex: "C89C5B", treeHex: "4F8A5A", cloudHex: "F7D9A2")
            ]
        case .creek:
            return [
                MeadowSceneryLayer(parallax: 0.1, hillHex: "C2DFD0", treeHex: "6B8F73", cloudHex: "F7FCFF"),
                MeadowSceneryLayer(parallax: 0.3, hillHex: "9CC8B0", treeHex: "4F8A5A", cloudHex: "E8F7F7"),
                MeadowSceneryLayer(parallax: 0.52, hillHex: "77AE91", treeHex: "3F7350", cloudHex: "D8EDF5")
            ]
        case .golden:
            return [
                MeadowSceneryLayer(parallax: 0.12, hillHex: "F3D08A", treeHex: "B8892E", cloudHex: "FFF0CB"),
                MeadowSceneryLayer(parallax: 0.28, hillHex: "E0B562", treeHex: "A46B49", cloudHex: "FFF0CB"),
                MeadowSceneryLayer(parallax: 0.5, hillHex: "C89643", treeHex: "8A5A3A", cloudHex: "F7E1B0")
            ]
        case .moonlit:
            return [
                MeadowSceneryLayer(parallax: 0.12, hillHex: "344C5C", treeHex: "24343C", cloudHex: "8FA6BF"),
                MeadowSceneryLayer(parallax: 0.28, hillHex: "405E5A", treeHex: "2F4A3C", cloudHex: "6C83A0"),
                MeadowSceneryLayer(parallax: 0.5, hillHex: "3E6652", treeHex: "2F503F", cloudHex: "4A5F7A")
            ]
        case .storm:
            return [
                MeadowSceneryLayer(parallax: 0.12, hillHex: "A6B3B0", treeHex: "5C6E64", cloudHex: "D8DEDD"),
                MeadowSceneryLayer(parallax: 0.28, hillHex: "879B8D", treeHex: "495B50", cloudHex: "AEB7B5"),
                MeadowSceneryLayer(parallax: 0.5, hillHex: "6E846F", treeHex: "3E5146", cloudHex: "8F9D9C")
            ]
        }
    }

    public static func accent(for biome: MeadowBiome) -> String {
        switch biome {
        case .meadow, .creek: return "4F8A5A"
        case .orchard: return "C94F45"
        case .golden: return "B8892E"
        case .moonlit: return "8E6BC4"
        case .storm: return "4F7FA8"
        }
    }
}
