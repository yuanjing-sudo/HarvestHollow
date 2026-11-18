#if canImport(SwiftUI)
import SwiftUI
import Combine
import HarvestHollowCore

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

// MARK: - Tabs

public enum AppTab: String, CaseIterable, Identifiable {
    case farm
    case barn
    case market
    case house
    case town
    case quests
    case arcade
    case economy
    // The voxel 3D diorama is archived at Archive/3D/World3DView.swift and is
    // deliberately out of the build; restore its tab here when it returns.

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .farm: return "Farm"
        case .barn: return "Barn"
        case .market: return "Market"
        case .house: return "House"
        case .town: return "Town"
        case .quests: return "Quests"
        case .arcade: return "Meadow Dash"
        case .economy: return "Valley Ledger"
        }
    }

    public var icon: String {
        switch self {
        case .farm: return "leaf.fill"
        case .barn: return "pawprint.fill"
        case .market: return "cart.fill"
        case .house: return "sofa.fill"
        case .town: return "building.columns.fill"
        case .quests: return "checklist"
        case .arcade: return "figure.run"
        case .economy: return "chart.line.uptrend.xyaxis"
        }
    }

    public var shortTitle: String {
        switch self {
        case .market: return "Shop"
        case .quests: return "Quests"
        case .town: return "Town"
        case .arcade: return "Play"
        case .economy: return "Valley"
        default: return title
        }
    }
}

// MARK: - Town routes

