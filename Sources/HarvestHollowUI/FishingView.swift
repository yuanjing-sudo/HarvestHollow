#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Pond

public struct FishingView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selectedFish: FishDefinition?
    @State private var lastCatchID: String?
    @State private var lastCatchWeight: Double = 0
    @State private var catchPulse = false
    @State private var catchTask: Task<Void, Never>?
    @State private var showRarityGuide = false

    private var state: GameState { store.state }
    private var recentCatch: FishingCatchRecord? {
        state.activities.fishing.recentCatches.first
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TownScreenHeader(
                    title: "Hollow Pond",
                    subtitle: "A quiet bend in the river, a battered jetty, and fish with opinions.",
                    icon: "fish.fill",
                    accent: Color(hex: "4F6D8A")
                )

                pondCard
                rodCard
                forecastCard
                journalSection
                recentCatchesSection
                pondTips
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(HHTheme.cream)
        .navigationTitle("Hollow Pond")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $selectedFish) { fish in
            FishDetailSheet(fish: fish)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRarityGuide) {
            RarityGuideSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onDisappear {
            catchTask?.cancel()
        }
    }

    // MARK: Pond card

    private var pondCard: some View {
        CozyCard {
            VStack(spacing: 12) {
                ZStack(alignment: .bottom) {
                    AnimatedPondScene(
                        fishID: lastCatchID ?? recentCatch?.fishID,
                        tint: Color(hex: "4F8AAE"),
                        height: 194
                    )

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.fishingRodName)
                                .font(.hhHeadline(13))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.18), radius: 2)
                            Text("Rod level \(store.fishingRodLevel) · \(store.baitCount) bait left")
                                .font(.hhCaption(10.5))
                                .foregroundStyle(.white.opacity(0.88))
                        }
                        Spacer(minLength: 4)
                        Button {
                            showRarityGuide = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Rarity guide")
                            }
                            .font(.hhCaption(10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.24), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                }

                if let record = recentCatch, catchPulse {
                    catchBanner(record)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                HStack(spacing: 9) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("The water is \(state.weather.title.lowercased())")
                            .font(.hhHeadline(13))
                            .foregroundStyle(HHTheme.ink)
                        Text(pondHint)
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if let buff = store.currentFoodBuff, buff.kind == .fishing || buff.kind == .feast {
                        TagChip("+\(buff.percent)% luck", icon: "fish.fill", tint: Color(hex: "4F6D8A"))
                    }
                }

                Button {
                    cast()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: store.baitCount > 0 ? "figure.fishing" : "tray")
                        VStack(alignment: .leading, spacing: 0) {
                            Text(store.baitCount > 0 ? "Cast the line" : "Out of bait")
                                .font(.hhHeadline(15))
                            Text(store.baitCount > 0
                                ? "Uses 1 pond bait · \(store.baitCount) left"
                                : "Buy pond bait from the market")
                                .font(.hhCaption(10))
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "water.waves")
                            .font(.system(size: 18, weight: .bold))
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .disabled(store.baitCount == 0)
                .opacity(store.baitCount == 0 ? 0.5 : 1)

                HStack(spacing: 6) {
                    TagChip("\(store.fishCaughtCount) caught", icon: "fish.fill", tint: Color(hex: "4F6D8A"))
                    TagChip("\(store.uniqueFishCaught)/\(store.catalog.fish.count) species", icon: "books.vertical.fill", tint: HHTheme.lavender)
                    if state.activities.fishing.perfectCasts > 0 {
                        TagChip("\(state.activities.fishing.perfectCasts) perfect", icon: "sparkles", tint: HHTheme.goldDeep)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var pondHint: String {
        let time = state.timeOfDay
        switch state.weather {
        case .rainy, .storm:
            return "Rain rings the surface. Rare fish are more willing to bite."
        case .sunny:
            if time > 0.84 || time < 0.18 {
                return "The moon is out. Night fish are stirring under the jetty."
            }
            return "Clear water and a bright sky. A good day for a lazy cast."
        case .breezy:
            return "The breeze hides your footsteps. Keep an eye on the shallows."
        case .heatwave:
            return "The fish are deep and sleepy. Try again when it cools."
        }
    }

    private func cast() {
        let previousID = store.state.activities.fishing.recentCatches.first?.id
        store.castLine()
        guard let record = store.state.activities.fishing.recentCatches.first,
              record.id != previousID else { return }
        lastCatchID = record.fishID
        lastCatchWeight = record.weight
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            catchPulse = true
        }
        catchTask?.cancel()
        catchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                catchPulse = false
            }
        }
    }

    private func catchBanner(_ record: FishingCatchRecord) -> some View {
        let fish = store.catalog.fishDefinition(record.fishID)
        let tint = Color(hex: fish?.rarity.tintHex ?? "4F6D8A")
        return HStack(spacing: 9) {
            if let fish {
                PixelSpriteView(SpriteLibrary.fish(fish.id) ?? SpriteLibrary.sprite(named: "fish.minnow")!)
                    .frame(width: 48, height: 38)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(fish?.name ?? "A mystery catch")
                    .font(.hhHeadline(13))
                    .foregroundStyle(HHTheme.ink)
                Text(String(format: "%.1f lb · %.0f coins at market", record.weight, Double(store.sellPrice(for: fish?.itemID ?? ""))))
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
            if let fish {
                RarityBadge(fish.rarity, compact: true)
            }
        }
        .padding(9)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    // MARK: Rod

    private var rodCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(HHTheme.goldDeep)
                        .frame(width: 38, height: 38)
                        .background(HHTheme.gold.opacity(0.16), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.fishingRodName)
                            .font(.hhHeadline(15))
                            .foregroundStyle(HHTheme.ink)
                        Text(rodBlurb)
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Text("LV \(store.fishingRodLevel)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.goldDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HHTheme.gold.opacity(0.14), in: Capsule())
                }

                HStack(spacing: 5) {
                    ForEach(1...FishingBalance.maxRodLevel, id: \.self) { level in
                        Capsule()
                            .fill(level <= store.fishingRodLevel ? HHTheme.goldDeep : HHTheme.ink.opacity(0.08))
                            .frame(height: 5)
                    }
                }

                if store.fishingRodLevel >= FishingBalance.maxRodLevel {
                    NoticeBanner(
                        icon: "sparkles",
                        title: "The Hollowmaster Rod",
                        message: "There is nothing left to upgrade. Every fish in the pond is within reach.",
                        tint: HHTheme.goldDeep
                    )
                } else {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next: \(FishingBalance.rodName(level: store.fishingRodLevel + 1))")
                                .font(.hhHeadline(12))
                                .foregroundStyle(HHTheme.ink)
                            Text("Level \(store.fishingUpgradeLevel) · \(store.fishingUpgradeCost) coins")
                                .font(.hhCaption(10))
                                .foregroundStyle(HHTheme.muted)
                        }
                        Spacer(minLength: 0)
                        Button {
                            store.upgradeFishingRod()
                        } label: {
                            Text("Upgrade")
                        }
                        .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
                        .disabled(!store.canUpgradeFishingRod)
                        .opacity(store.canUpgradeFishingRod ? 1 : 0.45)
                    }
                }

                HStack(spacing: 6) {
                    TagChip("\(store.baitCount) bait", icon: "tray.fill", tint: HHTheme.terracotta)
                    TagChip("Better rare odds", icon: "arrow.up.right", tint: HHTheme.forest)
                    Spacer(minLength: 0)
                    Button {
                        store.selectedTab = .market
                    } label: {
                        Text("Buy bait")
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
                }
            }
        }
    }

    private var rodBlurb: String {
        switch store.fishingRodLevel {
        case 1: return "A bent willow rod with a lot of heart and not much reach."
        case 2: return "Sturdy bamboo and a smoother reel. Uncommon fish are easier to find."
        case 3: return "A copper reel that sings on the cast. Rare fish start paying attention."
        case 4: return "A moonlit carbon rod for patient anglers and deep water."
        default: return "The pond-keeper's own rod. Legends have been landed on less."
        }
    }

    // MARK: Forecast

    private var forecastCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    "Pond conditions",
                    subtitle: "Weather and time of day both change who is biting.",
                    icon: "cloud.sun.fill"
                )

                HStack(spacing: 9) {
                    conditionTile(
                        title: "Today",
                        weather: state.weather,
                        detail: state.weather.fishingBonus >= 0
                            ? "+\(Int(state.weather.fishingBonus * 100))% rare odds"
                            : "\(Int(state.weather.fishingBonus * 100))% rare odds",
                        tint: Color(hex: "4F6D8A")
                    )
                    conditionTile(
                        title: "Tomorrow",
                        weather: state.nextWeather,
                        detail: state.nextWeather.blurb,
                        tint: HHTheme.goldDeep
                    )
                }

                HStack(spacing: 6) {
                    TagChip(state.timeOfDay < 0.32 ? "Dawn" : state.timeOfDay < 0.66 ? "Day" : state.timeOfDay < 0.84 ? "Dusk" : "Night", icon: "clock.fill", tint: HHTheme.terracotta)
                    TagChip("\(state.activities.fishing.totalCasts) casts", icon: "figure.fishing", tint: HHTheme.muted)
                    TagChip("\(state.activities.fishing.totalCatches) fish", icon: "fish.fill", tint: Color(hex: "4F6D8A"))
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func conditionTile(title: String, weather: Weather, detail: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Text(weather.emoji)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
                Text(weather.title)
                    .font(.hhHeadline(12))
                    .foregroundStyle(HHTheme.ink)
                Text(detail)
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    // MARK: Journal

    private var journalSection: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    SectionHeader(
                        "Fish journal",
                        subtitle: "Tap a fish to read its habits and best catch.",
                        icon: "books.vertical.fill"
                    )
                    Spacer(minLength: 4)
                    Text("\(store.uniqueFishCaught)/\(store.catalog.fish.count)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.lavender)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HHTheme.lavender.opacity(0.1), in: Capsule())
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 98, maximum: 150), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(store.catalog.fish) { fish in
                        fishTile(fish)
                            .onTapGesture {
                                selectedFish = fish
                            }
                    }
                }
            }
        }
    }

    private func fishTile(_ fish: FishDefinition) -> some View {
        let caught = store.isFishCaught(fish.id)
        let count = store.fishCatchCount(fish.id)
        let rarityTint = Color(hex: fish.rarity.tintHex)
        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(rarityTint.opacity(caught ? 0.09 : 0.04))
                if let sprite = SpriteLibrary.fish(fish.id) {
                    PixelSpriteView(sprite)
                        .frame(width: 62, height: 46)
                        .opacity(caught ? 1 : 0.22)
                        .saturation(caught ? 1 : 0)
                }
                if !caught {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted.opacity(0.65))
                }
            }
            .frame(height: 52)

            Text(caught ? fish.name : "???")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(caught ? HHTheme.ink : HHTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 3) {
                Text(fish.rarity.stars)
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(rarityTint)
                Spacer(minLength: 0)
                Text(caught ? "×\(count)" : "—")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
            }
        }
        .padding(6)
        .background(HHTheme.cream.opacity(0.45), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(rarityTint.opacity(caught ? 0.18 : 0.06), lineWidth: 1)
        )
    }

    // MARK: Recent catches

    @ViewBuilder
    private var recentCatchesSection: some View {
        let catches = state.activities.fishing.recentCatches
        if !catches.isEmpty {
            CozyCard {
                VStack(alignment: .leading, spacing: 9) {
                    SectionHeader(
                        "From the jetty",
                        subtitle: "The last few things that came out of the water.",
                        icon: "tray.full.fill"
                    )
                    ForEach(catches.prefix(6)) { record in
                        recentRow(record)
                        if record.id != catches.prefix(6).last?.id {
                            CozyDivider()
                        }
                    }
                }
            }
        }
    }

    private func recentRow(_ record: FishingCatchRecord) -> some View {
        let fish = store.catalog.fishDefinition(record.fishID)
        return HStack(spacing: 8) {
            if let fish, let sprite = SpriteLibrary.fish(fish.id) {
                PixelSpriteView(sprite)
                    .frame(width: 38, height: 30)
            } else {
                Text(fish?.emoji ?? "🐟")
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(fish?.name ?? "Unknown fish")
                    .font(.hhHeadline(11.5))
                    .foregroundStyle(HHTheme.ink)
                Text(record.caughtAt.formatted(date: .omitted, time: .shortened))
                    .font(.hhCaption(9))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
            Text(String(format: "%.1f lb", record.weight))
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.muted)
        }
        .padding(.vertical, 2)
    }

    // MARK: Tips

    private var pondTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Pond wisdom", subtitle: "Small details that make a difference.", icon: "lightbulb.fill")
            tipRow("🌧️", "Rain and storms coax out the rare fish. Bring bait and patience.")
            tipRow("🌙", "Some fish only rise at dawn, dusk, or deep night. Check the journal.")
            tipRow("⭐", "A perfect cast happens by chance and lands a heavier fish.")
            tipRow("🍲", "A fishing meal adds luck for several in-game hours.")
        }
    }

    private func tipRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji).font(.system(size: 15))
            Text(text)
                .font(.hhBody(11.5))
                .foregroundStyle(HHTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Fish detail

public struct FishDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    public let fish: FishDefinition

    public init(fish: FishDefinition) {
        self.fish = fish
    }

    private var caught: Bool { store.isFishCaught(fish.id) }
    private var count: Int { store.fishCatchCount(fish.id) }
    private var best: Double { store.bestWeight(forFish: fish.id) }

    public var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                HStack {
                    RarityBadge(fish.rarity)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }

                if caught {
                    if let sprite = SpriteLibrary.fish(fish.id) {
                        PixelSpriteView(sprite)
                            .frame(width: 170, height: 120)
                    }
                } else {
                    Text("❔")
                        .font(.system(size: 68))
                        .frame(width: 150, height: 110)
                }

                VStack(spacing: 3) {
                    Text(caught ? fish.name : "Undiscovered")
                        .font(.hhTitle(25))
                        .foregroundStyle(HHTheme.ink)
                    Text(caught ? fish.blurb : "Cast a line in the Hollow pond to learn more about this fish.")
                        .font(.hhBody(12.5))
                        .foregroundStyle(HHTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 7) {
                    statPill("Rod", "Lv \(fish.unlockRodLevel)", "wrench.and.screwdriver.fill", HHTheme.goldDeep)
                    statPill("Weight", fish.weightRangeText(), "scalemass.fill", Color(hex: "4F6D8A"))
                    statPill("Value", "\(fish.sellPrice)c", "circle.fill", HHTheme.terracotta)
                }

                VStack(spacing: 8) {
                    TownInfoRow(icon: "clock.fill", title: "Best time", value: fish.timeWindow.title, tint: HHTheme.terracotta)
                    if !fish.preferredWeather.isEmpty {
                        TownInfoRow(
                            icon: "cloud.rain.fill",
                            title: "Likes",
                            value: fish.preferredWeather.map(\.title).joined(separator: ", "),
                            tint: Color(hex: "4F6D8A")
                        )
                    }
                    TownInfoRow(icon: "chart.bar.fill", title: "Difficulty", value: String(repeating: "●", count: max(1, min(5, fish.difficulty))) + String(repeating: "○", count: max(0, 5 - fish.difficulty)), tint: HHTheme.forest)
                    TownInfoRow(icon: "tray.full.fill", title: "Caught", value: "\(count) times", tint: HHTheme.muted)
                    if caught {
                        TownInfoRow(icon: "scalemass.fill", title: "Best catch", value: String(format: "%.1f lb", best), tint: HHTheme.goldDeep)
                    }
                }
                .padding(12)
                .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HHTheme.ink.opacity(0.07), lineWidth: 1)
                )

                if caught {
                    Button {
                        store.selectedTab = .market
                    } label: {
                        Label("Sell at market for \(store.sellPrice(for: fish.itemID)) coins", systemImage: "cart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPrimaryButtonStyle())
                }
            }
            .padding(17)
        }
        .background(HHTheme.cream)
    }

    private func statPill(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.hhCaption(8.5))
                .foregroundStyle(HHTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Rarity guide

public struct RarityGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Pond rarity guide")
                        .font(.hhTitle(22))
                        .foregroundStyle(HHTheme.ink)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }

                Text("A better rod, the right weather, and a lucky meal all tip the odds toward the rarer fish.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)

                ForEach(FishRarity.allCases, id: \.self) { rarity in
                    HStack(spacing: 10) {
                        RarityBadge(rarity)
                        Spacer()
                        Text("Base chance \(Int(rarity.baseWeight))%")
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                        Text(rarity.stars)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: rarity.tintHex))
                    }
                    .padding(10)
                    .background(Color(hex: rarity.tintHex).opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }

                NoticeBanner(
                    icon: "sparkles",
                    title: "A little luck goes a long way",
                    message: "Legendary fish only appear with the Hollowmaster Rod or a strong fishing meal. Storms are said to help.",
                    tint: HHTheme.goldDeep
                )
            }
            .padding(18)
        }
        .background(HHTheme.cream)
    }
}
#endif
