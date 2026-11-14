import Foundation
import HarvestHollowCore

// MARK: - Terminal helpers

func paint(_ hex: String, text: String = "  ") -> String {
    let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard cleaned.count == 6,
          let value = Int(cleaned, radix: 16) else { return text }
    let r = (value >> 16) & 0xFF
    let g = (value >> 8) & 0xFF
    let b = value & 0xFF
    return "\u{001B}[48;2;\(r);\(g);\(b)m\(text)\u{001B}[0m"
}

func printSprite(_ sprite: PixelSprite) {
    print("")
    print("\(sprite.key)  \(sprite.width)×\(sprite.height)  \(sprite.coloredCellCount) squares  \(sprite.uniqueColorCount) colours")
    for row in sprite.rows {
        var line = ""
        for character in row {
            if character == "." {
                line += "  "
            } else if let hex = sprite.palette[character] {
                line += paint(hex)
            } else {
                line += "??"
            }
        }
        print(line)
    }
}

func printSprites(filter: String?) {
    let sprites: [PixelSprite]
    if let filter, !filter.isEmpty {
        sprites = SpriteLibrary.allSprites.filter { $0.key.contains(filter) }
    } else {
        sprites = SpriteLibrary.allSprites
    }
    guard !sprites.isEmpty else {
        print("No sprites matched “\(filter ?? "")”.")
        return
    }
    for sprite in sprites {
        printSprite(sprite)
    }
}

// MARK: - Demo

final class DemoClock {
    var now: Date

    init() {
        // A fixed date keeps the demo deterministic.
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 14
        components.hour = 9
        now = Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 1_779_000_000)
    }

    func advance(_ seconds: Double) {
        now = now.addingTimeInterval(seconds)
    }
}

func report(_ title: String) {
    print("\n\u{001B}[1m\(title)\u{001B}[0m")
    print(String(repeating: "─", count: max(12, title.count + 4)))
}

func describe(_ engine: GameEngine) {
    let state = engine.state
    print("  Day \(state.day) · \(state.weather.emoji) \(state.weather.title) · \(state.coins) coins · Lv \(state.level) (\(state.xp)/\(state.xpForNextLevel) xp)")
    let planted = state.plots.compactMap(\.crop)
    let ready = planted.filter(\.isReady).count
    let thirsty = planted.filter { !$0.watered && !$0.isReady }.count
    print("  Crops: \(planted.count) planted · \(ready) ready · \(thirsty) thirsty")
    let residents = state.pens.compactMap(\.animal)
    let goods = residents.reduce(0) { $0 + $1.stored }
    print("  Barn: \(residents.count) animals · \(goods) goods waiting")
    print("  Home comfort: \(engine.comfort) (+\(Int(engine.comfortBonus * 100))% sale bonus)")
    if let quest = engine.activeQuest {
        let progress = quest.objectives.map { "\($0.metric.title): \(engine.progress(for: $0))/\($0.target)" }
        print("  Quest “\(quest.title)”: " + progress.joined(separator: " · "))
    } else {
        print("  Quest: all story quests complete ✨")
    }
}