public enum TownRoute: String, Hashable, CaseIterable, Identifiable {
    case fishing
    case kitchen
    case achievements
    case almanac
    case collection
    case help

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fishing: return "Hollow Pond"
        case .kitchen: return "Cottage Kitchen"
        case .achievements: return "Achievement Journal"
        case .almanac: return "Valley Almanac"
        case .collection: return "Collection Book"
        case .help: return "How to Play"
        }
    }

    public var icon: String {
        switch self {
        case .fishing: return "fish.fill"
        case .kitchen: return "fork.knife"
        case .achievements: return "rosette"
        case .almanac: return "calendar"
        case .collection: return "books.vertical.fill"
        case .help: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Toast

public struct ToastMessage: Identifiable {
    public let id = UUID()
    public let title: String
    public let detail: String?
    public let icon: String
    public let tint: Color
}

public enum SaveStatus {
    case saved
    case failed

    public var icon: String {
        switch self {
        case .saved: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    public var text: String {
        switch self {
        case .saved: return "Saved"
        case .failed: return "Save failed"
        }
    }

    public var tint: Color {
        switch self {
        case .saved: return HHTheme.forest
        case .failed: return HHTheme.terracotta
        }
    }
}

// MARK: - Store

@MainActor
public final class GameStore: ObservableObject {
    @Published public private(set) var state: GameState
    @Published public var selectedTab: AppTab = .farm
    @Published public var selectedSeedCropID: String?
    @Published public var selectedPlotID: Int?
    @Published public var adoptPenID: Int?
    @Published public var toast: ToastMessage?
    @Published public var activeLevelUp: Int?
    @Published public var showWelcome: Bool = false
    @Published public var showInventory: Bool = false
    @Published public var showSettings: Bool = false
    @Published public var showWeatherSheet: Bool = false
    @Published public var townPath: [TownRoute] = []
    @Published public var offlineNotice: String?
    @Published public var saveStatus: SaveStatus = .saved

    public let engine: GameEngine
    public var catalog: GameCatalog { engine.catalog }

    private let saveStore: SaveStore
    private var timer: Timer?
    private var lastSavedAt = Date.distantPast
    private var toastQueue: [ToastMessage] = []
    private var toastTask: Task<Void, Never>?
    private var levelUpTask: Task<Void, Never>?

    // MARK: Bootstrap

    public init(saveStore: SaveStore? = nil) {
        let store = saveStore ?? Self.makeSaveStore()
        self.saveStore = store

        let loaded = (try? store.load()) ?? (try? store.loadBackup())
        let initialState = loaded ?? GameState.newGame()
        self.state = initialState
        self.engine = GameEngine(state: initialState)
        self.showWelcome = !initialState.settings.hasSeenWelcome
        #if DEBUG
        if ProcessInfo.processInfo.environment["HARVEST_HOLLOW_SKIP_WELCOME"] == "1" {
            self.showWelcome = false
        }
        if let rawTab = ProcessInfo.processInfo.environment["HARVEST_HOLLOW_START_TAB"],
           let tab = AppTab(rawValue: rawTab) {
            self.selectedTab = tab
        }
        if let rawRoute = ProcessInfo.processInfo.environment["HARVEST_HOLLOW_START_TOWN_ROUTE"],
           let route = TownRoute(rawValue: rawRoute) {
            self.selectedTab = .town
            self.townPath = [route]
        }
        #endif

        bootstrap()
        #if DEBUG
        if let rawTime = ProcessInfo.processInfo.environment["HARVEST_HOLLOW_START_TIME"],
           let fraction = Double(rawTime) {
            engine.setClock(GameConstants.dayLength * min(0.92, max(0.05, fraction)))
            state = engine.state
        }
        #endif
    }

    private static func makeSaveStore() -> SaveStore {
        if let url = try? SaveStore.defaultURL() {
            return SaveStore(url: url)
        }
        let fallback = FileManager.default.temporaryDirectory
            .appendingPathComponent("HarvestHollow-save.json")
        return SaveStore(url: fallback)
    }

    private func bootstrap() {
        engine.simulate()
        state = engine.state
        handle(engine.drainEvents())
        saveNow()
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        engine.simulate()
        state = engine.state
        handle(engine.drainEvents())
        if Date().timeIntervalSince(lastSavedAt) > 20 {
            saveNow()
        }
    }

    // MARK: Events

    private func handle(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .leveledUp(let level, let bonus):
                activeLevelUp = level
                enqueueToast(
                    title: "Level \(level)!",
                    detail: "+\(bonus) coins and fresh unlocks",
                    icon: "sparkles",
                    tint: HHTheme.goldDeep
                )
                scheduleLevelUpDismiss()
                playFeedback(strong: true)

            case .questCompleted(_, let title, let coins, let xp):
                enqueueToast(
                    title: "Quest complete · \(title)",
                    detail: "+\(coins) coins · +\(xp) XP",
                    icon: "checkmark.seal.fill",
                    tint: HHTheme.forest
                )
                playFeedback(strong: true)

            case .dailyOrderCompleted(_, let coins, let xp):
                enqueueToast(
                    title: "Daily order complete!",
                    detail: "+\(coins) coins · +\(xp) XP",
                    icon: "shippingbox.fill",
                    tint: HHTheme.terracotta
                )

            case .fishCaught(let fishID, let weight, let rarity):
                let name = catalog.fishDefinition(fishID)?.name ?? "fish"
                enqueueToast(
                    title: "\(rarity.stars) \(name)",
                    detail: String(format: "%.1f lb · +%d XP", weight, rarity.xp),
                    icon: "fish.fill",
                    tint: HHTheme.sky
                )
                playFeedback()

            case .rodUpgraded(let level):
                enqueueToast(
                    title: "Rod upgraded",
                    detail: "Level \(level) · \(engine.fishingRodName)",
                    icon: "wrench.and.screwdriver.fill",
                    tint: HHTheme.goldDeep
                )
                playFeedback(strong: true)

            case .achievementClaimed(_, let title, let coins, let xp):
                enqueueToast(
                    title: "Achievement · \(title)",
                    detail: "+\(coins) coins · +\(xp) XP",
                    icon: "rosette",
                    tint: HHTheme.lavender
                )
                playFeedback(strong: true)

            case .giftClaimed(let day, let streak, let coins, let xp):
                enqueueToast(
                    title: "Daily gift · Day \(day)",
                    detail: "+\(coins) coins · +\(xp) XP · \(streak)-day streak",
                    icon: "gift.fill",
                    tint: HHTheme.rose
                )
                playFeedback(strong: true)

            case .cooked(_, let dishName, let buffKind, let percent):
                enqueueToast(
                    title: "Cooked \(dishName)",
                    detail: "\(buffKind.title) +\(percent)% when eaten",
                    icon: "fork.knife",
                    tint: HHTheme.terracotta
                )
                playFeedback()

            case .mealEnjoyed(_, let dishName, let percent, let seconds):
                let minutes = max(1, seconds / 60)
                enqueueToast(
                    title: "Enjoyed \(dishName)"
                    , detail: "Buff +\(percent)% · \(minutes)m",
                    icon: "sparkles",
                    tint: HHTheme.goldDeep
                )
                playFeedback(strong: true)

            case .petAnimal(let name, let affection):
                enqueueToast(
                    title: "\(name) is delighted",
                    detail: "Affection \(Int(affection))%",
                    icon: "heart.fill",
                    tint: HHTheme.rose
                )
                playFeedback()

            case .masteryUp(let cropID, let level):
                let name = catalog.crop(cropID)?.name ?? "Crop"
                enqueueToast(
                    title: "\(name) mastery \(level)",
                    detail: "A little more value at market",
                    icon: "star.fill",
                    tint: HHTheme.goldDeep
                )

            case .meadowRunCompleted(let level, let score, let stars, let coins, let xp):
                enqueueToast(
                    title: "Meadow \(level) · \(stars)★",
                    detail: "\(score) pts · +\(coins) coins · +\(xp) XP",
                    icon: "figure.run",
                    tint: HHTheme.forest
                )
                playFeedback(strong: stars >= 2)

            case .economyEvent(_, let title, let detail, let positive):
                enqueueToast(
                    title: title,
                    detail: detail,
                    icon: positive ? "chart.line.uptrend.xyaxis" : "exclamationmark.triangle.fill",
                    tint: positive ? HHTheme.forest : HHTheme.terracotta
                )
                playFeedback(strong: !positive)

            case .dayAdvanced(let day, let weather):
                enqueueToast(
                    title: "Day \(day) · \(weather.title)",
                    detail: weather.blurb,
                    icon: weather == .rainy ? "cloud.rain.fill" : "sun.max.fill",
                    tint: HHTheme.terracotta
                )

            case .returnedAfterDays(let days, let day, let weather):
                offlineNotice = "\(days) days passed while the farm dozed. It is now day \(day) — \(weather.title.lowercased())."

            case .offlineProgress(let seconds, let days):
                let hours = Double(seconds) / 3_600
                if offlineNotice == nil, hours >= 0.1 {
                    let timeText = hours >= 1
                        ? String(format: "%.1f hours", hours)
                        : "\(max(1, seconds / 60)) minutes"
                    offlineNotice = "Your farm kept growing for \(timeText) while you were away."
                }
                if days > 1 {
                    offlineNotice = offlineNotice ?? "\(days) days passed while you were away."
                }

            case .message(let text):
                enqueueToast(
                    title: text,
                    detail: nil,
                    icon: "bell.fill",
                    tint: HHTheme.forest
                )
            }
        }
    }

    private func scheduleLevelUpDismiss() {
        levelUpTask?.cancel()
        levelUpTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 4_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self?.activeLevelUp = nil
            }
        }
    }

    // MARK: Toasts

    public func enqueueToast(
        title: String,
        detail: String?,
        icon: String = "leaf.fill",
        tint: Color = HHTheme.forest
    ) {
        let message = ToastMessage(title: title, detail: detail, icon: icon, tint: tint)
        if toast == nil {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                toast = message
            }
            scheduleToastAdvance()
        } else {
            if toastQueue.count >= 3 {
                toastQueue.removeFirst()
            }
            toastQueue.append(message)
        }
    }

    private func scheduleToastAdvance() {
        toastTask?.cancel()
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                self?.toast = nil
            }
            try? await Task.sleep(nanoseconds: 240_000_000)
            guard !Task.isCancelled else { return }
            self?.showNextToast()
        }
    }

    private func showNextToast() {
        guard toast == nil, !toastQueue.isEmpty else { return }
        let next = toastQueue.removeFirst()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            toast = next
        }
        scheduleToastAdvance()
    }

    public func dismissOfflineNotice() {
        withAnimation(.easeOut(duration: 0.2)) {
            offlineNotice = nil
        }
    }

    // MARK: Feedback

    private func playFeedback(strong: Bool = false) {
        #if canImport(UIKit)
        if state.settings.hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: strong ? .medium : .light)
            generator.impactOccurred()
        }
        #endif
        #if canImport(AudioToolbox)
        if state.settings.soundEnabled {
            AudioServicesPlaySystemSound(strong ? 1025 : 1104)
        }
        #endif
    }

    // MARK: Action plumbing

    private func perform(
        _ result: ActionResult,
        announceSuccess: Bool = false,
        feedback: Bool = true
    ) {
        state = engine.state
        handle(engine.drainEvents())

        if result.isSuccess {
            if announceSuccess {
                enqueueToast(
                    title: result.message,
                    detail: nil,
                    icon: "checkmark.circle.fill",
                    tint: HHTheme.forest
                )
            }
            if feedback { playFeedback() }
        } else {
            enqueueToast(
                title: result.message,
                detail: nil,
                icon: "exclamationmark.triangle.fill",
                tint: HHTheme.terracotta
            )
        }
        saveNow()
    }

    public func saveNow() {
        state = engine.state
        do {
            try saveStore.save(engine.state)
            lastSavedAt = Date()
            saveStatus = .saved
        } catch {
            saveStatus = .failed
            enqueueToast(
                title: "Could not save the farm",
                detail: error.localizedDescription,
                icon: "externaldrive.badge.exclamationmark",
                tint: HHTheme.terracotta
            )
        }
    }

    // MARK: Derived helpers

    public var ownedSeedCrops: [CropDefinition] {
        catalog.crops.filter {
            state.level >= $0.unlockLevel && state.inventory[$0.seedItemID, default: 0] > 0
        }
    }

    public var activeSeedCropID: String? {
        if let selectedSeedCropID,
           let crop = catalog.crop(selectedSeedCropID),
           state.level >= crop.unlockLevel,
           state.inventory[crop.seedItemID, default: 0] > 0 {
            return selectedSeedCropID
        }
        return ownedSeedCrops.first?.id
    }

    public func seedCount(_ cropID: String) -> Int {
        guard let crop = catalog.crop(cropID) else { return 0 }
        return state.inventory[crop.seedItemID, default: 0]
    }

    public func sellPrice(for itemID: String) -> Int {
        engine.sellPrice(for: itemID)
    }

    public func priceTrend(for itemID: String) -> Double {
        Market.multiplier(itemID: itemID, day: state.day) - 1
    }

    public var comfort: Int { engine.comfort }
    public var comfortBonusPercent: Int { Int(engine.comfortBonus * 100) }
    public var activeQuest: QuestDefinition? { engine.activeQuest }

    public func questProgress(_ objective: QuestObjective) -> Int {
        engine.progress(for: objective)
    }

    public var inventoryItems: [(item: ItemDefinition, count: Int)] {
        state.inventory.compactMap { key, count in
            guard count > 0, let item = catalog.item(key) else { return nil }
            return (item, count)
        }
        .sorted {
            if $0.item.kind == $1.item.kind {
                return $0.item.name < $1.item.name
            }
            return $0.item.kind.rawValue < $1.item.kind.rawValue
        }
    }

    public var furnitureInventory: [(item: ItemDefinition, count: Int)] {
        inventoryItems.filter { $0.item.kind == .furniture }
    }

    public var sellableInventory: [(item: ItemDefinition, count: Int)] {
        inventoryItems.filter {
            switch $0.item.kind {
            case .produce, .animalProduct, .fish, .dish, .supply:
                return true
            case .seed, .furniture:
                return false
            }
        }
    }

    public func itemCount(_ itemID: String) -> Int {
        state.inventory[itemID, default: 0]
    }

    public var placedFurniture: [PlacedFurniture] {
        state.house.placed
    }

    public func placedDefinition(_ placed: PlacedFurniture) -> FurnitureDefinition? {
        catalog.furniture(placed.itemID)
    }

    public var currentTheme: HouseTheme {
        engine.currentTheme
    }

    public func plotUnlockLevel(_ plotID: Int) -> Int {
        engine.plotUnlockLevel(plotID)
    }

    public func plotPrice() -> Int {
        engine.plotPrice()
    }

    public func penUnlockLevel(_ penID: Int) -> Int {
        engine.penUnlockLevel(penID)
    }

    public func penPrice() -> Int {
        engine.penPrice()
    }

    // MARK: Town helpers

    public var season: FarmSeason { state.season }
    public var seasonDay: Int { state.seasonDay }
    public var festival: FarmFestival? { state.festival }
    public var nextWeather: Weather { state.nextWeather }
    public var weatherHistory: [Weather] { engine.weatherHistory }
    public var fishingRodName: String { engine.fishingRodName }
    public var fishingRodLevel: Int { engine.fishingRodLevel }
    public var fishingUpgradeCost: Int { engine.fishingRodUpgradeCost }
    public var fishingUpgradeLevel: Int { engine.fishingRodUpgradeLevel }
    public var canUpgradeFishingRod: Bool { engine.canUpgradeFishingRod }
    public var baitCount: Int { engine.baitCount }
    public var fishCaughtCount: Int { engine.fishCaughtCount }
    public var uniqueFishCaught: Int { engine.uniqueFishCaught }
    public var currentFoodBuff: FoodBuff? { engine.currentFoodBuff }
    public var foodBuffSecondsRemaining: Int { engine.foodBuffSecondsRemaining }
    public var dishesCookedCount: Int { engine.dishesCookedCount }
    public var uniqueRecipesCooked: Int { engine.uniqueRecipesCooked }
    public var dailyGift: DailyGiftDefinition { engine.nextDailyGift }
    public var canClaimDailyGift: Bool { engine.canClaimDailyGift }
    public var dailyGiftStreak: Int { engine.dailyGiftStreak }
    public var dailyGiftCycleDay: Int { engine.dailyGiftCycleDay }
    public var achievementProgressList: [AchievementProgress] { engine.achievementProgressList }
    public var claimableAchievementCount: Int { engine.claimableAchievementCount }
    public var claimedAchievementCount: Int { engine.claimedAchievementCount }
    public var collectionProgress: Double { engine.collectionProgress }
    public var discoveredCropCount: Int { engine.discoveredCropCount }
    public var discoveredDishCount: Int { engine.discoveredDishCount }
    public var discoveredBarnGoodCount: Int { engine.discoveredBarnGoodCount }

    public func fishCatchCount(_ fishID: String) -> Int {
        engine.fishCatchCount(fishID)
    }

    public func bestWeight(forFish fishID: String) -> Double {
        engine.bestWeight(forFish: fishID)
    }

    public func isFishCaught(_ fishID: String) -> Bool {
        engine.isFishCaught(fishID)
    }

    public func cookedCount(recipeID: String) -> Int {
        engine.cookedCount(recipeID: recipeID)
    }

    public func hasCooked(recipeID: String) -> Bool {
        engine.hasCooked(recipeID: recipeID)
    }

    public func canCook(_ recipe: RecipeDefinition) -> Bool {
        engine.canCook(recipe)
    }

    public func missingIngredients(for recipe: RecipeDefinition) -> [(itemID: String, quantity: Int)] {
        engine.missingIngredients(for: recipe)
    }

    public func cropMasteryLevel(_ cropID: String) -> Int {
        engine.cropMasteryLevel(cropID)
    }

    public func cropMasteryTier(_ cropID: String) -> CropMasteryTier {
        engine.cropMasteryTier(cropID)
    }

    public func cropMasteryProgress(_ cropID: String) -> Double {
        engine.cropMasteryProgress(cropID)
    }

    public func cropHarvestCount(_ cropID: String) -> Int {
        engine.cropHarvestCount(cropID)
    }

    public func isCropDiscovered(_ cropID: String) -> Bool {
        engine.isCropDiscovered(cropID)
    }

    public func soldCount(itemID: String) -> Int {
        engine.soldCount(itemID: itemID)
    }

    public func isItemDiscovered(_ itemID: String) -> Bool {
        engine.isItemDiscovered(itemID)
    }

    public func achievementProgress(_ id: String) -> AchievementProgress? {
        guard let definition = catalog.achievement(id) else { return nil }
        return engine.progress(forAchievement: definition)
    }

    public func openTown(_ route: TownRoute? = nil) {
        if let route {
            townPath = [route]
        } else {
            townPath = []
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            selectedTab = .town
        }
    }

    public func closeTownToRoot() {
        townPath = []
    }

    // MARK: Farm actions

    public func plant(cropID: String, in plotID: Int) {
        perform(engine.plant(cropID: cropID, inPlot: plotID))
    }

    public func plantSelected(in plotID: Int) {
        guard let cropID = activeSeedCropID else {
            enqueueToast(
                title: "Pick a seed first",
                detail: "Buy seeds at the market, then tap a plot.",
                icon: "leaf",
                tint: HHTheme.terracotta
            )
            selectedTab = .market
            return
        }
        plant(cropID: cropID, in: plotID)
    }

    public func plantAll() {
        guard let cropID = activeSeedCropID else {
            enqueueToast(
                title: "Pick a seed first",
                detail: "There are no seeds in your satchel.",
                icon: "leaf",
                tint: HHTheme.terracotta
            )
            return
        }
        perform(engine.plantAll(cropID: cropID), announceSuccess: true)
    }

    public func water(plotID: Int) {
        perform(engine.water(plotID: plotID))
    }

    public func waterAll() {
        perform(engine.waterAll(), announceSuccess: true)
    }

    public func fertilize(plotID: Int) {
        perform(engine.fertilize(plotID: plotID), announceSuccess: true)
    }

    public func harvest(plotID: Int) {
        perform(engine.harvest(plotID: plotID), announceSuccess: true)
    }

    public func harvestAll() {
        perform(engine.harvestAll(), announceSuccess: true)
    }

    public func buyPlot(_ plotID: Int) {
        perform(engine.buyPlot(plotID), announceSuccess: true, feedback: true)
    }

    // MARK: Barn actions

    public func adoptAnimal(speciesID: String, penID: Int) {
        perform(engine.adoptAnimal(speciesID: speciesID, penID: penID), announceSuccess: true)
    }

    public func feed(penID: Int) {
        perform(engine.feed(penID: penID), announceSuccess: true)
    }

    public func feedAll() {
        perform(engine.feedAll(), announceSuccess: true)
    }

    public func collect(penID: Int) {
        perform(engine.collect(penID: penID), announceSuccess: true)
    }

    public func collectAll() {
        perform(engine.collectAll(), announceSuccess: true)
    }

    public func renameAnimal(penID: Int, to name: String) {
        perform(engine.renameAnimal(penID: penID, to: name), announceSuccess: true)
    }

    public func buyPen(_ penID: Int) {
        perform(engine.buyPen(penID), announceSuccess: true)
    }

    // MARK: Arcade

    @discardableResult
    public func recordMeadowRun(_ result: MeadowRunResult) -> (coins: Int, xp: Int) {
        let rewards = engine.recordMeadowRun(result)
        state = engine.state
        handle(engine.drainEvents())
        saveNow()
        return rewards
    }

    // MARK: Economy actions

    @discardableResult
    public func setEconomyTaxRate(_ value: Double) -> Bool {
        finishEconomyAction(engine.setEconomyTaxRate(value))
    }

    @discardableResult
    public func setEconomySubsidyRate(_ value: Double) -> Bool {
        finishEconomyAction(engine.setEconomySubsidyRate(value))
    }

    @discardableResult
    public func setEconomyPublicSpending(_ value: Double) -> Bool {
        finishEconomyAction(engine.setEconomyPublicSpending(value))
    }

    @discardableResult
    public func setEconomyTariffRate(_ value: Double) -> Bool {
        finishEconomyAction(engine.setEconomyTariffRate(value))
    }

    @discardableResult
    public func setEconomyInterestRate(_ value: Double) -> Bool {
        finishEconomyAction(engine.setEconomyInterestRate(value))
    }

    @discardableResult
    public func investInEconomy(_ investment: EconomyInvestment) -> Bool {
        finishEconomyAction(engine.investInEconomy(investment))
    }

    @discardableResult
    public func takeEconomyLoan(amount: Double) -> Bool {
        finishEconomyAction(engine.takeEconomyLoan(amount: amount))
    }

    @discardableResult
    public func repayEconomyLoan(id: UUID, amount: Double) -> Bool {
        finishEconomyAction(engine.repayEconomyLoan(id: id, amount: amount))
    }

    @discardableResult
    public func buyBusinessShares(
        businessID: UUID,
        shares: Double,
        leverage: Double
    ) -> InvestmentExecution {
        finishInvestmentAction(
            engine.buyBusinessShares(
                businessID: businessID,
                shares: shares,
                leverage: leverage
            )
        )
    }

    @discardableResult
    public func sellBusinessShares(
        businessID: UUID,
        shares: Double
    ) -> InvestmentExecution {
        finishInvestmentAction(
            engine.sellBusinessShares(businessID: businessID, shares: shares)
        )
    }

    @discardableResult
    public func shortBusinessShares(
        businessID: UUID,
        shares: Double,
        leverage: Double
    ) -> InvestmentExecution {
        finishInvestmentAction(
            engine.shortBusinessShares(
                businessID: businessID,
                shares: shares,
                leverage: leverage
            )
        )
    }

    @discardableResult
    public func coverBusinessShares(
        businessID: UUID,
        shares: Double
    ) -> InvestmentExecution {
        finishInvestmentAction(
            engine.coverBusinessShares(businessID: businessID, shares: shares)
        )
    }

    @discardableResult
    public func auditBusiness(id: UUID) -> BusinessAuditResult {
        finishAuditAction(engine.auditBusiness(id: id))
    }

    @discardableResult
    private func finishInvestmentAction(_ execution: InvestmentExecution) -> InvestmentExecution {
        state = engine.state
        handle(engine.drainEvents())
        if execution.success {
            saveNow()
            playFeedback()
        }
        return execution
    }

    @discardableResult
    private func finishAuditAction(_ result: BusinessAuditResult) -> BusinessAuditResult {
        state = engine.state
        handle(engine.drainEvents())
        if result.success {
            saveNow()
            playFeedback()
        }
        return result
    }

    @discardableResult
    private func finishEconomyAction(_ success: Bool) -> Bool {
        state = engine.state
        handle(engine.drainEvents())
        if success {
            saveNow()
            playFeedback()
        } else {
            enqueueToast(
                title: "The ledger resists",
                detail: "Raise your level, repay debt, or check your coin balance.",
                icon: "lock.fill",
                tint: HHTheme.muted
            )
        }
        return success
    }

    public func pet(penID: Int) {
        perform(engine.pet(penID: penID), announceSuccess: true)
    }

    public func petAll() {
        perform(engine.petAll(), announceSuccess: true)
    }

    // MARK: Town actions

    public func castLine() {
        perform(engine.castLine(), announceSuccess: true)
    }

    public func upgradeFishingRod() {
        perform(engine.upgradeFishingRod(), announceSuccess: true)
    }

    public func cook(recipeID: String) {
        perform(engine.cook(recipeID: recipeID), announceSuccess: true)
    }

    public func cookAllPossible() {
        perform(engine.cookAllPossible(), announceSuccess: true)
    }

    public func eatDish(itemID: String) {
        perform(engine.eatDish(itemID: itemID), announceSuccess: true)
    }

    public func claimDailyGift() {
        perform(engine.claimDailyGift(), announceSuccess: true)
    }

    public func claimAchievement(id: String) {
        perform(engine.claimAchievement(id: id), announceSuccess: true)
    }

    public func claimAllAchievements() {
        perform(engine.claimAllAchievements(), announceSuccess: true)
    }

    // MARK: Market actions

    public func buySeed(cropID: String, quantity: Int = 1) {
        perform(engine.buySeed(cropID: cropID, quantity: quantity), announceSuccess: true)
    }

    public func buySupply(_ itemID: String, quantity: Int = 1) {
        perform(engine.buySupply(itemID, quantity: quantity), announceSuccess: true)
    }

    public func buyFurniture(_ itemID: String) {
        perform(engine.buyFurniture(itemID), announceSuccess: true)
    }

    public func buyTheme(_ themeID: String) {
        perform(engine.buyTheme(themeID), announceSuccess: true)
    }

    public func applyTheme(_ themeID: String) {
        perform(engine.applyTheme(themeID), announceSuccess: true)
    }

    public func sell(itemID: String, quantity: Int = 1) {
        perform(engine.sell(itemID: itemID, quantity: quantity), announceSuccess: true)
    }

    public func sellAll(itemID: String) {
        perform(engine.sellAll(itemID: itemID), announceSuccess: true)
    }

    // MARK: House actions

    public func selectSeed(_ cropID: String) {
        selectedSeedCropID = cropID
        selectedTab = .farm
    }

    public func placeFurniture(itemID: String, x: Int, y: Int) {
        perform(engine.placeFurniture(itemID: itemID, x: x, y: y), announceSuccess: true)
    }

    public func removeFurniture(_ placed: PlacedFurniture) {
        perform(engine.removeFurniture(id: placed.id), announceSuccess: true)
    }

    public func nudgeFurniture(_ placed: PlacedFurniture, dx: Int, dy: Int) {
        perform(engine.nudgeFurniture(id: placed.id, dx: dx, dy: dy))
    }

    // MARK: Import / export

    /// Loads a save state decoded from an export code, replacing the current farm.
    public func importSave(_ imported: GameState) {
        engine.replaceState(imported)
        engine.simulate()
        state = engine.state
        selectedSeedCropID = nil
        selectedPlotID = nil
        adoptPenID = nil
        townPath = []
        offlineNotice = nil
        showWelcome = false
        activeLevelUp = nil
        handle(engine.drainEvents())
        saveNow()
        withAnimation {
            selectedTab = .farm
        }
    }

    // MARK: Settings

    public func dismissWelcome() {
        engine.markWelcomeSeen()
        state = engine.state
        withAnimation(.easeOut(duration: 0.25)) {
            showWelcome = false
        }
        saveNow()
    }

    public func toggleSound() {
        engine.setSoundEnabled(!state.settings.soundEnabled)
        state = engine.state
        saveNow()
        if state.settings.soundEnabled { playFeedback() }
    }

    public func toggleHaptics() {
        engine.setHapticsEnabled(!state.settings.hapticsEnabled)
        state = engine.state
        saveNow()
        if state.settings.hapticsEnabled { playFeedback() }
    }

    public func resetGame() {
        let fresh = engine.resetProgress()
        state = fresh
        selectedSeedCropID = nil
        selectedPlotID = nil
        adoptPenID = nil
        townPath = []
        offlineNotice = nil
        showWelcome = true
        withAnimation {
            selectedTab = .farm
        }
        saveNow()
    }
}
#endif