func runDemo() {
    let clock = DemoClock()
    var state = GameState.newGame(now: clock.now, seed: 7)
    state.coins = 4_000
    state.level = 4
    state.pens[2].unlocked = true
    state.inventory["seed.wheat", default: 0] += 6
    let engine = GameEngine(state: state, clock: { clock.now })

    report("Welcome to Harvest Hollow")
    describe(engine)

    report("1 · Plant and water")
    for plot in 0..<4 {
        _ = engine.plant(cropID: "wheat", inPlot: plot)
    }
    _ = engine.waterAll()
    describe(engine)

    report("2 · Fast-forward 35 seconds")
    clock.advance(35)
    engine.simulate()
    print("  " + engine.simulateDescriptionForDemo())
    describe(engine)

    report("3 · Harvest everything")
    print("  " + engine.harvestAll().message)
    print("  " + engine.sellAll(itemID: "crop.wheat").message)
    describe(engine)

    report("4 · Adopt and feed a chicken, then a pig")
    print("  " + engine.adoptAnimal(speciesID: "chicken", penID: 0).message)
    print("  " + engine.adoptAnimal(speciesID: "pig", penID: 2).message)
    print("  " + engine.feed(penID: 0).message)
    print("  " + engine.feed(penID: 2).message)
    clock.advance(110)
    engine.simulate()
    print("  " + engine.collectAll().message)
    print("  " + engine.sellAll(itemID: "product.egg").message)
    describe(engine)

    report("5 · Decorate the cottage")
    let chair = engine.placeFurniture(itemID: "furniture.chair", x: 1, y: 1)
    print("  " + chair.message)
    let plant = engine.placeFurniture(itemID: "furniture.plant", x: 4, y: 1)
    print("  " + plant.message)
    print("  " + engine.buyFurniture("furniture.rug").message)
    print("  " + engine.placeFurniture(itemID: "furniture.rug", x: 5, y: 4).message)
    describe(engine)

    report("6 · Save, reload, and catch up offline")
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("harvest-hollow-demo-\(UUID().uuidString).json")
    let store = SaveStore(url: url)
    do {
        try store.save(engine.state, at: clock.now)
        print("  Saved \(store.url.lastPathComponent) (\((try Data(contentsOf: url)).count) bytes)")
        guard let loaded = try store.load() else { throw SaveError.invalidData }
        let reloaded = GameEngine(state: loaded, clock: { clock.now })
        print("  Reloaded day \(reloaded.state.day), \(reloaded.state.coins) coins")

        clock.advance(3_600)
        reloaded.simulate()
        print("  After one offline hour: day \(reloaded.state.day), \(reloaded.state.weather.title)")
        let ready = reloaded.state.plots.compactMap(\.crop).filter(\.isReady).count
        print("  Offline crops ready: \(ready)")
        let products = reloaded.state.pens.compactMap(\.animal).reduce(0) { $0 + $1.stored }
        print("  Offline barn goods: \(products)")
    } catch {
        print("  Save error: \(error.localizedDescription)")
    }
    try? store.delete()

    report("Loop complete")
    print("  Coins: \(engine.state.coins) · Level: \(engine.state.level) · Comfort: \(engine.comfort)")
    print("  Quests completed: \(engine.state.stats.questsCompleted)")
    print("  Inventory: " + engine.state.inventory
        .sorted { $0.key < $1.key }
        .map { "\($0.key)×\($0.value)" }
        .joined(separator: ", "))
    print("\nOpen the SwiftUI app for the full clickable farm.")
}

extension GameEngine {
    func simulateDescriptionForDemo() -> String {
        let ready = state.plots.compactMap(\.crop).filter(\.isReady).count
        let growing = state.plots.compactMap(\.crop).filter { !$0.isReady }.count
        return "\(growing) growing, \(ready) ready to harvest."
    }
}

// MARK: - Entry point

let arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first {
case "sprites":
    printSprites(filter: arguments.dropFirst().first)
case "demo":
    runDemo()
case "validate":
    var failed = false
    for sprite in SpriteLibrary.allSprites {
        for (y, row) in sprite.rows.enumerated() where row.count != sprite.width {
            print("✗ \(sprite.key) row \(y) has width \(row.count), expected \(sprite.width)")
            failed = true
        }
        for (y, row) in sprite.rows.enumerated() {
            for character in row where character != "." && sprite.palette[character] == nil {
                print("✗ \(sprite.key) row \(y) uses undefined colour “\(character)”")
                failed = true
            }
        }
    }
    if failed {
        exit(1)
    }
    print("✓ \(SpriteLibrary.all.count) sprites are valid.")
case "help", "--help", "-h", nil:
    print("""
    Harvest Hollow — a cozy farm game written in Swift

    USAGE
      harvesthollow sprites [filter]   Browse the pixel-art sprites in ANSI colour
      harvesthollow demo               Run the whole gameplay loop headlessly
      harvesthollow validate           Validate every sprite grid
    """)
default:
    print("Unknown command “\(arguments[0])”. Try “harvesthollow help”.")
    exit(2)
}
